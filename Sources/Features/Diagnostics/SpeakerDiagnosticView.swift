import SwiftUI

// MARK: - Экран комплексного тестирования динамиков (Speaker Diagnostic Suite)
public struct SpeakerDiagnosticView: View {
    @State private var viewModel = DiagnosticsViewModel()
    @State private var activeTestName: String? = nil
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            // Раздельная проверка каналов (Нижний vs Верхний)
            channelSection
            
            // Специализированные акустические стресс-тесты
            acousticStressTestsSection
            
            // Автоматический спектральный замер отклика через микрофон
            spectralMicrophoneAnalysisSection
            
            // Карточка с результатами теста (если проведен)
            if let result = viewModel.lastResult {
                diagnosticResultCard(result)
            }
        }
    }
    
    // MARK: - Компоненты экрана
    
    private var channelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundColor(Theme.waterCyan)
                Text("Раздельный тест каналов")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
            }
            
            Text("Подайте тестовый тон на каждый спикер по отдельности, чтобы проверить баланс громкости.")
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
            
            HStack(spacing: 12) {
                testButton(
                    title: "Нижний динамик",
                    subtitle: "Мультимедиа",
                    icon: "speaker.wave.3.fill",
                    color: Theme.waterCyan,
                    channel: .main
                )
                
                testButton(
                    title: "Верхний спикер",
                    subtitle: "Разговорный",
                    icon: "phone.badge.waveform.fill",
                    color: Theme.dustGold,
                    channel: .earpiece
                )
            }
        }
        .padding(18)
        .liquidGlass(cornerRadius: 20)
    }
    
    private func testButton(title: String, subtitle: String, icon: String, color: Color, channel: SpeakerChannel) -> some View {
        let isTesting = viewModel.isTestingChannel && viewModel.selectedChannel == channel
        
        return Button {
            viewModel.testChannel(channel)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isTesting ? color : Theme.textPrimary)
                    .symbolEffect(.bounce, value: isTesting)
                
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(Theme.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 85)
            .background(isTesting ? color.opacity(0.18) : Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isTesting ? color : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .disabled(viewModel.isTestingChannel || viewModel.isRunningSpectralTest)
    }
    
    private var acousticStressTestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "waveform.badge.magnifyingglass")
                    .foregroundColor(Theme.proPurple)
                Text("Стресс-тесты мембраны")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
            }
            
            Text("Проверка на механические дефекты диффузора и засорение защитных решеток.")
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
            
            VStack(spacing: 8) {
                stressRow(
                    title: "Тест на дребезг мембраны (Суббас 60 Гц)",
                    desc: "Выявляет надорванную катушку или попавшие под мембрану твердые песчинки.",
                    freq: 60.0,
                    wave: .sine,
                    duration: 3.0
                )
                
                stressRow(
                    title: "Тест четкости речи (Голос 1.5 кГц)",
                    desc: "Проверяет разборчивость голоса собеседника в телефонном разговоре.",
                    freq: 1500.0,
                    wave: .sine,
                    duration: 3.0
                )
                
                stressRow(
                    title: "Тест проходимости сетки (Высокие 8 кГц)",
                    desc: "Выявляет глухоту звучания из-за забитой жиром или пылью акустической ткани.",
                    freq: 8000.0,
                    wave: .triangle,
                    duration: 3.0
                )
            }
        }
        .padding(18)
        .liquidGlass(cornerRadius: 20)
    }
    
    private func stressRow(title: String, desc: String, freq: Float, wave: WaveformType, duration: Double) -> some View {
        let isRunningThis = activeTestName == title
        
        return Button {
            runStressTone(name: title, freq: freq, wave: wave, duration: duration)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isRunningThis ? "stop.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(isRunningThis ? Theme.dangerRed : Theme.proPurple)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    Text(desc)
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }
            .padding(12)
            .background(isRunningThis ? Theme.proPurple.opacity(0.15) : Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
    
    private func runStressTone(name: String, freq: Float, wave: WaveformType, duration: Double) {
        if activeTestName == name {
            AudioEngineService.shared.stop()
            activeTestName = nil
            return
        }
        
        activeTestName = name
        AudioEngineService.shared.startTone(frequency: freq, waveform: wave, volume: 1.0, channel: viewModel.selectedChannel)
        HapticFeedback.notification(.warning)
        
        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if activeTestName == name {
                AudioEngineService.shared.stop()
                activeTestName = nil
                HapticFeedback.notification(.success)
            }
        }
    }
    
    private var spectralMicrophoneAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(Theme.dustGold)
                Text("Автоматическая спектральная оценка (FFT)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
            }
            
            Text("Приложение подаст свип-сигнал и через микрофон снимет АЧХ для расчета индекса чистоты (0–100%).")
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
            
            // Живой спектрограф
            SpectrumView(
                bands: SpectralAnalyzer.shared.spectrumBands,
                isActive: viewModel.isRunningSpectralTest,
                tintColor: Theme.dustGold
            )
            
            if viewModel.isRunningSpectralTest {
                VStack(spacing: 6) {
                    HStack {
                        Text(viewModel.currentTestPhaseText)
                            .font(.caption)
                            .foregroundColor(Theme.dustGold)
                        Spacer()
                        Text("\(Int(viewModel.testProgress * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.textPrimary)
                    }
                    ProgressView(value: viewModel.testProgress)
                        .tint(Theme.dustGold)
                }
            } else {
                Button {
                    viewModel.startSpectralTest()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "waveform.badge.mic")
                        Text("Запустить спектральный анализ")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.dustGradient)
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(viewModel.isTestingChannel)
            }
        }
        .padding(18)
        .liquidGlass(cornerRadius: 20)
    }
    
    private func diagnosticResultCard(_ result: DiagnosticResult) -> some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.statusTitle)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(result.statusColor)
                    Text(result.recommendation)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 6)
                    Circle()
                        .trim(from: 0.0, to: CGFloat(result.cleanlinessScore) / 100.0)
                        .stroke(result.statusColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(result.cleanlinessScore)%")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                }
                .frame(width: 64, height: 64)
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 18, strokeColor: result.statusColor.opacity(0.4))
    }
}
