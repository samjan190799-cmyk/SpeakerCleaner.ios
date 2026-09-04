import Foundation
import SwiftUI

// MARK: - ViewModel для Pro-генератора частот (Swift 6 Strict Concurrency, @Observable)
@Observable
@MainActor
public final class ProGeneratorViewModel {
    public var frequency: Float = 165.0 {
        didSet {
            if isPlaying {
                AudioEngineService.shared.updateFrequency(frequency)
            }
        }
    }
    
    public var waveform: WaveformType = .sine {
        didSet {
            if isPlaying {
                AudioEngineService.shared.updateWaveform(waveform)
            }
        }
    }
    
    public var volume: Float = 1.0 {
        didSet {
            if isPlaying {
                AudioEngineService.shared.updateVolume(volume)
            }
        }
    }
    
    public var isPulsing: Bool = false {
        didSet {
            if isPlaying {
                restartTone()
            }
        }
    }
    
    public var pulseInterval: Double = 0.2 // секунд
    public private(set) var isPlaying: Bool = false
    
    public init() {}
    
    public func togglePlayback() {
        if isPlaying {
            stop()
        } else {
            play()
        }
    }
    
    public func play() {
        isPlaying = true
        AudioEngineService.shared.startTone(
            frequency: frequency,
            waveform: waveform,
            volume: volume,
            isPulsing: isPulsing,
            pulseOn: pulseInterval,
            pulseOff: pulseInterval * 0.5
        )
        HapticFeedback.notification(.success)
    }
    
    public func stop() {
        isPlaying = false
        AudioEngineService.shared.stop()
        HapticFeedback.impact(.light)
    }
    
    private func restartTone() {
        AudioEngineService.shared.stop()
        AudioEngineService.shared.startTone(
            frequency: frequency,
            waveform: waveform,
            volume: volume,
            isPulsing: isPulsing,
            pulseOn: pulseInterval,
            pulseOff: pulseInterval * 0.5
        )
    }
    
    // MARK: - Быстрые пресеты
    public struct Preset: Identifiable {
        public let id = UUID()
        public let title: String
        public let freq: Float
        public let wave: WaveformType
        public let description: String
    }
    
    public let presets: [Preset] = [
        Preset(title: "Выталкивание воды", freq: 165.0, wave: .sine, description: "Резонанс диффузора для капель"),
        Preset(title: "Глубокий суббас", freq: 60.0, wave: .sine, description: "Максимальная амплитуда мембраны"),
        Preset(title: "Встряхивание пыли", freq: 3200.0, wave: .sawtooth, description: "Гармоники высокой энергии"),
        Preset(title: "Очистка ресивера", freq: 1200.0, wave: .square, description: "Тест разговорного динамика"),
        Preset(title: "Ультразвуковой порог", freq: 16500.0, wave: .triangle, description: "Микроколебания акустической сетки")
    ]
    
    public func applyPreset(_ preset: Preset) {
        self.frequency = preset.freq
        self.waveform = preset.wave
        HapticFeedback.selection()
    }
    
    public func stepFrequency(by delta: Float) {
        let newFreq = min(max(frequency + delta, 20.0), 20000.0)
        self.frequency = newFreq
        HapticFeedback.impact(.light)
    }
}
