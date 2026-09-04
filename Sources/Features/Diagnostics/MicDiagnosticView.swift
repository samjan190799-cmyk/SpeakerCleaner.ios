import SwiftUI

// MARK: - Экран комплексного тестирования микрофонов (Mic Diagnostic Suite)
public struct MicDiagnosticView: View {
    @State private var micService = MicDiagnosticService.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            // Главный интерактивный Loopback-тест (Скажи и послушай)
            loopbackTestCard
            
            // VU-метр и замер уровня окружающего шума
            ambientNoiseMeterCard
            
            // Информация о физическом расположении микрофонов
            microphonesLocationInfoCard
        }
    }
    
    // MARK: - Компоненты экрана
    
    private var loopbackTestCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "mic.badge.waveform.fill")
                    .foregroundColor(Theme.waterCyan)
                Text("Тест «Запись и прослушивание»")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }
            
            Text("Нажмите кнопку записи и произнесите контрольную фразу (например: «Раз, два, три, проверка связи»). Запись сразу воспроизведется обратно в динамик для оценки разборчивости и отсутствия хрипов.")
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)
                .lineSpacing(2)
            
            // Анимированный визуализатор записи
            if micService.isRecording {
                VStack(spacing: 10) {
                    HStack(spacing: 4) {
                        ForEach(0..<16) { i in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(LinearGradient.waterGradient)
                                .frame(width: 4, height: max(6, CGFloat(sin(Double(i) + micService.recordDuration * 10) + 1.2) * 16))
                        }
                    }
                    .frame(height: 40)
                    
                    Text("Идет запись... \(String(format: "%.1f", micService.recordDuration)) сек")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.waterCyan)
                }
            } else if micService.isPlayingBack {
                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(Theme.successGreen)
                        .symbolEffect(.bounce)
                    Text("Воспроизведение вашей записи...")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.successGreen)
                }
                .padding(.vertical, 8)
            }
            
            // Кнопки управления тестом
            HStack(spacing: 12) {
                if !micService.isRecording && !micService.isPlayingBack {
                    Button {
                        micService.startVoiceRecord()
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Theme.dangerRed)
                                .frame(width: 10, height: 10)
                            Text("Начать запись (до 6 сек)")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Theme.cardBorder)
                        .foregroundColor(Theme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                } else if micService.isRecording {
                    Button {
                        micService.stopRecordAndPlayback()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "stop.fill")
                            Text("Остановить и прослушать")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Theme.waterCyan)
                        .foregroundColor(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                } else if micService.isPlayingBack {
                    Button {
                        micService.stopPlayback()
                    } label: {
                        Text("Остановить воспроизведение")
                            .font(.system(size: 14, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Theme.dangerRed.opacity(0.2))
                            .foregroundColor(Theme.dangerRed)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                
                // Кнопка повторного прослушивания
                if micService.hasRecordedAudio && !micService.isRecording && !micService.isPlayingBack {
                    Button {
                        micService.playBackRecordedAudio()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 48, height: 48)
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(Theme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
        }
        .padding(18)
        .liquidGlass(cornerRadius: 20)
    }
    
    private var ambientNoiseMeterCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gauge.with.needle.fill")
                    .foregroundColor(Theme.dustGold)
                Text("Уровень шума помещения (VU-метр)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
            }
            
            Text("Замер чувствительности капсюля микрофона и уровня внешнего шума.")
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
            
            VStack(spacing: 8) {
                // Шкала уровня
                GeometryReader { proxy in
                    let normalized = CGFloat(max(0, (micService.currentDecibels + 60.0) / 60.0))
                    
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 12)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.successGreen, Theme.warningYellow, Theme.dangerRed],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: proxy.size.width * normalized, height: 12)
                            .animation(.easeOut(duration: 0.1), value: normalized)
                    }
                }
                .frame(height: 12)
                
                HStack {
                    Text("-60 дБ (Тишина)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Theme.textTertiary)
                    Spacer()
                    Text("Текущий: \(Int(micService.currentDecibels)) дБ")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Text("0 дБ (Пик)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(Theme.textTertiary)
                }
            }
        }
        .padding(18)
        .liquidGlass(cornerRadius: 20)
    }
    
    private var microphonesLocationInfoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Theme.proPurple)
                Text("Где расположены микрофоны в iPhone?")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
            }
            
            VStack(spacing: 8) {
                locationRow(
                    title: "Нижний микрофон",
                    placement: "Слева от порта зарядки",
                    purpose: "Основной разговорный голос при звонках"
                )
                
                locationRow(
                    title: "Фронтальный микрофон",
                    placement: "В решетке разговорного динамика",
                    purpose: "Шумоподавление и звонки по громкой связи"
                )
                
                locationRow(
                    title: "Задний микрофон",
                    placement: "Рядом с блоком камер и вспышкой",
                    purpose: "Запись стереозвука видео и подавление шума ветра"
                )
            }
        }
        .padding(18)
        .liquidGlass(cornerRadius: 20)
    }
    
    private func locationRow(title: String, placement: String, purpose: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundColor(Theme.proPurple)
                .padding(.top, 5)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Text(placement)
                        .font(.caption2)
                        .foregroundColor(Theme.textTertiary)
                }
                
                Text(purpose)
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
