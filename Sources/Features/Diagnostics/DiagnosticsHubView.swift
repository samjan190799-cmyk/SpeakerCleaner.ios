import SwiftUI

// MARK: - Объединенный экран диагностики и трекера ухода за гаджетом
public struct DiagnosticsHubView: View {
    @State private var selectedTab: Int = 0
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Переключатель между акустической диагностикой и трекером заботы
                        HStack(spacing: 8) {
                            tabButton(title: "Акустический тест", icon: "waveform.badge.mic", index: 0)
                            tabButton(title: "Индекс ухода", icon: "checklist", index: 1)
                        }
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.05))
                        )
                        .padding(.horizontal, 20)
                        
                        if selectedTab == 0 {
                            DiagnosticsView()
                        } else {
                            CareChecklistView()
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Диагностика и здоровье")
            .navigationBarTitleDisplayMode(.inline)
        }
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
                    .font(.system(size: 13, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Theme.dustGold.opacity(0.2) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isSelected ? Theme.dustGold.opacity(0.8) : Color.clear, lineWidth: 1)
                    )
            )
            .foregroundColor(isSelected ? Theme.textPrimary : Theme.textTertiary)
        }
    }
}
