import SwiftUI

// MARK: - Модель отдельной частицы брызг или микрочастиц пыли
struct DropletParticle: Identifiable {
    let id = UUID()
    var angle: Double // Угол вылета в радианах
    var distance: CGFloat // Расстояние от центра
    var size: CGFloat // Размер капли
    var opacity: Double // Прозрачность
    var scale: CGFloat // Масштаб
}

// MARK: - Высокопроизводительная физическая симуляция выталкивания капель воды и пыли
public struct WaterDropletsEmitterView: View {
    public let isActive: Bool
    public let mode: CleaningMode
    public let burstTrigger: Int
    
    @State private var particles: [DropletParticle] = []
    @State private var shockwaveRadius: CGFloat = 80
    @State private var shockwaveOpacity: Double = 0.0
    
    public init(isActive: Bool, mode: CleaningMode, burstTrigger: Int) {
        self.isActive = isActive
        self.mode = mode
        self.burstTrigger = burstTrigger
    }
    
    public var body: some View {
        ZStack {
            // Акустическая ударная волна (Shockwave Ring)
            if isActive {
                Circle()
                    .stroke(
                        mode.primaryColor.opacity(shockwaveOpacity),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: shockwaveRadius * 2, height: shockwaveRadius * 2)
                
                Circle()
                    .stroke(
                        mode.primaryColor.opacity(shockwaveOpacity * 0.5),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
                    .frame(width: shockwaveRadius * 2.3, height: shockwaveRadius * 2.3)
            }
            
            // Радиальный рой капель воды / частиц
            ForEach(particles) { particle in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                mode.primaryColor,
                                mode.primaryColor.opacity(0.3)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: particle.size
                        )
                    )
                    .frame(width: particle.size, height: particle.size)
                    .scaleEffect(particle.scale)
                    .opacity(particle.opacity)
                    .offset(
                        x: cos(particle.angle) * particle.distance,
                        y: sin(particle.angle) * particle.distance
                    )
                    .blur(radius: particle.distance > 130 ? 0.8 : 0.0)
            }
        }
        .frame(width: 320, height: 320)
        .allowsHitTesting(false)
        .onChange(of: burstTrigger) { _, _ in
            if isActive {
                triggerEjectionBurst()
            }
        }
        .onChange(of: isActive) { _, active in
            if !active {
                withAnimation(.easeOut(duration: 0.3)) {
                    particles.removeAll()
                    shockwaveOpacity = 0.0
                }
            }
        }
    }
    
    private func triggerEjectionBurst() {
        // Запуск расширения акустической волны
        shockwaveRadius = 90
        shockwaveOpacity = 0.85
        withAnimation(.easeOut(duration: 0.65)) {
            shockwaveRadius = 165
            shockwaveOpacity = 0.0
        }
        
        // Генерация пучка капель (14–20 капель за один звуковой импульс)
        let count = Int.random(in: 14...20)
        var newParticles: [DropletParticle] = []
        
        for _ in 0..<count {
            let angle = Double.random(in: 0...(2 * .pi))
            let particle = DropletParticle(
                angle: angle,
                distance: CGFloat.random(in: 90...110),
                size: CGFloat.random(in: 4...10),
                opacity: Double.random(in: 0.8...1.0),
                scale: 1.0
            )
            newParticles.append(particle)
        }
        
        self.particles = newParticles
        
        // Физический разлет с затуханием (Water Ejection Splash)
        withAnimation(.easeOut(duration: 0.55)) {
            for i in 0..<self.particles.count {
                self.particles[i].distance += CGFloat.random(in: 35...65)
                self.particles[i].opacity = 0.0
                self.particles[i].scale = CGFloat.random(in: 0.4...0.7)
            }
        }
    }
}
