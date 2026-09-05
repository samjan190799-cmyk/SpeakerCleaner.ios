import SwiftUI

// MARK: - Главный экран очистки динамика (Apple HIG 2026, Liquid Glassmorphism)
public struct CleanerView: View {
    @State private var viewModel = CleanerViewModel()
    @State private var showChannelSheet = false
    @State private var showProUpgrade = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Фоновый градиент темы
                Theme.background
                    .ignoresSafeArea()
                
                // Декоративные световые пятна (Ambient Glow)
                ambientBackgroundGlow
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Верхняя панель статуса и переключателей
                        headerBar
                        
                        // Предупреждение о громкости (если ниже 100%)
                        if viewModel.showVolumeWarning {
                            volumeWarningBanner
                        }
                        
                        // Селектор каналов вывода (Основной / Разговорный)
                        channelSelectorCard
                        
                        // Селектор программ очистки (Вода / Пыль / Pro)
                        ModeSelectorView(
                            selectedMode: $viewModel.selectedMode,
                            isRunning: viewModel.isRunning
                        )
                        
                        // Центральный круговой прогресс, таймер и физика брызг
                        ZStack {
                            WaterDropletsEmitterView(
                                isActive: viewModel.isRunning && !viewModel.isPaused,
                                mode: viewModel.selectedMode,
                                burstTrigger: viewModel.burstTriggerCounter
                            )
                            
                            ProgressRingView(
                                progress: viewModel.progress,
                                remainingSeconds: viewModel.remainingSeconds,
                                currentFrequency: viewModel.currentFrequency,
                                isRunning: viewModel.isRunning && !viewModel.isPaused,
                                mode: viewModel.selectedMode
                            )
                        }
                        .padding(.vertical, 8)
                        
                        // Динамический визуализатор звуковых волн
                        WaveformVisualizer(
                            isActive: viewModel.isRunning && !viewModel.isPaused,
                            color: viewModel.selectedMode.primaryColor,
                            frequency: viewModel.currentFrequency,
                            isPulsing: viewModel.selectedMode == .water
                        )
                        .padding(.horizontal)
                        
                        // Кнопки управления (Старт / Пауза / Сброс)
                        controlButtons
                        
