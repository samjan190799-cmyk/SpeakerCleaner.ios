import Foundation
import SwiftUI

// MARK: - ViewModel главного экрана очистки (Swift 6 Strict Concurrency, @Observable)
@Observable
@MainActor
public final class CleanerViewModel {
    private static let boostStorageKey = "speaker_cleaner_boost_mode_v1"

    public var selectedMode: CleaningMode = .water {
        didSet {
            if !isRunning {
                resetDuration()
            }
        }
    }
    
    public var selectedChannel: SpeakerChannel = .main {
        didSet {
            AudioSessionManager.shared.setChannel(selectedChannel)
        }
    }
    
    public private(set) var isRunning: Bool = false
    public private(set) var isPaused: Bool = false
    public var isFinished: Bool = false
    public private(set) var progress: Double = 0.0
    public private(set) var remainingSeconds: Int = 60
    public private(set) var currentFrequency: Float = 165.0
    public var isHapticBoostEnabled: Bool = true {
        didSet {
            HapticBoostManager.shared.isHapticBoostEnabled = isHapticBoostEnabled
            syncContinuousVibration()
        }
    }

    /// Усиленный режим: меандр без пауз, сессия .playback и непрерывная вибрация (для сравнения на устройстве)
    public var isBoostEnabled: Bool = UserDefaults.standard.bool(forKey: CleanerViewModel.boostStorageKey) {
        didSet {
            UserDefaults.standard.set(isBoostEnabled, forKey: Self.boostStorageKey)
        }
    }

    public private(set) var burstTriggerCounter: Int = 0
    public var showVolumeWarning: Bool = false
    
    private var timerTask: Task<Void, Never>?
    private var elapsedSeconds: Double = 0.0
    private var totalDuration: Double = 60.0
    
    public init() {
        resetDuration()
        setupPulseCallback()
    }
    
