import SwiftUI

// MARK: - Экран Энциклопедии ухода за смартфоном
public struct EncyclopediaView: View {
    @AppStorage("care_bookmarked_articles") private var bookmarkedIdsData: String = ""
    @State private var selectedCategory: CareCategory? = nil
    @State private var showBookmarksOnly: Bool = false
    @State private var searchText: String = ""
    
    public init() {}
    
    private var bookmarkedIds: Set<String> {
        Set(bookmarkedIdsData.split(separator: ",").map { String($0) })
    }
    
    private func isBookmarked(_ article: CareArticle) -> Bool {
        bookmarkedIds.contains(article.id)
    }
    
    private func toggleBookmark(for article: CareArticle) {
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
    
    private var filteredArticles: [CareArticle] {
        CareArticlesData.articles.filter { article in
            if showBookmarksOnly && !isBookmarked(article) {
                return false
            }
            if let category = selectedCategory, article.category != category {
                return false
            }
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return true
            }
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let inTitle = article.title.localizedCaseInsensitiveContains(query)
            let inSubtitle = article.subtitle.localizedCaseInsensitiveContains(query)
            let inRules = article.keyRules.contains { $0.localizedCaseInsensitiveContains(query) }
            let inProhibited = article.prohibitedActions.contains { $0.localizedCaseInsensitiveContains(query) }
            let inGuide = article.detailedGuide.contains {
                $0.heading.localizedCaseInsensitiveContains(query) ||
                $0.content.localizedCaseInsensitiveContains(query) ||
                ($0.proTip?.localizedCaseInsensitiveContains(query) ?? false)
            }
            return inTitle || inSubtitle || inRules || inProhibited || inGuide
        }
    }
    
    private func countForCategory(_ category: CareCategory) -> Int {
        CareArticlesData.articles.filter { $0.category == category }.count
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Категории-чипсы и переключатель закладок
                        categoryPills
                        
                        // Список статей
                        if filteredArticles.isEmpty {
                            emptyStateView
                        } else {
                            LazyVStack(spacing: 14) {
                                ForEach(filteredArticles) { article in
                                    NavigationLink {
                                        ArticleDetailView(article: article)
                                    } label: {
                                        articleCard(article)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Энциклопедия")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Поиск советов, правил и частых проблем...")
        }
    }
    
    // MARK: - Компоненты экрана
    
    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // 1. Кнопка «Все темы»
                Button {
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedCategory = nil
                        showBookmarksOnly = false
                    }
                } label: {
                    Text("Все (\(CareArticlesData.articles.count))")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill((selectedCategory == nil && !showBookmarksOnly) ? Theme.waterCyan.opacity(0.2) : Color.white.opacity(0.04))
                                .overlay(
                                    Capsule()
                                        .stroke((selectedCategory == nil && !showBookmarksOnly) ? Theme.waterCyan : Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .foregroundColor((selectedCategory == nil && !showBookmarksOnly) ? Theme.textPrimary : Theme.textTertiary)
                }
                
                // 2. Кнопка «Закладки»
                Button {
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        showBookmarksOnly.toggle()
                        if showBookmarksOnly {
                            selectedCategory = nil
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showBookmarksOnly ? "bookmark.fill" : "bookmark")
                            .font(.caption)
                        Text("Закладки (\(bookmarkedIds.count))")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(showBookmarksOnly ? Theme.dustGold.opacity(0.2) : Color.white.opacity(0.04))
                            .overlay(
                                Capsule()
                                    .stroke(showBookmarksOnly ? Theme.dustGold : Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .foregroundColor(showBookmarksOnly ? Theme.dustGold : Theme.textTertiary)
                }
                
                // 3. Плашки категорий
                ForEach(CareCategory.allCases) { category in
                    let isSelected = (selectedCategory == category && !showBookmarksOnly)
                    let count = countForCategory(category)
                    
                    Button {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            showBookmarksOnly = false
                            selectedCategory = category
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.iconName)
                                .font(.caption)
                            Text("\(category.rawValue) (\(count))")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isSelected ? category.color.opacity(0.2) : Color.white.opacity(0.04))
                                .overlay(
                                    Capsule()
                                        .stroke(isSelected ? category.color : Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .foregroundColor(isSelected ? Theme.textPrimary : Theme.textTertiary)
                    }
                }
            }
        }
    }
    
    private func articleCard(_ article: CareArticle) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(article.category.color.opacity(0.18))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: article.category.iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(article.category.color)
                )
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(article.category.rawValue)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(article.category.color)
                        .textCase(.uppercase)
                    
                    Spacer()
                    
                    Text("\(article.readTimeMinutes) мин")
                        .font(.caption2)
                        .foregroundColor(Theme.textTertiary)
                }
                
                Text(article.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Text(article.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.successGreen)
                        Text("\(article.keyRules.count) правил")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textTertiary)
                    }
                    
                    if !article.prohibitedActions.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.dangerRed)
                            Text("\(article.prohibitedActions.count) табу")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textTertiary)
                        }
                    }
                }
                .padding(.top, 2)
            }
            
            VStack(spacing: 16) {
                Button {
                    toggleBookmark(for: article)
                } label: {
                    Image(systemName: isBookmarked(article) ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isBookmarked(article) ? Theme.dustGold : Theme.textTertiary.opacity(0.7))
                        .padding(6)
                }
                .buttonStyle(.plain)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 18)
    }
    
    // MARK: - Состояние пустого списка
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: showBookmarksOnly ? "bookmark.slash" : "magnifyingglass")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(Theme.textTertiary)
                .padding(.top, 40)
            
            Text(showBookmarksOnly ? "В закладках пока пусто" : "Ничего не найдено")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            
            Text(showBookmarksOnly
                 ? "Нажимайте на значок закладки в правом углу любой карточки, чтобы сохранить инструкцию."
                 : "Попробуйте изменить поисковый запрос или выберите другую категорию ухода.")
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            if !searchText.isEmpty || selectedCategory != nil || showBookmarksOnly {
                Button {
                    HapticFeedback.selection()
                    withAnimation {
                        searchText = ""
                        selectedCategory = nil
                        showBookmarksOnly = false
                    }
                } label: {
                    Text("Сбросить все фильтры")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.waterCyan)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Theme.waterCyan.opacity(0.12)))
                }
                .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
