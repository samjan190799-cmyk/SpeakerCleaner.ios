import SwiftUI

// MARK: - Главная точка входа в приложение Speaker Cleaner (iOS 17+, Swift 6.0)
@main
struct SpeakerCleanerApp: App {
    init() {
        // Первичная инициализация аудио-сессии при запуске
        _ = AudioSessionManager.shared
        _ = HapticBoostManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Основная навигация приложения (Apple HIG)
struct MainTabView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CleanerView()
                .tabItem {
                    Label("Очистка", systemImage: "speaker.wave.3.fill")
                }
                .tag(0)
            
            ProGeneratorView()
                .tabItem {
                    Label("Pro", systemImage: "slider.horizontal.3")
                }
                .tag(1)
            
            DiagnosticsView()
                .tabItem {
                    Label("Диагностика", systemImage: "waveform.badge.mic")
                }
                .tag(2)
            
            KnowledgeBaseView()
                .tabItem {
                    Label("Гайды", systemImage: "book.fill")
                }
                .tag(3)
        }
        .tint(Theme.waterCyan)
        .onAppear {
            configureTabBarAppearance()
        }
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(Color(hex: "0B0E14")).withAlphaComponent(0.85)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
