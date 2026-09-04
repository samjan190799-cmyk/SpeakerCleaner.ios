import SwiftUI

// MARK: - Экран Энциклопедии ухода за смартфоном
public struct EncyclopediaView: View {
    @State private var selectedCategory: CareCategory? = nil
    @State private var searchText: String = ""
    
    public init() {}
    
    private var filteredArticles: [CareArticle] {
        CareArticlesData.articles.filter { article in
            let matchesCategory = selectedCategory == nil || article.category == selectedCategory
            let matchesSearch = searchText.isEmpty ||
                article.title.localizedCaseInsensitiveContains(searchText) ||
                article.subtitle.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Категории-чипсы
                        categoryPills
                        
                        // Список статей
                        VStack(spacing: 14) {
                            ForEach(filteredArticles) { article in
                                NavigationLink {
                                    ArticleDetailView(article: article)
                                } label: {
                                    articleCard(article)
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
            .searchable(text: $searchText, prompt: "Поиск советов по уходу...")
        }
    }
    
    // MARK: - Компоненты экрана
    
    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Кнопка «Все»
                Button {
                    HapticFeedback.selection()
                    withAnimation(.spring()) {
                        selectedCategory = nil
                    }
                } label: {
                    Text("Все темы")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedCategory == nil ? Theme.waterCyan.opacity(0.2) : Color.white.opacity(0.04))
                                .overlay(
                                    Capsule()
                                        .stroke(selectedCategory == nil ? Theme.waterCyan : Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .foregroundColor(selectedCategory == nil ? Theme.textPrimary : Theme.textTertiary)
                }
                
                ForEach(CareCategory.allCases) { category in
                    let isSelected = selectedCategory == category
                    Button {
                        HapticFeedback.selection()
                        withAnimation(.spring()) {
                            selectedCategory = category
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.iconName)
                                .font(.caption)
                            Text(category.rawValue)
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
        HStack(spacing: 16) {
            Circle()
                .fill(article.category.color.opacity(0.18))
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: article.category.iconName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(article.category.color)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(article.category.rawValue)
                        .font(.caption2)
                        .fontWeight(.semibold)
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
                
                Text(article.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Theme.textTertiary)
        }
        .padding(16)
        .liquidGlass(cornerRadius: 18)
    }
}
