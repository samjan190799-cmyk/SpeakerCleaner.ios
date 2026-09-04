import SwiftUI

// MARK: - Единый хаб инструментов ухода (Tools Hub)
public struct ToolsHubView: View {
    @State private var showScreenLock: Bool = false
    @State private var showPixelTest: Bool = false
    @State private var selectedToolSegment: Int = 0 // 0: Speaker Cleaner, 1: Pro Synth
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Верхний блок быстрых экранных инструментов
                        screenToolsHeader
                        
                        // Сегментный переключатель между Очисткой и Pro-синтезом
                        toolModeSelector
                        
                        // Отображение выбранного инструмента
                        if selectedToolSegment == 0 {
                            CleanerView()
                        } else {
                            ProGeneratorView()
                        }
                    }
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Инструменты")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showScreenLock) {
                ScreenCleanLockView()
            }
            .fullScreenCover(isPresented: $showPixelTest) {
                DisplayPixelTestView()
            }
        }
    }
    
    // MARK: - Компоненты экрана
    
    private var screenToolsHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Экранные инструменты")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .padding(.horizontal, 20)
            
            HStack(spacing: 12) {
                // Кнопка блокировки экрана для протирки
                Button {
                    HapticFeedback.impact(.medium)
                    showScreenLock = true
                } label: {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Theme.waterCyan.opacity(0.18))
                            .frame(width: 42, height: 42)
                            .overlay(
                                Image(systemName: "sparkles")
                                    .foregroundColor(Theme.waterCyan)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Режим протирки")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Theme.textPrimary)
                            Text("Блокировка сенсора")
                                .font(.caption2)
                                .foregroundColor(Theme.textTertiary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .liquidGlass(cornerRadius: 16)
                }
                
                // Кнопка теста матрицы дисплея
                Button {
                    HapticFeedback.impact(.medium)
                    showPixelTest = true
                } label: {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Theme.dustGold.opacity(0.18))
                            .frame(width: 42, height: 42)
                            .overlay(
                                Image(systemName: "checkerboard.rectangle")
                                    .foregroundColor(Theme.dustGold)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Тест матрицы")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Theme.textPrimary)
                            Text("Битые пиксели")
                                .font(.caption2)
                                .foregroundColor(Theme.textTertiary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .liquidGlass(cornerRadius: 16)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var toolModeSelector: some View {
        HStack(spacing: 8) {
            segmentButton(title: "Очистка динамиков", icon: "speaker.wave.3.fill", index: 0)
            segmentButton(title: "Pro-генератор", icon: "slider.horizontal.3", index: 1)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .padding(.horizontal, 20)
    }
    
    private func segmentButton(title: String, icon: String, index: Int) -> some View {
        let isSelected = selectedToolSegment == index
        
        return Button {
            HapticFeedback.selection()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedToolSegment = index
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Theme.waterCyan.opacity(0.2) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isSelected ? Theme.waterCyan.opacity(0.8) : Color.clear, lineWidth: 1)
                    )
            )
            .foregroundColor(isSelected ? Theme.textPrimary : Theme.textTertiary)
        }
    }
}
