#!/usr/bin/env python3
"""
Получение информации о кодах и ссылках инвайтов бета-тестировщиков TestFlight
"""
import os, sys, base64, json, urllib.request, urllib.error, time
from pathlib import Path

key_id     = os.environ.get("APPSTORE_KEY_ID", "").strip()
issuer_id  = os.environ.get("APPSTORE_ISSUER_ID", "").strip()
key_path   = os.environ.get("AUTH_KEY_PATH", "").strip()

if not key_id or not issuer_id or not key_path:
    print("❌ Ошибка: переменные API ключа не найдены!")
    sys.exit(1)

try:
    from cryptography.hazmat.primitives import serialization, hashes
    from cryptography.hazmat.primitives.asymmetric import ec, utils
except ImportError:
    import subprocess
    subprocess.run([sys.executable, "-m", "pip", "install", "--break-system-packages", "cryptography"], check=True)
    from cryptography.hazmat.primitives import serialization, hashes
    from cryptography.hazmat.primitives.asymmetric import ec, utils

# Читаем .p8 ключ
with open(key_path, "rb") as f:
    key_bytes = f.read().replace(b"\r\n", b"\n").replace(b"\r", b"\n").strip()
    pk = serialization.load_pem_private_key(key_bytes, password=None)

def base64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode('utf-8')

# Генерируем JWT токен
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
            if r.status in (200, 201):
                res_content = r.read()
                return json.loads(res_content) if res_content else {"status": "success"}
            return {"status": "success"}
    except urllib.error.HTTPError as e:
        err_b = e.read().decode("utf-8", errors="ignore")
        print(f"⚠️ Apple API Response [{e.code}]: {err_b}")
        return {"error_code": e.code, "body": err_b}

print("==========================================")
print("🔑 ИНФОРМАЦИЯ О ГРУППАХ И ТЕСТИРОВЩИКАХ TESTFLIGHT")
print("==========================================")

groups_res = api_request("GET", "/betaGroups?include=builds")
print("\n📁 БЕТА-ГРУППЫ:")
for g in groups_res.get("data", []):
    attrs = g.get("attributes", {})
    g_name = attrs.get("name")
    is_internal = attrs.get("isInternalGroup")
    pub_link = attrs.get("publicLink")
    pub_enabled = attrs.get("publicLinkEnabled")
    print(f" • Группа: [{g_name}] | Internal: {is_internal} | PublicLinkEnabled: {pub_enabled} | Link: {pub_link}")

testers_res = api_request("GET", "/betaTesters")
print("\n👥 СПИСОК ТЕСТИРОВЩИКОВ:")
for t in testers_res.get("data", []):
    attrs = t.get("attributes", {})
    t_email = attrs.get("email")
    t_state = attrs.get("inviteType")
    print(f" • Tester Email: {t_email} | State/Type: {t_state} | ID: {t.get('id')}")

print("==========================================")
