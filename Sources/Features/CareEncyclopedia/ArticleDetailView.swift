import SwiftUI

// MARK: - Экран детальной статьи энциклопедии ухода за смартфоном
public struct ArticleDetailView: View {
    @AppStorage("care_bookmarked_articles") private var bookmarkedIdsData: String = ""
    public let article: CareArticle
    
    public init(article: CareArticle) {
        self.article = article
    }
    
    private var bookmarkedIds: Set<String> {
        Set(bookmarkedIdsData.split(separator: ",").map { String($0) })
    }
    
    private var isBookmarked: Bool {
        bookmarkedIds.contains(article.id)
    }
    
    private func toggleBookmark() {
        var current = bookmarkedIds
        if current.contains(article.id) {
            current.remove(article.id)
            HapticFeedback.selection()
        } else {
            current.insert(article.id)
            HapticFeedback.notification(.success)
        }
        bookmarkedIdsData = current.joined(separator: ",")
    }
    
    private var shareText: String {
        """
        📱 PhoneCare Совет: \(article.title)
        
        \(article.subtitle)
        
        ✨ Золотые правила ухода:
        \(article.keyRules.map { "• \($0)" }.joined(separator: "\n"))
        
        ⚠️ Запрещено:
        \(article.prohibitedActions.map { "⛔ \($0)" }.joined(separator: "\n"))
        """
    }
    
    public var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Заголовок и метаданные
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Text(article.category.rawValue)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(article.category.color)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(article.category.color.opacity(0.15)))
                            
                            Text("• \(article.readTimeMinutes) мин чтения")
                                .font(.caption)
                                .foregroundColor(Theme.textTertiary)
                            
                            Spacer()
                            
                            if isBookmarked {
                                HStack(spacing: 4) {
                                    Image(systemName: "bookmark.fill")
                                        .font(.caption2)
                                    Text("В закладках")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(Theme.dustGold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Theme.dustGold.opacity(0.12)))
                            }
                        }
                        
                        Text(article.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                            .lineSpacing(2)
                        
                        Text(article.subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(Theme.textSecondary)
                            .lineSpacing(4)
                    }
                    .padding(.top, 10)
                    
                    // Блок «Что категорически запрещено» (Красный)
                    if !article.prohibitedActions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.octagon.fill")
                                    .foregroundColor(Theme.dangerRed)
                                    .font(.system(size: 16))
                                Text("Категорически запрещено")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Theme.dangerRed)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(article.prohibitedActions, id: \.self) { rule in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("⛔")
                                            .font(.caption)
                                            .padding(.top, 1)
                                        Text(rule)
                                            .font(.system(size: 13))
                                            .foregroundColor(Theme.textPrimary)
                                            .lineSpacing(3)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .liquidGlass(cornerRadius: 18, strokeColor: Theme.dangerRed.opacity(0.4))
                    }
                    
                    // Блок «Главные правила ухода» (Зеленый)
                    if !article.keyRules.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundColor(Theme.successGreen)
                                    .font(.system(size: 16))
                                Text("Золотые правила ухода")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Theme.successGreen)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(article.keyRules, id: \.self) { rule in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(Theme.successGreen)
                                            .padding(.top, 3)
                                        Text(rule)
                                            .font(.system(size: 13))
                                            .foregroundColor(Theme.textPrimary)
                                            .lineSpacing(3)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .liquidGlass(cornerRadius: 18, strokeColor: Theme.successGreen.opacity(0.4))
                    }
                    
                    // Разделы руководства со счётчиком шагов
                    ForEach(Array(article.detailedGuide.enumerated()), id: \.element.id) { index, section in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Text("Шаг \(index + 1)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(article.category.color)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(article.category.color.opacity(0.15)))
                                
                                Text(section.heading)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Theme.textPrimary)
                            }
                            
                            Text(section.content)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.textSecondary)
                                .lineSpacing(4)
                            
                            if let tip = section.proTip {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(Theme.dustGold)
                                        .font(.caption)
                                        .padding(.top, 2)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Совет эксперта")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(Theme.dustGold)
                                            .textCase(.uppercase)
                                        Text(tip)
                                            .font(.system(size: 12))
                                            .foregroundColor(Theme.textPrimary.opacity(0.9))
                                            .lineSpacing(2)
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Theme.dustGold.opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(Theme.dustGold.opacity(0.2), lineWidth: 1)
                                        )
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
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                }
                
                Button {
                    toggleBookmark()
                } label: {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isBookmarked ? Theme.dustGold : Theme.textPrimary)
                }
            }
        }
    }
}
