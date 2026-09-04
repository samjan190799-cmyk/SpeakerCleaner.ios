import SwiftUI

// MARK: - Цветовая палитра и темы оформления (Apple HIG 2026)
public enum Theme {
    // Основные цвета фона
    public static let background = Color(hex: "07090E")
    public static let secondaryBackground = Color(hex: "0E121A")
    public static let cardBackground = Color(hex: "141923").opacity(0.7)
    public static let cardBorder = Color.white.opacity(0.12)
    
    // Акцентные цвета режимов
    public static let waterCyan = Color(hex: "00F5D4")
    public static let waterBlue = Color(hex: "00B4D8")
    
    public static let dustGold = Color(hex: "FFB703")
    public static let dustOrange = Color(hex: "FB8500")
    
    public static let proPurple = Color(hex: "9D4EDD")
    public static let proPink = Color(hex: "F72585")
    
    public static let successGreen = Color(hex: "06D6A0")
    public static let warningYellow = Color(hex: "FFD166")
    public static let dangerRed = Color(hex: "EF476F")
    
    // Градиенты режимов
    public static let waterGradient = LinearGradient.waterGradient
    public static let dustGradient = LinearGradient.dustGradient
    public static let proGradient = LinearGradient.proGradient
    
    // Текстовые цвета
    public static let textPrimary = Color.white
    public static let textSecondary = Color.white.opacity(0.7)
    public static let textTertiary = Color.white.opacity(0.4)
}

// MARK: - Градиенты
public extension LinearGradient {
    static let waterGradient = LinearGradient(
        colors: [Theme.waterCyan, Theme.waterBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let dustGradient = LinearGradient(
        colors: [Theme.dustGold, Theme.dustOrange],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let proGradient = LinearGradient(
        colors: [Theme.proPurple, Theme.proPink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGlassGradient = LinearGradient(
        colors: [Color.white.opacity(0.08), Color.white.opacity(0.02)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Расширение Color для Hex
public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Стиль Liquid Glassmorphism
public struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat
    var strokeColor: Color
    
    public init(cornerRadius: CGFloat = 20, strokeColor: Color = Theme.cardBorder) {
        self.cornerRadius = cornerRadius
        self.strokeColor = strokeColor
    }
    
    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(strokeColor, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.35), radius: 16, x: 0, y: 8)
            )
    }
}

public extension View {
    func liquidGlass(cornerRadius: CGFloat = 20, strokeColor: Color = Theme.cardBorder) -> some View {
        self.modifier(LiquidGlassModifier(cornerRadius: cornerRadius, strokeColor: strokeColor))
    }
}