    private func setupPulseCallback() {
        AudioEngineService.shared.onPulseBurstTriggered = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, self.isRunning else { return }
                self.burstTriggerCounter += 1
                if self.isHapticBoostEnabled {
                    HapticBoostManager.shared.triggerWaterBurst()
                }
            }
        }
    }
    
    private func resetDuration() {
        totalDuration = selectedMode.defaultDurationSeconds
        remainingSeconds = Int(totalDuration)
        progress = 0.0
        elapsedSeconds = 0.0
        
        switch selectedMode {
        case .water:
            currentFrequency = 165.0
        case .dust:
            currentFrequency = 100.0
        case .pro:
            currentFrequency = 440.0
        }
    }
    
    // MARK: - Запуск программы очистки
    public func startCleaning() {
        guard !isRunning else { return }
        
        // Проверка уровня громкости
        if AudioSessionManager.shared.currentVolume < 0.95 {
            showVolumeWarning = true
        }
        
        AudioSessionManager.shared.setBoostActive(isBoostEnabled)
        AudioSessionManager.shared.setChannel(selectedChannel)
        isRunning = true
        isPaused = false
        isFinished = false
        
        HapticFeedback.notification(.success)
        
        // Старт аудио-движка в зависимости от режима с учетом выбранного спикера
        switch selectedMode {
        case .water:
            currentFrequency = 165.0
        case .dust:
            currentFrequency = 100.0
        case .pro:
            break
        }
        startAudio()
        syncContinuousVibration()
        
        startTimerLoop()
    }
    
    public func pauseCleaning() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        timerTask?.cancel()
        timerTask = nil
        AudioEngineService.shared.stop()
        syncContinuousVibration()
        HapticFeedback.impact(.light)
    }
    
    public func resumeCleaning() {
        guard isRunning, isPaused else { return }
        isPaused = false
        HapticFeedback.impact(.medium)

        startAudio()
        syncContinuousVibration()

        startTimerLoop()
    }

    public func stopCleaning() {
        timerTask?.cancel()
        timerTask = nil
        isRunning = false
        isPaused = false
        endAudio()
        resetDuration()
        HapticFeedback.impact(.rigid)
    }

    // MARK: - Звук и вибрация

    /// Запуск тона или свипа текущего режима. В усиленном режиме: меандр (больше энергии и гармоник) и без пауз
    private func startAudio() {
        let boost = isBoostEnabled
        AudioEngineService.shared.setBoost(boost)

        switch selectedMode {
        case .water:
            AudioEngineService.shared.startTone(
                frequency: currentFrequency,
                waveform: boost ? .square : .sine,
                volume: 1.0,
                isPulsing: !boost,
                pulseOn: 0.45,
                pulseOff: 0.15,
                channel: selectedChannel
            )

        case .dust:
            AudioEngineService.shared.startSweep(
                startFreq: 100.0,
                endFreq: 10000.0,
                duration: 4.0,
                waveform: boost ? .square : .sawtooth,
                volume: 1.0,
                channel: selectedChannel
            )

        case .pro:
            AudioEngineService.shared.startTone(
                frequency: currentFrequency,
                waveform: boost ? .square : .sine,
                volume: 1.0,
                isPulsing: false,
                channel: selectedChannel
            )
        }
    }
    
    /// Полная остановка: звук, вибрация и возврат аудио-сессии к обычной конфигурации (нужна диагностике)
    private func endAudio() {
        AudioEngineService.shared.stop()
        AudioEngineService.shared.setBoost(false)
        syncContinuousVibration()
        AudioSessionManager.shared.setBoostActive(false)
    }

    /// Непрерывная вибрация идет только в усиленном режиме, пока очистка запущена, не на паузе и Haptic Boost включен
    private func syncContinuousVibration() {
        if isBoostEnabled && isHapticBoostEnabled && isRunning && !isPaused {
            HapticBoostManager.shared.startContinuousVibration()
        } else {
            HapticBoostManager.shared.stopContinuousVibration()
        }
    }

    // MARK: - Внутренний цикл таймера
    private func startTimerLoop() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            let intervalNanoseconds: UInt64 = 100_000_000 // 100 мс (10 раз в секунду)
            
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: intervalNanoseconds)
                guard let self, self.isRunning, !self.isPaused else { break }
                
                self.elapsedSeconds += 0.1
                self.remainingSeconds = max(0, Int(ceil(self.totalDuration - self.elapsedSeconds)))
                self.progress = min(1.0, self.elapsedSeconds / self.totalDuration)
                
                // Динамическая адаптация частот
                self.updateFrequenciesForMode()
                
                // Проверка завершения
                if self.elapsedSeconds >= self.totalDuration {
                    self.finishCleaning()
                    break
                }
            }
        }
    }
    
    private func updateFrequenciesForMode() {
        switch selectedMode {
        case .water:
            // Без пауз в тоне (усиленный режим) такты импульсов не приходят: анимацию брызг ведем по таймеру
            if isBoostEnabled && fmod(elapsedSeconds, 0.6) < 0.1 {
                burstTriggerCounter += 1
            }

            // Фазовое переключение резонансных частот для выдувания капель разного объема
            let progressFraction = elapsedSeconds / totalDuration
            if progressFraction < 0.33 {
                if currentFrequency != 145.0 {
                    currentFrequency = 145.0
                    AudioEngineService.shared.updateFrequency(145.0)
                }
            } else if progressFraction < 0.66 {
                if currentFrequency != 155.0 {
                    currentFrequency = 155.0
                    AudioEngineService.shared.updateFrequency(155.0)
                }
            } else {
                if currentFrequency != 165.0 {
                    currentFrequency = 165.0
                    AudioEngineService.shared.updateFrequency(165.0)
                }
            }
            
        case .dust:
            // Для режима пыли визуализируем текущую точку свипа
            let sweepProgress = Float(fmod(elapsedSeconds, 4.0) / 4.0)
            let logStart = log(100.0)
            let logEnd = log(10000.0)
            currentFrequency = exp(Float(logStart) + sweepProgress * Float(logEnd - logStart))
            
            // Периодическая микровибрация (в усиленном режиме вместо нее идет непрерывная вибрация)
            if !isBoostEnabled && fmod(elapsedSeconds, 1.0) < 0.1 && isHapticBoostEnabled {
                HapticBoostManager.shared.triggerDustMicroVibration()
            }
            
        case .pro:
            break
        }
    }
    
    private func finishCleaning() {
        isRunning = false
        isPaused = false
        isFinished = true
        endAudio()
        CleaningHistoryManager.shared.recordCleaning(
            channel: selectedChannel,
            mode: selectedMode,
            duration: Int(totalDuration)
        )
        HapticFeedback.notification(.success)
    }
}
