#!/usr/bin/env python3
"""
Официальный нативный генератор сертификатов и профилей для Apple App Store Connect API (RFC 7515 ES256 / IEEE P1363).
Автоматически регистрирует Bundle ID, генерирует iOS Distribution сертификат и App Store Provisioning Profile.
"""
import os, sys, base64, json, urllib.request, urllib.error, subprocess, time
from pathlib import Path

key_id     = os.environ.get("APPSTORE_KEY_ID", "").strip()
issuer_id  = os.environ.get("APPSTORE_ISSUER_ID", "").strip()
key_path   = os.environ.get("AUTH_KEY_PATH", "").strip()
runner_tmp = Path(os.environ.get("RUNNER_TEMP", "/tmp"))
github_env = os.environ.get("GITHUB_ENV", "/tmp/env")
bundle_id  = "com.samvel.speakercleaner"

if not key_id or not issuer_id or not key_path:
    print("❌ Ошибка: не заданы переменные API ключа App Store Connect!")
    sys.exit(1)

try:
    from cryptography.hazmat.primitives import serialization, hashes
    from cryptography.hazmat.primitives.asymmetric import ec, utils
except ImportError:
    subprocess.run([sys.executable, "-m", "pip", "install", "--break-system-packages", "cryptography"], check=True)
    from cryptography.hazmat.primitives import serialization, hashes
    from cryptography.hazmat.primitives.asymmetric import ec, utils

# Читаем .p8 ключ
with open(key_path, "rb") as f:
    key_bytes = f.read().replace(b"\r\n", b"\n").replace(b"\r", b"\n").strip()
    pk = serialization.load_pem_private_key(key_bytes, password=None)

def base64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode('utf-8')

# Генерируем токен RFC 7515 JWS ES256 с iat - 10 с учетом сдвига времени серверов
now = int(time.time())
header = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
payload = {
    "iss": issuer_id,
    "iat": now - 10,
    "exp": now + 1100,
    "aud": "appstoreconnect-v1"
}

header_b64 = base64url_encode(json.dumps(header, separators=(',', ':')).encode('utf-8'))
payload_b64 = base64url_encode(json.dumps(payload, separators=(',', ':')).encode('utf-8'))
signing_input = f"{header_b64}.{payload_b64}".encode('utf-8')

der_signature = pk.sign(signing_input, ec.ECDSA(hashes.SHA256()))
r, s = utils.decode_dss_signature(der_signature)
raw_signature = r.to_bytes(32, byteorder='big') + s.to_bytes(32, byteorder='big')
sig_b64 = base64url_encode(raw_signature)

token = f"{header_b64}.{payload_b64}.{sig_b64}"

def api_request(method, path, body=None):
    url = f"https://api.appstoreconnect.apple.com/v1{path}"
    data = json.dumps(body).encode("utf-8") if body else None
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        },
        method=method
    )
    try:
        with urllib.request.urlopen(req) as r:
            if r.status == 204:
                return {"status": "success"}
            res_content = r.read()
            if not res_content or not res_content.strip():
                return {"status": "success"}
            return json.loads(res_content)
    except urllib.error.HTTPError as e:
        err_b = e.read().decode("utf-8", errors="ignore")
        print(f"⚠️ Apple API Ответ [{e.code}]: {err_b}")
        return {"error_code": e.code, "body": err_b}

print("🔑 [1/4] Генерация локальной ключевой пары и CSR...")
csr_key_path = Path(runner_tmp) / "dist.key"
csr_path = Path(runner_tmp) / "dist.csr"

subprocess.run(["openssl", "genrsa", "-out", str(csr_key_path), "2048"], check=True)
subprocess.run([
    "openssl", "req", "-new", "-key", str(csr_key_path),
    "-out", str(csr_path), "-subj", f"/CN=iOS Distribution/O=PhoneCare/C=US"
], check=True)

csr_raw = csr_path.read_text()
csr_pem = csr_raw.replace("-----BEGIN CERTIFICATE REQUEST-----", "").replace("-----END CERTIFICATE REQUEST-----", "").replace("\r", "").replace("\n", "").strip()

print("🍎 [2/4] Запрос на создание iOS Distribution сертификата в Apple...")
create_payload = {
    "data": {
        "type": "certificates",
        "attributes": {
            "certificateType": "IOS_DISTRIBUTION",
            "csrContent": csr_pem
        }
    }
}

res = api_request("POST", "/certificates", create_payload)

cer_b64 = None
cert_id_new = None
if "data" in res and "attributes" in res["data"]:
    cer_b64 = res["data"]["attributes"]["certificateContent"]
    cert_id_new = res["data"]["id"]
    print("✅ Сертификат подписи успешно сгенерирован Apple API!")
else:
    print("⚠️ Лимит сертификатов исчерпан или сертификат уже существует. Ищем активный сертификат...")
    certs_res = api_request("GET", "/certificates?filter[certificateType]=IOS_DISTRIBUTION")
    if not certs_res.get("data"):
        certs_res = api_request("GET", "/certificates?filter[certificateType]=DISTRIBUTION")
        
    for old_cert in certs_res.get("data", []):
        cert_id = old_cert["id"]
        print(f"🗑 Авто-отзыв устаревшего сертификата {cert_id}...")
        api_request("DELETE", f"/certificates/{cert_id}")
        
    print("🔄 Повторная генерация свежего сертификата...")
    res_retry = api_request("POST", "/certificates", create_payload)
    if "data" in res_retry and "attributes" in res_retry["data"]:
        cer_b64 = res_retry["data"]["attributes"]["certificateContent"]
        cert_id_new = res_retry["data"]["id"]
        print("✅ Свежий сертификат подписи успешно сгенерирован!")