                        // Информационная подсказка по положению устройства
                        deviceOrientationTip
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundStyle(Theme.waterCyan)
                        Text("Speaker Cleaner")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticFeedback.impact(.medium)
                        showProUpgrade = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                            Text("PRO")
                                .font(.system(size: 11, weight: .black))
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(
                            LinearGradient(
                                colors: [Theme.dustGold, Color(hex: "FFAA00")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                        .shadow(color: Theme.dustGold.opacity(0.4), radius: 6)
                    }
                }
            }
            .sheet(isPresented: $viewModel.isFinished) {
                completionSheet
            }
            .sheet(isPresented: $showProUpgrade) {
                ProUpgradeView()
            }
        }
    }
    
    // MARK: - Компоненты экрана
    
    private var ambientBackgroundGlow: some View {
        VStack {
            Circle()
                .fill(viewModel.selectedMode.primaryColor.opacity(0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(y: -50)
            Spacer()
        }
        .ignoresSafeArea()
    }
    
    private var headerBar: some View {
        HStack {
            // Переключатель Haptic Boost
            Button {
                HapticFeedback.selection()
                withAnimation(.spring()) {
                    viewModel.isHapticBoostEnabled.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.isHapticBoostEnabled ? "iphone.radiowaves.left.and.right" : "iphone.slash")
                        .font(.caption)
                    Text("Haptic Boost")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(viewModel.isHapticBoostEnabled ? Theme.waterCyan.opacity(0.15) : Color.white.opacity(0.06))
                        .overlay(
                            Capsule()
                                .stroke(viewModel.isHapticBoostEnabled ? Theme.waterCyan.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .foregroundColor(viewModel.isHapticBoostEnabled ? Theme.waterCyan : Theme.textTertiary)
            }
            
            Spacer()
            
            // Индикатор громкости
            HStack(spacing: 4) {
                Image(systemName: AudioSessionManager.shared.isMaxVolume ? "speaker.wave.3.fill" : "speaker.wave.1.fill")
                    .foregroundColor(AudioSessionManager.shared.isMaxVolume ? Theme.successGreen : Theme.warningYellow)
                    .font(.caption)
                Text("\(Int(AudioSessionManager.shared.currentVolume * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.white.opacity(0.06)))
        }
    }
    
    private var volumeWarningBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Theme.warningYellow)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Громкость ниже 100%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text("Для эффективного выдувания капель увеличьте звук до максимума боковыми кнопками.")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
            
            Button {
                withAnimation {
                    viewModel.showVolumeWarning = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(Theme.textTertiary)
                    .padding(6)
            }
        }
        .padding(14)
        .liquidGlass(cornerRadius: 16, strokeColor: Theme.warningYellow.opacity(0.4))
    }
    
    private var channelSelectorCard: some View {
        HStack(spacing: 12) {
            ForEach(SpeakerChannel.allCases) { channel in
                let isSelected = viewModel.selectedChannel == channel
                
                Button {
                    guard !viewModel.isRunning else { return }
                    HapticFeedback.selection()
                    withAnimation(.spring()) {
                        viewModel.selectedChannel = channel
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: channel.iconName)
                            .font(.system(size: 13))
                        Text(channel.shortTitle)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(isSelected ? Color.white.opacity(0.4) : Color.clear, lineWidth: 1)
                            )
                    )
                    .foregroundColor(isSelected ? Theme.textPrimary : Theme.textTertiary)
                }
                .disabled(viewModel.isRunning)
            }
        }
        .padding(8)
        .liquidGlass(cornerRadius: 16)
    }
    
    private var controlButtons: some View {
        VStack(spacing: 12) {
            if !viewModel.isRunning {
                // Большая главная кнопка запуска
                Button {
                    viewModel.startCleaning()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.title3)
                        Text("Начать очистку")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(viewModel.selectedMode.gradient)
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: viewModel.selectedMode.primaryColor.opacity(0.4), radius: 14, x: 0, y: 6)
                }
            } else {
                HStack(spacing: 12) {
                    // Кнопка Пауза / Продолжить
                    Button {
                        if viewModel.isPaused {
                            viewModel.resumeCleaning()
                        } else {
                            viewModel.pauseCleaning()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                            Text(viewModel.isPaused ? "Продолжить" : "Пауза")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.white.opacity(0.12))
                        .foregroundColor(Theme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    
                    // Кнопка Стоп
                    Button {
                        viewModel.stopCleaning()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "stop.fill")
                            Text("Стоп")
                                .fontWeight(.semibold)
                        }
                        .frame(width: 120)
                        .frame(height: 54)
                        .background(Theme.dangerRed.opacity(0.18))
                        .foregroundColor(Theme.dangerRed)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Theme.dangerRed.opacity(0.4), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
    
    private var deviceOrientationTip: some View {
        HStack(spacing: 14) {
            Image(systemName: "arrow.down.to.line.compact")
                .font(.title2)
                .foregroundColor(viewModel.selectedMode.primaryColor)
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Правильное положение")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text("Поверните телефон динамиками вниз и слегка встряхивайте устройство во время звукового цикла.")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 18)
    }
    
    private var completionSheet: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Circle()
                    .fill(Theme.successGreen.opacity(0.2))
                    .frame(width: 90, height: 90)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(Theme.successGreen)
                    )
                    .shadow(color: Theme.successGreen.opacity(0.5), radius: 20)
                
                VStack(spacing: 8) {
                    Text("Цикл очистки завершен!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("Вся акустическая полость была обработана звуковыми импульсами. Проверьте результат с помощью спектрального анализатора.")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button {
                    viewModel.stopCleaning()
                } label: {
                    Text("Готово")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Theme.successGreen)
                        .foregroundColor(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 24)
            }
            .padding()
        }
        .presentationDetents([.fraction(0.45)])
    }
}
