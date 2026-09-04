import SwiftUI

// MARK: - Экран спектральной диагностики динамиков и микрофона
public struct DiagnosticsView: View {
    @State private var viewModel = DiagnosticsViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Карточка раздельного теста каналов
                        channelTestSection
                        
                        // Спектральный анализ через микрофон
                        spectralTestSection
                        
                        // Результат диагностики (если тест был проведен)
                        if let result = viewModel.lastResult {
                            diagnosticResultCard(result)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Диагностика")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Компоненты экрана
    
    private var channelTestSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "headphones")
                    .foregroundColor(Theme.waterCyan)
                Text("Раздельный тест каналов")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
            }
            
            Text("Проверьте работу каждого динамика по отдельности воспроизведением калибровочного стерео-сигнала.")
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)
            
            HStack(spacing: 12) {
                channelButton(
                    title: "Основной (Нижний)",
                    channel: .main,
                    icon: "speaker.wave.3.fill"
                )
                
                channelButton(
                    title: "Разговорный (Верхний)",
                    channel: .earpiece,
                    icon: "phone.badge.waveform.fill"
                )
            }
        }
        .padding(18)
        .liquidGlass(cornerRadius: 20)
    }
    
    private func channelButton(title: String, channel: SpeakerChannel, icon: String) -> some View {
        let isTestingThis = viewModel.isTestingChannel && viewModel.selectedChannel == channel
        
        return Button {
            viewModel.testChannel(channel)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .symbolEffect(.bounce, value: isTestingThis)
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 85)
            .background(isTestingThis ? Theme.waterCyan.opacity(0.25) : Color.white.opacity(0.04))
            .foregroundColor(isTestingThis ? Theme.waterCyan : Theme.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isTestingThis ? Theme.waterCyan : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .disabled(viewModel.isTestingChannel || viewModel.isRunningSpectralTest)
    }
    
    private var spectralTestSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "waveform.badge.mic")
                    .foregroundColor(Theme.dustGold)
                Text("Оценка чистоты через микрофон")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
            }
            
            Text("Приложение подаст тестовый свип-сигнал и через микрофон измерит амплитудно-частотную характеристику (FFT) для выявления загрязнения сетки.")
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)
            
            // Живой спектрограф
            SpectrumView(
                bands: SpectralAnalyzer.shared.spectrumBands,
                isActive: viewModel.isRunningSpectralTest,
                tintColor: Theme.dustGold
            )
            
            if viewModel.isRunningSpectralTest {
                VStack(spacing: 8) {
                    HStack {
                        Text(viewModel.currentTestPhaseText)
                            .font(.caption)
                            .foregroundColor(Theme.dustGold)
                        Spacer()
                        Text("\(Int(viewModel.testProgress * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.textSecondary)
                    }
                    
                    ProgressView(value: viewModel.testProgress)
                        .tint(Theme.dustGold)
                }
            } else {
                Button {
                    viewModel.startSpectralTest()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                        Text("Запустить спектральный тест")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Theme.dustGradient)
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Theme.dustGold.opacity(0.35), radius: 10, x: 0, y: 4)
                }
                .disabled(viewModel.isTestingChannel)
            }
        }
        .padding(18)
        .liquidGlass(cornerRadius: 20)
    }
    
    private func diagnosticResultCard(_ result: DiagnosticResult) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.statusTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(result.statusColor)
                    
                    Text(result.recommendation)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSecondary)
                }
                
                Spacer()
                
                // Кольцо с процентом чистоты
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    Circle()
                        .trim(from: 0.0, to: CGFloat(result.cleanlinessScore) / 100.0)
                        .stroke(result.statusColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(result.cleanlinessScore)%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                }
                .frame(width: 70, height: 70)
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Анализ частотных диапазонов
            VStack(spacing: 10) {
                clarityRow(title: "Низкие частоты (Бас)", value: result.bassClarity)
                clarityRow(title: "Средние частоты (Речь)", value: result.midClarity)
                clarityRow(title: "Высокие частоты (Чистота сетки)", value: result.trebleClarity)
            }
        }
        .padding(18)
        .liquidGlass(cornerRadius: 20, strokeColor: result.statusColor.opacity(0.4))
    }
    
    private func clarityRow(title: String, value: Double) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.textPrimary)
            }
            
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    Capsule()
                        .fill(LinearGradient.waterGradient)
                        .frame(width: proxy.size.width * CGFloat(min(max(value, 0.0), 1.0)), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}
