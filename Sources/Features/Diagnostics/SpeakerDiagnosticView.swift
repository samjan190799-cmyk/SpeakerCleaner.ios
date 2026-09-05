import SwiftUI

// MARK: - Экран комплексного тестирования динамиков (Speaker Diagnostic Suite)
public struct SpeakerDiagnosticView: View {
    @State private var viewModel = DiagnosticsViewModel()
    @State private var activeTestName: String? = nil
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            // Интерактивный 3D-визуализатор излучения звука
            deviceVisualizerCard
            
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
    
    // MARK: - Интерактивный визуализатор излучения звука
    
    private var deviceVisualizerCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .foregroundColor(viewModel.isTestingChannel ? (viewModel.selectedChannel == .earpiece ? Theme.dustGold : Theme.waterCyan) : Theme.waterCyan)
                    .symbolEffect(.variableColor.iterative, isActive: viewModel.isTestingChannel)
                
                Text("Акустическая карта устройства")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                if viewModel.isTestingChannel {
                    Text(viewModel.selectedChannel == .earpiece ? "Ресивер (1100 Гц)" : "Спикер (440 Гц)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.selectedChannel == .earpiece ? Theme.dustGold : Theme.waterCyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill((viewModel.selectedChannel == .earpiece ? Theme.dustGold : Theme.waterCyan).opacity(0.15))
                        )
                }
            }
            
            HStack(spacing: 22) {
                // Силуэт смартфона с физическими излучателями
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(hex: "0D1118"))
                        .frame(width: 80, height: 135)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.18), lineWidth: 1.5)
                        )
                    
                    VStack {
                        // Верхний слуховой динамик (ресивер)
                        ZStack {
                            if viewModel.isTestingChannel && viewModel.selectedChannel == .earpiece {
                                AcousticWaveRipples(color: Theme.dustGold, isActive: true)
                                    .frame(width: 44, height: 44)
                                    .offset(y: -4)
                            }
                            
                            Capsule()
                                .fill(viewModel.isTestingChannel && viewModel.selectedChannel == .earpiece ? Theme.dustGold : Color.white.opacity(0.35))
                                .frame(width: 24, height: 4)
                                .shadow(color: Theme.dustGold.opacity(viewModel.isTestingChannel && viewModel.selectedChannel == .earpiece ? 1.0 : 0.0), radius: 6)
                        }
                        .padding(.top, 10)
                        
                        Spacer()
                        
                        // Экранное стекло
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.white.opacity(0.02))
                            .frame(width: 66, height: 80)
                            .overlay(
                                Image(systemName: viewModel.isTestingChannel ? "waveform" : "iphone")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color.white.opacity(0.1))
                            )
                        
                        Spacer()
                        
                        // Нижние порты динамика
                        ZStack {
                            if viewModel.isTestingChannel && viewModel.selectedChannel == .main {
                                AcousticWaveRipples(color: Theme.waterCyan, isActive: true)
                                    .frame(width: 44, height: 44)
                                    .offset(y: 4)
                            }
                            
                            HStack(spacing: 3) {
                                ForEach(0..<4) { _ in
                                    Circle()
                                        .fill(viewModel.isTestingChannel && viewModel.selectedChannel == .main ? Theme.waterCyan : Color.white.opacity(0.35))
                                        .frame(width: 3.5, height: 3.5)
                                }
                            }
                            .shadow(color: Theme.waterCyan.opacity(viewModel.isTestingChannel && viewModel.selectedChannel == .main ? 1.0 : 0.0), radius: 6)
                        }
                        .padding(.bottom, 10)
                    }
                    .frame(height: 135)
                }
                
                // Текстовая информация и эквалайзер
                VStack(alignment: .leading, spacing: 8) {
                    if viewModel.isTestingChannel {
                        let isEarpiece = viewModel.selectedChannel == .earpiece
                        let color = isEarpiece ? Theme.dustGold : Theme.waterCyan
                        
                        HStack(spacing: 8) {
                            LiveEqualizerBars(color: color, count: 5, isPlaying: true)
                            Text(isEarpiece ? "Тест верхнего динамика" : "Тест нижнего динамика")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(color)
                        }
                        
                        Text(isEarpiece
                             ? "Звуковой поток направлен исключительно в слуховой ресивер на резонансной частоте."
                             : "Звук строго изолирован в нижнем динамике без подмешивания стерео.")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                            .lineSpacing(2)
                        
                        // Полоса обратного отсчета теста
                        ProgressView(value: viewModel.testProgress, total: 1.0)
                            .tint(color)
                            .padding(.top, 2)
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.shield")
                                .foregroundColor(Theme.successGreen)
                            Text("Готов к раздельной проверке")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                        }
                        
                        Text("Нажмите на один из динамиков ниже. Калибровочный тон подается раздельно в каждый физический канал.")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                            .lineSpacing(3)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .liquidGlass(
            cornerRadius: 20,
            strokeColor: viewModel.isTestingChannel
                ? (viewModel.selectedChannel == .earpiece ? Theme.dustGold : Theme.waterCyan).opacity(0.4)
                : Theme.cardBorder
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.isTestingChannel)
    }
    
    // MARK: - Раздельный тест каналов
    
    private var channelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundColor(Theme.waterCyan)
                Text("Раздельный тест каналов")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
            }
            
            Text("Подайте тестовый тон на каждый спикер по отдельности, чтобы проверить баланс громкости и отсутствие хрипа.")
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
            
            HStack(spacing: 12) {
                testButton(
                    title: "Нижний динамик",
                    subtitle: "Мультимедиа (440 Гц)",
                    icon: "speaker.wave.3.fill",
                    color: Theme.waterCyan,
                    channel: .main
                )
                
                testButton(
                    title: "Верхний спикер",
                    subtitle: "Разговорный (1100 Гц)",
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
                ZStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isTesting ? color : Theme.textPrimary)
                        .symbolEffect(.bounce, value: isTesting)
                    
                    if isTesting {
                        LiveEqualizerBars(color: color, count: 3, isPlaying: true)
                            .offset(x: 28)
                    }
                }
                
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                
                Text(isTesting ? "Воспроизведение..." : subtitle)
                    .font(.caption2)
                    .foregroundColor(isTesting ? color : Theme.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 88)
            .background(isTesting ? color.opacity(0.18) : Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isTesting ? color : Color.white.opacity(0.08), lineWidth: isTesting ? 1.5 : 1)
            )
            .shadow(color: isTesting ? color.opacity(0.4) : Color.clear, radius: 10)
        }
        .disabled(viewModel.isTestingChannel || viewModel.isRunningSpectralTest)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isTesting)
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
                ZStack {
                    Image(systemName: isRunningThis ? "stop.fill" : "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(isRunningThis ? Theme.dangerRed : Theme.proPurple)
                    
                    if isRunningThis {
                        Circle()
                            .stroke(Theme.dangerRed.opacity(0.4), lineWidth: 2)
                            .scaleEffect(1.3)
                            .animation(.easeOut(duration: 0.8).repeatForever(autoreverses: false), value: isRunningThis)
                    }
                }
                
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
                
                if isRunningThis {
                    LiveEqualizerBars(color: Theme.proPurple, count: 4, isPlaying: true)
                }
            }
            .padding(12)
            .background(isRunningThis ? Theme.proPurple.opacity(0.15) : Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isRunningThis ? Theme.proPurple.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isRunningThis)
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

