import SwiftUI

// MARK: - Круговой индикатор прогресса и частоты очистки
public struct ProgressRingView: View {
    public let progress: Double // 0.0 ... 1.0
    public let remainingSeconds: Int
    public let currentFrequency: Float
    public let isRunning: Bool
    public let mode: CleaningMode
    
    @State private var pulseScale: CGFloat = 1.0
    
    public init(
        progress: Double,
        remainingSeconds: Int,
        currentFrequency: Float,
        isRunning: Bool,
        mode: CleaningMode
    ) {
        self.progress = progress
        self.remainingSeconds = remainingSeconds
        self.currentFrequency = currentFrequency
        self.isRunning = isRunning
        self.mode = mode
    }
    
    public var body: some View {
        ZStack {
            // Внешний пульсирующий ореол (во время работы)
            if isRunning {
                Circle()
                    .stroke(mode.primaryColor.opacity(0.2), lineWidth: 2)
                    .scaleEffect(pulseScale)
                    .opacity(2.0 - pulseScale)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: false),
                        value: pulseScale
                    )
                    .onAppear {
                        pulseScale = 1.35
                    }
                    .onDisappear {
                        pulseScale = 1.0
                    }
            }
            
            // Базовая серая дорожка
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 14)
            
            // Заполняющийся градиентный круг
            Circle()
                .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    mode.gradient,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.25), value: progress)
                .shadow(color: mode.primaryColor.opacity(0.5), radius: 10, x: 0, y: 0)
            
            // Центральный блок информации
            VStack(spacing: 8) {
                Image(systemName: mode.iconName)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(mode.primaryColor)
                    .symbolEffect(.bounce, value: isRunning)
                
                // Таймер
                Text("\(remainingSeconds) сек")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                    .contentTransition(.numericText())
                
                // Бейдж текущей частоты
                HStack(spacing: 6) {
                    Image(systemName: "waveform")
                        .font(.caption2)
                    Text(frequencyText)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(mode.primaryColor.opacity(0.15))
                        .overlay(
                            Capsule()
                                .stroke(mode.primaryColor.opacity(0.3), lineWidth: 1)
                        )
                )
                .foregroundColor(mode.primaryColor)
            }
        }
        .frame(width: 260, height: 260)
    }
    
    private var frequencyText: String {
        if currentFrequency >= 1000 {
            return String(format: "%.1f кГц", currentFrequency / 1000.0)
        } else {
            return "\(Int(currentFrequency)) Гц"
        }
    }
}
