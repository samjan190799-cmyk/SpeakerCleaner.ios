import Foundation
import CoreHaptics
import UIKit

// MARK: - Менеджер тактильной отдачи Haptic Boost на CoreHaptics
@MainActor
public final class HapticBoostManager {
    public static let shared = HapticBoostManager()
    
    private var engine: CHHapticEngine?
    private var continuousPlayer: CHHapticAdvancedPatternPlayer?
    public private(set) var supportsHaptics: Bool = false
    public var isHapticBoostEnabled: Bool = true
    
    private init() {
        setupHaptics()
    }
    
    private func setupHaptics() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        guard supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            engine?.resetHandler = { [weak self] in
                Task { @MainActor in
                    do {
                        try self?.engine?.start()
                    } catch {
                        print("❌ Ошибка перезапуска CoreHaptics: \(error)")
                    }
                }
            }
            engine?.stoppedHandler = { reason in
                print("⚠️ CoreHaptics остановлен по причине: \(reason)")
            }
            try engine?.start()
        } catch {
            print("❌ Ошибка инициализации CHHapticEngine: \(error.localizedDescription)")
        }
    }
    
    /// Тактильный удар для выдувания капель воды (Water Eject Burst)
    public func triggerWaterBurst() {
        guard isHapticBoostEnabled else { return }
        
        if supportsHaptics, let engine {
            do {
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.85)
                
                // Мощный удар в начале выброса капли
                let impact = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: 0
                )
                
                // Низкочастотный рокот вслед за ударом (имитация движения воздуха)
                let rumble = CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ],
                    relativeTime: 0.05,
                    duration: 0.3
                )
                
                let pattern = try CHHapticPattern(events: [impact, rumble], parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: CHHapticTimeImmediate)
            } catch {
                fallbackImpact()
            }
        } else {
            fallbackImpact()
        }
    }
    
    /// Микровибрации для встряхивания пыли (Dust Shaker Micro-vibrations)
    public func triggerDustMicroVibration() {
        guard isHapticBoostEnabled else { return }
        
        if supportsHaptics, let engine {
            do {
                var events: [CHHapticEvent] = []
                // Серия из 4 микро-щелчков высокой резкости
                for i in 0..<4 {
                    let event = CHHapticEvent(
                        eventType: .hapticTransient,
                        parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                        ],
                        relativeTime: Double(i) * 0.08
                    )
                    events.append(event)
                }
                let pattern = try CHHapticPattern(events: events, parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: CHHapticTimeImmediate)
            } catch {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
        } else {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
    }
    
    /// Непрерывная сильная вибрация для усиленного режима: зацикленный паттерн 1 с,
    /// полная интенсивность и четыре резких удара в секунду (вместо коротких всплесков по тактам импульсов)
    public func startContinuousVibration() {
        guard isHapticBoostEnabled, supportsHaptics, let engine, continuousPlayer == nil else { return }

        do {
            // Движок мог остановиться (фон, прерывание сессии): повторный start() безопасен
            try engine.start()

            var events: [CHHapticEvent] = [
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: 0,
                    duration: 1.0
                )
            ]
            for i in 0..<4 {
                events.append(
                    CHHapticEvent(
                        eventType: .hapticTransient,
                        parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                        ],
                        relativeTime: Double(i) * 0.25
                    )
                )
            }

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makeAdvancedPlayer(with: pattern)
            player.loopEnabled = true
            try player.start(atTime: CHHapticTimeImmediate)
            continuousPlayer = player
        } catch {
            print("❌ Ошибка непрерывной вибрации: \(error.localizedDescription)")
            fallbackImpact()
        }
    }

    public func stopContinuousVibration() {
        guard let player = continuousPlayer else { return }
        continuousPlayer = nil
        try? player.stop(atTime: CHHapticTimeImmediate)
    }

    private func fallbackImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred(intensity: 1.0)
    }
}