if cer_b64:
    cer_path = runner_tmp / "dist.cer"
    p12_path = runner_tmp / "dist.p12"
    cer_path.write_bytes(base64.b64decode(cer_b64))
    
    subprocess.run([
        "openssl", "x509", "-inform", "DER", "-in", str(cer_path), "-out", str(runner_tmp / "dist.pem")
    ], check=True)
    
    p12_cmd = [
        "openssl", "pkcs12", "-export", "-legacy", "-out", str(p12_path),
        "-inkey", str(csr_key_path), "-in", str(runner_tmp / "dist.pem"),
        "-passout", "pass:123456"
    ]
    res_p12 = subprocess.run(p12_cmd)
    if res_p12.returncode != 0:
        subprocess.run([
            "openssl", "pkcs12", "-export", "-out", str(p12_path),
            "-inkey", str(csr_key_path), "-in", str(runner_tmp / "dist.pem"),
            "-passout", "pass:123456"
        ], check=True)
    
    keychain_path = os.environ.get("KEYCHAIN_PATH", "")
    keychain_password = os.environ.get("KEYCHAIN_PASSWORD", "123456")
    if keychain_path and Path(keychain_path).exists():
        print(f"🔑 Импорт .p12 сертификата в Keychain: {keychain_path}")
        subprocess.run([
            "security", "import", str(p12_path),
            "-k", keychain_path,
            "-P", "123456",
            "-A", "-T", "/usr/bin/codesign", "-T", "/usr/bin/security"
        ], check=True)
        subprocess.run([
            "security", "list-keychains", "-d", "user", "-s", keychain_path, "login.keychain-db"
        ], check=True)
        try:
            subprocess.run([
                "security", "set-key-partition-list",
                "-S", "apple-tool:,apple:,codesign:",
                "-s", "-k", keychain_password, keychain_path
            ], check=True)
        except Exception as e:
            print(f"⚠️ Warning set-key-partition-list: {e}")
        print("✅ Сертификат подписи успешно импортирован в Keychain!")

print(f"📱 [3/4] Проверка регистрации Bundle ID [{bundle_id}]...")
b_list = api_request("GET", "/bundleIds")
main_b_id = None

for b in b_list.get("data", []):
    bid_identifier = b.get("attributes", {}).get("identifier")
    if bid_identifier == bundle_id:
        main_b_id = b.get("id")
        print(f"✅ Bundle ID найден в Apple Developer: {main_b_id}")
        break

if not main_b_id:
    print(f"⚙️ Регистрация нового Bundle ID [{bundle_id}] в Apple Developer...")
    create_bid_res = api_request("POST", "/bundleIds", {
        "data": {
            "type": "bundleIds",
            "attributes": {
                "identifier": bundle_id,
                "name": "PhoneCare",
                "platform": "IOS"
            }
        }
    })
    main_b_id = create_bid_res.get("data", {}).get("id")
    print(f"✅ Bundle ID успешно зарегистрирован: {main_b_id}")

print("📋 [4/4] Создание и установка App Store Provisioning Profile...")
prof_name = f"PhoneCare_AppStore_{int(time.time())}"
create_prof_payload = {
    "data": {
        "type": "profiles",
        "attributes": {
            "name": prof_name,
            "profileType": "IOS_APP_STORE"
        },
        "relationships": {
            "bundleId": {
                "data": {"type": "bundleIds", "id": main_b_id}
            },
            "certificates": {
                "data": [{"type": "certificates", "id": cert_id_new}]
            }
        }
    }
}

prof_res = api_request("POST", "/profiles", create_prof_payload)
prof_b64 = prof_res.get("data", {}).get("attributes", {}).get("profileContent")
prof_uuid = prof_res.get("data", {}).get("attributes", {}).get("uuid")

if not prof_b64:
    print("⚠️ Поиск существующего профиля...")
    all_profs = api_request("GET", f"/profiles?filter[profileType]=IOS_APP_STORE")
    for p in all_profs.get("data", []):
        if p.get("attributes", {}).get("name", "").startswith("PhoneCare"):
            prof_b64 = p.get("attributes", {}).get("profileContent")
            prof_uuid = p.get("attributes", {}).get("uuid")
            break

if prof_b64:
    mobileprovision_data = base64.b64decode(prof_b64)
    pp_dir = Path.home() / "Library" / "MobileDevice" / "Provisioning Profiles"
    pp_dir.mkdir(parents=True, exist_ok=True)
    
    if prof_uuid:
        target_pp = pp_dir / f"{prof_uuid}.mobileprovision"
        target_pp.write_bytes(mobileprovision_data)
        print(f"✅ Provisioning Profile сохранен: {target_pp}")
        
        # Передаем UUID профиля в GitHub Actions Environment
        with open(github_env, "a") as env_f:
            env_f.write(f"MAIN_APP_PROFILE_UUID={prof_uuid}\n")
            env_f.write(f"PROVISIONING_PROFILE_UUID={prof_uuid}\n")
        print(f"🚀 MAIN_APP_PROFILE_UUID={prof_uuid} экспортирован в GitHub Actions!")
else:
    print("❌ Ошибка: не удалось получить Provisioning Profile от Apple API.")
    sys.exit(1)

print("🎉 Все сертификаты и профили готовы к сборке и загрузке в TestFlight!")
