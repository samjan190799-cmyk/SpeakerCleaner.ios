import SwiftUI

// MARK: - Экран Pro-генератора частот (Apple HIG 2026, Liquid Glassmorphism)
public struct ProGeneratorView: View {
    @State private var viewModel = ProGeneratorViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                // Декоративное свечение
                VStack {
                    Circle()
                        .fill(Theme.proPurple.opacity(0.12))
                        .frame(width: 320, height: 320)
                        .blur(radius: 80)
                        .offset(y: -40)
                    Spacer()
                }
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Карточка частоты
                        frequencyCard
                        
                        // Регуляторы шага частоты
                        stepperControls
                        
                        // Селектор формы волны
                        waveformSelector
                        
                        // Модуляция импульсов (Strobe/LFO)
                        modulationCard
                        
                        // Кнопка Старт/Стоп
                        masterPlayButton
                        
                        // Быстрые пресеты
                        presetsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Pro-генератор")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear {
                viewModel.stop()
            }
        }
    }
    
    // MARK: - Компоненты экрана
    
    private var frequencyCard: some View {
        VStack(spacing: 12) {
            Text("Текущая частота")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.textTertiary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(frequencyFormatted)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                
                Text(viewModel.frequency >= 1000 ? "кГц" : "Гц")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Theme.proPurple)
            }
            
            // Логарифмический слайдер частоты (от 20 Гц до 20 000 Гц)
            Slider(
                value: Binding(
                    get: {
                        // Преобразование частоты в логарифмический диапазон 0.0 ... 1.0
                        let minLog = log10(20.0)
                        let maxLog = log10(20000.0)
                        let curLog = log10(Double(viewModel.frequency))
                        return (curLog - minLog) / (maxLog - minLog)
                    },
                    set: { newNorm in
                        let minLog = log10(20.0)
                        let maxLog = log10(20000.0)
                        let logVal = minLog + newNorm * (maxLog - minLog)
                        viewModel.frequency = Float(pow(10.0, logVal))
                    }
                ),
                in: 0.0...1.0
            )
            .tint(Theme.proPurple)
            
            HStack {
                Text("20 Гц")
                    .font(.caption2)
                    .foregroundColor(Theme.textTertiary)
                Spacer()
                Text("1 кГц")
                    .font(.caption2)
                    .foregroundColor(Theme.textTertiary)
                Spacer()
                Text("20 кГц")
                    .font(.caption2)
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .padding(20)
        .liquidGlass(cornerRadius: 20, strokeColor: Theme.proPurple.opacity(0.3))
    }
    
    private var stepperControls: some View {
        HStack(spacing: 8) {
            stepButton("-100", delta: -100)
            stepButton("-10", delta: -10)
            stepButton("-1", delta: -1)
            stepButton("+1", delta: 1)
            stepButton("+10", delta: 10)
            stepButton("+100", delta: 100)
        }
    }
    
    private func stepButton(_ title: String, delta: Float) -> some View {
        Button {
            viewModel.stepFrequency(by: delta)
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.06))
                .foregroundColor(Theme.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
    
    private var waveformSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Форма волны")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(WaveformType.allCases) { wave in
                    let isSelected = viewModel.waveform == wave
                    
                    Button {
                        HapticFeedback.selection()
                        withAnimation(.spring()) {
                            viewModel.waveform = wave
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: wave.iconName)
                                .font(.system(size: 15))
                            Text(wave.rawValue)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(isSelected ? Theme.proPurple.opacity(0.25) : Color.white.opacity(0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(isSelected ? Theme.proPurple : Color.clear, lineWidth: 1.5)
                                )
                        )
                        .foregroundColor(isSelected ? Theme.textPrimary : Theme.textTertiary)
                    }
                }
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 18)
    }
    
    private var modulationCard: some View {
        VStack(spacing: 12) {
            Toggle(isOn: $viewModel.isPulsing) {
                HStack(spacing: 8) {
                    Image(systemName: "waveform.badge.magnifyingglass")
                        .foregroundColor(Theme.proPurple)
                    Text("Импульсная модуляция (Строб)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                }
            }
            .tint(Theme.proPurple)
            
            if viewModel.isPulsing {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Интервал импульса")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                        Spacer()
                        Text("\(Int(viewModel.pulseInterval * 1000)) мс")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.proPurple)
                    }
                    
                    Slider(value: $viewModel.pulseInterval, in: 0.05...1.0, step: 0.05)
                        .tint(Theme.proPurple)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 18)
    }
    
    private var masterPlayButton: some View {
        Button {
            viewModel.togglePlayback()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.fill")
                    .font(.title3)
                Text(viewModel.isPlaying ? "Остановить генератор" : "Запустить генератор")
                    .font(.system(size: 17, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(viewModel.isPlaying ? Theme.dangerRed : Theme.proPurple)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: (viewModel.isPlaying ? Theme.dangerRed : Theme.proPurple).opacity(0.4), radius: 12, x: 0, y: 6)
        }
    }
    
    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Калибровочные пресеты")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
            
            VStack(spacing: 8) {
                ForEach(viewModel.presets) { preset in
                    Button {
                        viewModel.applyPreset(preset)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Theme.textPrimary)
                                Text(preset.description)
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.textTertiary)
                            }
                            
                            Spacer()
                            
                            Text("\(Int(preset.freq)) Гц")
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.proPurple)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Theme.proPurple.opacity(0.15)))
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 18)
    }
    
    private var frequencyFormatted: String {
        if viewModel.frequency >= 1000 {
            return String(format: "%.2f", viewModel.frequency / 1000.0)
        } else {
            return String(format: "%.1f", viewModel.frequency)
        }
    }
}
