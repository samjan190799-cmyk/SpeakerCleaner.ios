import Foundation
import SwiftUI

// MARK: - Результаты спектральной диагностики динамика
public struct DiagnosticResult: Identifiable, Sendable {
    public let id: UUID
    public let channel: SpeakerChannel
    public let cleanlinessScore: Int // 0 ... 100%
    public let frequencyResponse: [Float] // Амплитуды по частотным бинам
    public let bassClarity: Double // 0.0 ... 1.0 (Низкие частоты)
    public let midClarity: Double  // 0.0 ... 1.0 (Средние частоты)
    public let trebleClarity: Double // 0.0 ... 1.0 (Высокие частоты)
    public let timestamp: Date
    
    public init(
        id: UUID = UUID(),
        channel: SpeakerChannel,
        cleanlinessScore: Int,
        frequencyResponse: [Float],
        bassClarity: Double,
        midClarity: Double,
        trebleClarity: Double,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.channel = channel
        self.cleanlinessScore = cleanlinessScore
        self.frequencyResponse = frequencyResponse
        self.bassClarity = bassClarity
        self.midClarity = midClarity
        self.trebleClarity = trebleClarity
        self.timestamp = timestamp
    }
    
    public var statusTitle: String {
        switch cleanlinessScore {
        case 85...100:
            return "Идеальная чистота"
        case 65...84:
            return "Незначительное загрязнение"
        case 40...64:
            return "Требуется очистка"
        default:
            return "Критическое загрязнение"
        }
    }
    
    public var statusColor: Color {
        switch cleanlinessScore {
        case 85...100:
            return Theme.successGreen
        case 65...84:
            return Theme.waterCyan
        case 40...64:
            return Theme.warningYellow
        default:
            return Theme.dangerRed
        }
    }
    
    public var recommendation: String {
        switch cleanlinessScore {
        case 85...100:
            return "Акустический тракт чист. Мембрана и защитная сетка функционируют на 100% мощности."
        case 65...84:
            return "Обнаружено легкое демпфирование высоких частот. Рекомендуется запустить режим «Пыль»."
        case 40...64:
            return "Зафиксировано ослабление резонанса. Запустите 60-секундный цикл «Вода» или «Пыль»."
        default:
            return "Динамик сильно заблокирован жидкостью или грязью. Проведите цикл выталкивания воды и ознакомьтесь с гайдом механической очистки."
        }
    }
}
