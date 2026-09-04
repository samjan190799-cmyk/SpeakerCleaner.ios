import SwiftUI

// MARK: - Экран детальной статьи энциклопедии ухода за смартфоном
public struct ArticleDetailView: View {
    public let article: CareArticle
    
    public init(article: CareArticle) {
        self.article = article
    }
    
    public var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Заголовок и метаданные
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text(article.category.rawValue)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(article.category.color)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(article.category.color.opacity(0.15)))
                            
                            Text("• \(article.readTimeMinutes) мин чтения")
                                .font(.caption)
                                .foregroundColor(Theme.textTertiary)
                        }
                        
                        Text(article.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        
                        Text(article.subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textSecondary)
                            .lineSpacing(3)
                    }
                    .padding(.top, 10)
                    
                    // Блок «Что категорически запрещено» (Красный)
                    if !article.prohibitedActions.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "exclamationmark.octagon.fill")
                                    .foregroundColor(Theme.dangerRed)
                                Text("Категорически запрещено")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Theme.dangerRed)
                            }
                            
                            ForEach(article.prohibitedActions, id: \.self) { rule in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("⛔")
                                        .font(.caption)
                                    Text(rule)
                                        .font(.system(size: 13))
                                        .foregroundColor(Theme.textPrimary)
                                }
                            }
                        }
                        .padding(16)
                        .liquidGlass(cornerRadius: 18, strokeColor: Theme.dangerRed.opacity(0.4))
                    }
                    
                    // Блок «Главные правила ухода» (Зеленый)
                    if !article.keyRules.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundColor(Theme.successGreen)
                                Text("Золотые правила ухода")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Theme.successGreen)
                            }
                            
                            ForEach(article.keyRules, id: \.self) { rule in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("✓")
                                        .foregroundColor(Theme.successGreen)
                                        .fontWeight(.bold)
                                    Text(rule)
                                        .font(.system(size: 13))
                                        .foregroundColor(Theme.textPrimary)
                                }
                            }
                        }
                        .padding(16)
                        .liquidGlass(cornerRadius: 18, strokeColor: Theme.successGreen.opacity(0.4))
                    }
                    
                    // Разделы статьи
                    ForEach(article.detailedGuide) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.heading)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(Theme.textPrimary)
                            
                            Text(section.content)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.textSecondary)
                                .lineSpacing(4)
                            
                            if let tip = section.proTip {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(article.category.color)
                                        .font(.caption)
                                    Text(tip)
                                        .font(.system(size: 12))
                                        .foregroundColor(article.category.color)
                                }
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(article.category.color.opacity(0.1))
                                )
                                .padding(.top, 4)
                            }
                        }
                        .padding(16)
                        .liquidGlass(cornerRadius: 18)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
