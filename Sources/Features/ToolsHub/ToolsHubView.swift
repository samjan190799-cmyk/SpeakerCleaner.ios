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
        VStack(alignment: .leading, spacing: 12) {
            Text("Экранные инструменты")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Theme.textSecondary)
                .padding(.horizontal, 20)
            
            HStack(spacing: 12) {
                // Кнопка блокировки экрана для протирки
                screenToolCard(
                    title: "Режим протирки",
                    subtitle: "Блокировка сенсора",
                    icon: "sparkles",
                    color: Theme.waterCyan,
                    badge: "30–60 с"
                ) {
                    HapticFeedback.impact(.medium)
                    showScreenLock = true
                }
                
                // Кнопка теста матрицы дисплея
                screenToolCard(
                    title: "Тест матрицы",
                    subtitle: "Битые пиксели",
                    icon: "checkerboard.rectangle",
                    color: Theme.dustGold,
                    badge: "OLED / LCD"
                ) {
                    HapticFeedback.impact(.medium)
                    showPixelTest = true
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func screenToolCard(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        badge: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center) {
                    Circle()
                        .fill(color.opacity(0.18))
                        .frame(width: 38, height: 38)
                        .overlay(
                            Image(systemName: icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(color)
                        )
                    
                    Spacer()
                    
                    Text(badge)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(color.opacity(0.12))
                        .clipShape(Capsule())
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.textTertiary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 104)
            .padding(12)
            .liquidGlass(cornerRadius: 18, strokeColor: color.opacity(0.25))
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
