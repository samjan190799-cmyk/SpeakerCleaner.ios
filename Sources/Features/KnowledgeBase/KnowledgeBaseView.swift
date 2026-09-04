import SwiftUI

// MARK: - Экран базы знаний и инструкций по уходу за динамиками
public struct KnowledgeBaseView: View {
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Верхний баннер безопасности
                        safetyQuickBanner
                        
                        // Список интерактивных карточек-гайдов
                        VStack(spacing: 16) {
                            ForEach(KnowledgeBaseData.guides) { guide in
                                NavigationLink {
                                    GuideDetailView(guide: guide)
                                } label: {
                                    guideCard(guide)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("База знаний")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Компоненты экрана
    
    private var safetyQuickBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.title)
                .foregroundColor(Theme.dangerRed)
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Главное правило безопасности")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Text("Никогда не используйте иглы, зубочистки и 70% спирт. Это необратимо повреждает водозащитную мембрану.")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 18, strokeColor: Theme.dangerRed.opacity(0.35))
    }
    
    private func guideCard(_ guide: CleaningGuide) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(guide.accentColor.opacity(0.16))
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: guide.iconName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(guide.accentColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(guide.category.rawValue)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(guide.accentColor)
                    .textCase(.uppercase)
                
                Text(guide.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.leading)
                
                Text(guide.summary)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textTertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Theme.textTertiary)
        }
        .padding(16)
        .liquidGlass(cornerRadius: 18)
    }
}