// MARK: - Анимированные компоненты для визуализации звука

struct AcousticWaveRipples: View {
    let color: Color
    let isActive: Bool
    
    @State private var isAnimating: Bool = false
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                Circle()
                    .stroke(color.opacity(isActive ? 0.7 - Double(index) * 0.2 : 0.0), lineWidth: 1.5)
                    .scaleEffect(isAnimating && isActive ? 1.0 + CGFloat(index) * 0.5 : 0.3)
                    .opacity(isAnimating && isActive ? 0.0 : (isActive ? 0.8 : 0.0))
                    .animation(
                        isActive
                            ? Animation.easeOut(duration: 1.1)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.3)
                            : .default,
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct LiveEqualizerBars: View {
    let color: Color
    let count: Int
    let isPlaying: Bool
    
    init(color: Color, count: Int = 4, isPlaying: Bool) {
        self.color = color
        self.count = count
        self.isPlaying = isPlaying
    }
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<count, id: \.self) { index in
                SingleBar(color: color, isPlaying: isPlaying, delay: Double(index) * 0.12)
            }
        }
    }
}

struct SingleBar: View {
    let color: Color
    let isPlaying: Bool
    let delay: Double
    
    @State private var barHeight: CGFloat = 5
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 3, height: isPlaying ? barHeight : 4)
            .animation(
                isPlaying
                    ? Animation.easeInOut(duration: 0.32)
                        .repeatForever(autoreverses: true)
                        .delay(delay)
                    : .default,
                value: barHeight
            )
            .onAppear {
                if isPlaying {
                    barHeight = CGFloat.random(in: 10...20)
                }
            }
            .onChange(of: isPlaying) { _, playing in
                if playing {
                    barHeight = CGFloat.random(in: 10...20)
                } else {
                    barHeight = 4
                }
            }
    }
}
