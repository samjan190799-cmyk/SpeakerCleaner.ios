import SwiftUI

// MARK: - Главная точка входа в приложение PhoneCare Hub (iOS 17+, Swift 6.0)
@main
struct SpeakerCleanerApp: App {
    init() {
        // Инициализация сервисов при запуске
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

// MARK: - Основная навигация приложения PhoneCare Hub (Apple HIG 2026)
struct MainTabView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Вкладка 1: Хаб инструментов (Очистка динамиков, Pro-генератор, Экранный замок, Тест матрицы)
            ToolsHubView()
                .tabItem {
                    Label("Инструменты", systemImage: "wrench.and.screwdriver.fill")
                }
                .tag(0)
            
            // Вкладка 2: Интерактивная энциклопедия ухода за компонентами
            EncyclopediaView()
                .tabItem {
                    Label("Энциклопедия", systemImage: "book.closed.fill")
                }
                .tag(1)
            
            // Вкладка 3: Экстренный визард первой помощи при инцидентах
            EmergencyWizardView()
                .tabItem {
                    Label("Экстренно", systemImage: "cross.case.fill")
                }
                .tag(2)
            
            // Вкладка 4: Спектральная диагностика и трекер заботы
            DiagnosticsHubView()
                .tabItem {
                    Label("Диагностика", systemImage: "waveform.badge.mic")
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
        appearance.backgroundColor = UIColor(Color(hex: "080A0F")).withAlphaComponent(0.92)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
