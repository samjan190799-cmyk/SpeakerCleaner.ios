import SwiftUI

// MARK: - Элемент чек-листа регулярного ухода за устройством
public struct CareChecklistItem: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let category: String
    public let recommendedIntervalDays: Int
    public let iconName: String
    public let iconColor: Color
    public var isCompleted: Bool
    public var lastCompletedDate: Date?
    
    public init(
        id: String,
        title: String,
        category: String,
        recommendedIntervalDays: Int,
        iconName: String,
        iconColor: Color,
        isCompleted: Bool = false,
        lastCompletedDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.recommendedIntervalDays = recommendedIntervalDays
        self.iconName = iconName
        self.iconColor = iconColor
        self.isCompleted = isCompleted
        self.lastCompletedDate = lastCompletedDate
    }
}

// MARK: - Предустановленный список процедур гигиены смартфона
public enum CareChecklistData {
    public static let initialItems: [CareChecklistItem] = [
        CareChecklistItem(
            id: "speaker-blast",
            title: "Звуковая продувка динамиков (Water/Dust)",
            category: "Акустика",
            recommendedIntervalDays: 14,
            iconName: "speaker.wave.3.fill",
            iconColor: Theme.waterCyan
        ),
        CareChecklistItem(
            id: "case-abrasive",
            title: "Очистка чехла от абразивной пыли",
            category: "Корпус",
            recommendedIntervalDays: 14,
            iconName: "shield.lefthalf.filled",
            iconColor: Theme.dustGold
        ),
        CareChecklistItem(
            id: "screen-microfiber",
            title: "Протирка экрана сухой микрофиброй",
            category: "Экран",
            recommendedIntervalDays: 7,
            iconName: "iphone",
            iconColor: Theme.waterBlue
        ),
        CareChecklistItem(
            id: "port-inspection",
            title: "Осмотр разъема зарядки на ворсинки",
            category: "Разъемы",
            recommendedIntervalDays: 30,
            iconName: "cable.connector",
            iconColor: Color(hex: "06D6A0")
        ),
        CareChecklistItem(
            id: "lens-clean",
            title: "Очистка линз фотомодулей камеры",
            category: "Оптика",
            recommendedIntervalDays: 7,
            iconName: "camera.fill",
            iconColor: Theme.proPurple
        )
    ]
}
