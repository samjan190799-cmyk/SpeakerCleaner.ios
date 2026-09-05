import Foundation
import SwiftUI

// MARK: - ViewModel для экрана спектральной диагностики динамиков
@Observable
@MainActor
public final class DiagnosticsViewModel {
    public var selectedChannel: SpeakerChannel = .main {
        didSet {
            AudioSessionManager.shared.setChannel(selectedChannel)
        }
    }
    
    public private(set) var isTestingChannel: Bool = false
    public private(set) var isRunningSpectralTest: Bool = false
    public private(set) var testProgress: Double = 0.0
    public private(set) var currentTestPhaseText: String = ""
    public private(set) var lastResult: DiagnosticResult?
    public private(set) var baselineResult: DiagnosticResult? // Результат до очистки для сравнения
    
    private var testTask: Task<Void, Never>?
    
    public init() {}
    
    // MARK: - Тестирование аудио-канала (Основной / Разговорный)
    public func testChannel(_ channel: SpeakerChannel) {
        guard !isTestingChannel, !isRunningSpectralTest else { return }
        self.selectedChannel = channel
        self.isTestingChannel = true
        self.testProgress = 0.0
        AudioSessionManager.shared.setChannel(channel)
        
        // Для верхнего разговорного динамика используется резонансная частота 1100 Гц (максимальная громкость и разборчивость ресивера).
        // Для нижнего динамика — плотный калибровочный тон 440 Гц на 100% громкости.
        let testFreq: Float = (channel == .earpiece) ? 1100.0 : 440.0
        AudioEngineService.shared.startTone(frequency: testFreq, waveform: .sine, volume: 1.0, channel: channel)
        HapticFeedback.impact(.medium)
        
        testTask?.cancel()
        testTask = Task {
            let totalSteps = 25
            for step in 1...totalSteps {
                try? await Task.sleep(nanoseconds: 100_000_000)
                guard !Task.isCancelled else { break }
                self.testProgress = Double(step) / Double(totalSteps)
                if step % 6 == 0 {
                    HapticFeedback.selection()
                }
            }
            AudioEngineService.shared.stop()
            self.isTestingChannel = false
            self.testProgress = 0.0
            HapticFeedback.notification(.success)
        }
    }
    
    // MARK: - Комплексный спектральный тест динамика через микрофон
    public func startSpectralTest() {
        guard !isRunningSpectralTest else { return }
        
        Task {
            // Проверка разрешения на микрофон
            let hasPerm = await SpectralAnalyzer.shared.requestPermission()
            guard hasPerm else { return }
            
            self.isRunningSpectralTest = true
            self.testProgress = 0.0
            
            // Активируем спектральный анализатор микрофона
            SpectralAnalyzer.shared.start()
            
            // Фаза 1: Проверка низких частот (Бас / Мембрана) 180 Гц
            self.currentTestPhaseText = "Тест низких частот (180 Гц)..."
            AudioEngineService.shared.startTone(frequency: 180.0, waveform: .sine, volume: 0.9)
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            let bassSample = SpectralAnalyzer.shared.spectrumBands.prefix(8).reduce(0, +) / 8.0
            self.testProgress = 0.33
            
            // Фаза 2: Проверка средних частот (Разборчивость речи) 1500 Гц
            self.currentTestPhaseText = "Тест средних частот (1.5 кГц)..."
            AudioEngineService.shared.startTone(frequency: 1500.0, waveform: .sine, volume: 0.85)
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            let midSample = SpectralAnalyzer.shared.spectrumBands[8..<16].reduce(0, +) / 8.0
            self.testProgress = 0.66
            
            // Фаза 3: Проверка высоких частот (Чистота сетки) 6500 Гц
            self.currentTestPhaseText = "Тест высоких частот (6.5 кГц)..."
            AudioEngineService.shared.startTone(frequency: 6500.0, waveform: .triangle, volume: 0.8)
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            let trebleSample = SpectralAnalyzer.shared.spectrumBands.suffix(8).reduce(0, +) / 8.0
            self.testProgress = 1.0
            
            // Остановка воспроизведения и анализатора
            AudioEngineService.shared.stop()
            SpectralAnalyzer.shared.stop()
            
            // Вычисление оценки чистоты динамика (0 ... 100%)
            let bassClarity = Double(min(max(bassSample * 1.4, 0.2), 1.0))
            let midClarity = Double(min(max(midSample * 1.2, 0.3), 1.0))
            let trebleClarity = Double(min(max(trebleSample * 1.5, 0.1), 1.0))
            
            // Взвешенный расчет итогового индекса
            let totalWeighted = (bassClarity * 0.35) + (midClarity * 0.35) + (trebleClarity * 0.30)
            let finalScore = Int(totalWeighted * 100)
            
            let result = DiagnosticResult(
                channel: self.selectedChannel,
                cleanlinessScore: finalScore,
                frequencyResponse: SpectralAnalyzer.shared.spectrumBands,
                bassClarity: bassClarity,
                midClarity: midClarity,
                trebleClarity: trebleClarity
            )
            
            if self.baselineResult == nil {
                self.baselineResult = result
            }
            self.lastResult = result
            self.isRunningSpectralTest = false
            self.currentTestPhaseText = ""
            
            // Запись в журнал истории и графиков
            CleaningHistoryManager.shared.recordDiagnosticResult(result)
            
            HapticFeedback.notification(.success)
        }
    }
}
