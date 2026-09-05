import Foundation

// MARK: - Акустические каналы динамиков
public enum SpeakerChannel: String, CaseIterable, Identifiable, Sendable, Codable {
    case main = "Основной динамик"
    case earpiece = "Разговорный динамик"
    case both = "Оба динамика"
    
    public var id: String { rawValue }
    
    public var shortTitle: String {
        switch self {
        case .main: return "Нижний"
        case .earpiece: return "Верхний"
        case .both: return "Все"
        }
    }
    
    public var iconName: String {
        switch self {
        case .main: return "speaker.wave.3.fill"
        case .earpiece: return "phone.badge.waveform.fill"
        case .both: return "hifispeaker.2.fill"
        }
    }
    
    public var description: String {
        switch self {
        case .main:
            return "Основной мультимедийный динамик на нижнем торце устройства."
        case .earpiece:
            return "Фронтальный разговорный динамик над экраном (ресивер)."
        case .both:
            return "Одновременная очистка всей акустической системы устройства."
        }
    }
}
