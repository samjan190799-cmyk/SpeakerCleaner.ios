import SwiftUI

// MARK: - Центральный диагностический центр (Динамики, Микрофоны, Чек-лист)
public struct DiagnosticsHubView: View {
    @State private var selectedTab: Int = 0 // 0: Динамики, 1: Микрофоны, 2: Чек-лист
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Верхний 3-позиционный селектор
                        tabSelectorBar
                        
                        // Выбранный диагностический экран
                        if selectedTab == 0 {
                            SpeakerDiagnosticView()
                                .padding(.horizontal, 20)
                        } else if selectedTab == 1 {
                            MicDiagnosticView()
                                .padding(.horizontal, 20)
                        } else {
                            CareChecklistView()
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 14)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Диагностический центр")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Компоненты экрана
    
    private var tabSelectorBar: some View {
        HStack(spacing: 6) {
            tabButton(title: "Динамики", icon: "speaker.wave.2.fill", index: 0)
            tabButton(title: "Микрофоны", icon: "mic.fill", index: 1)
            tabButton(title: "Чек-лист", icon: "checklist", index: 2)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .padding(.horizontal, 20)
    }
    
    private func tabButton(title: String, icon: String, index: Int) -> some View {
        let isSelected = selectedTab == index
        
        return Button {
            HapticFeedback.selection()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedTab = index
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
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
