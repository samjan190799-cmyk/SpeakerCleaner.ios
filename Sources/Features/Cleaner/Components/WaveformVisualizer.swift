import SwiftUI

// MARK: - Динамический визуализатор звуковых волн и резонансных импульсов на Canvas
public struct WaveformVisualizer: View {
    public let isActive: Bool
    public let color: Color
    public let frequency: Float
    public let isPulsing: Bool
    
    @State private var phase: CGFloat = 0.0
    
    public init(
        isActive: Bool,
        color: Color = Theme.waterCyan,
        frequency: Float = 165.0,
        isPulsing: Bool = false
    ) {
        self.isActive = isActive
        self.color = color
        self.frequency = frequency
        self.isPulsing = isPulsing
    }
    
    public var body: some View {
        TimelineView(.animation(paused: !isActive)) { timeline in
            Canvas { context, size in
                let midY = size.height / 2
                let width = size.width
                
                // Расчет скорости анимации на основе частоты
                let time = timeline.date.timeIntervalSinceReferenceDate
                let speedMultiplier = Double(min(max(frequency / 100.0, 1.0), 10.0))
                let animPhase = time * speedMultiplier
                
                // Рендерим 3 наложенные синусоидальные волны с разным сдвигом фазы
                for i in 0..<3 {
                    var path = Path()
                    let waveOffset = Double(i) * 0.45
                    let alpha = 1.0 - (Double(i) * 0.25)
                    let amplitude = (size.height * 0.35) * (1.0 - CGFloat(i) * 0.2)
                    
                    path.move(to: CGPoint(x: 0, y: midY))
                    
                    let step: CGFloat = 3.0
                    for x in stride(from: 0, through: width, by: step) {
                        let relativeX = x / width
                        // Огибающая для затухания к краям экрана (Hanning-подобная)
                        let envelope = sin(relativeX * .pi)
                        let wavelength = width / 2.5
                        let y = midY + sin((x / wavelength) * 2 * .pi + animPhase + waveOffset) * amplitude * envelope
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    
                    context.stroke(
                        path,
                        with: .color(color.opacity(alpha)),
                        lineWidth: i == 0 ? 3.0 : 1.5
                    )
                }
            }
        }
        .frame(height: 100)
    }
}
