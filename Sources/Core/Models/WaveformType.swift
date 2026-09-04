import Foundation

// MARK: - Форма звуковой волны для синтезатора
public enum WaveformType: String, CaseIterable, Identifiable, Sendable {
    case sine = "Синусоида"
    case square = "Меандр"
    case sawtooth = "Пилообразная"
    case triangle = "Треугольная"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .sine: return "waveform.path"
        case .square: return "square.split.diagonal.2x2"
        case .sawtooth: return "waveform.path.badge.plus"
        case .triangle: return "triangle"
        }
    }
    
    /// Математическая функция генерации амплитуды (-1.0 ... 1.0) по текущей фазе (0 ... 2*PI)
    @inline(__always)
    public func sample(at phase: Float) -> Float {
        switch self {
        case .sine:
            return sin(phase)
        case .square:
            return sin(phase) >= 0 ? 1.0 : -1.0
        case .sawtooth:
            // Фаза от 0 до 2*PI приводится к диапазону -1.0 ... 1.0
            let normalized = phase / (2.0 * Float.pi)
            return 2.0 * (normalized - floor(normalized + 0.5))
        case .triangle:
            // Треугольная волна
            let normalized = phase / (2.0 * Float.pi)
            return 2.0 * abs(2.0 * (normalized - floor(normalized + 0.5))) - 1.0
        }
    }
}
