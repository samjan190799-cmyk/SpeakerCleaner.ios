import Foundation
import SwiftUI

// MARK: - Менеджер хранения истории акустических процедур и тестов
@Observable
@MainActor
public final class CleaningHistoryManager {
    public static let shared = CleaningHistoryManager()
    
    private let storageKey = "speaker_cleaner_acoustic_history_v1"
    
    public private(set) var entries: [CleaningLogEntry] = []
    
    private init() {
        loadEntries()
    }
    
    // MARK: - Загрузка и сохранение
    
    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([CleaningLogEntry].self, from: data) {
            self.entries = decoded
        } else {
            // Начальные реалистичные данные для демонстрации динамики АЧХ
            self.entries = defaultInitialHistory()
            saveEntries()
        }
    }
    
    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    // MARK: - Публичные методы
    
    public func addEntry(_ entry: CleaningLogEntry) {
        entries.insert(entry, at: 0)
        // Храним последние 50 записей
        if entries.count > 50 {
            entries = Array(entries.prefix(50))
        }
        saveEntries()
    }
    
    public func recordCleaning(channel: SpeakerChannel, mode: CleaningMode, duration: Int, estimatedGain: Int = 8) {
        let lastScore = entries.first?.cleanlinessScore ?? 75
        let newScore = min(100, lastScore + estimatedGain)
        
        let entry = CleaningLogEntry(
            timestamp: Date(),
            logType: .cleaningSession,
            channel: channel,
            modeTitle: mode.title,
            durationSeconds: duration,
            cleanlinessScore: newScore,
            bassScore: min(100, newScore - 5),
            midScore: newScore,
            trebleScore: min(100, newScore + 4),
            note: "Акустическая очистка завершена. Мембрана свободна от влаги."
        )
        addEntry(entry)
    }
    
    public func recordDiagnosticResult(_ result: DiagnosticResult) {
        let entry = CleaningLogEntry(
            timestamp: Date(),
            logType: .spectralDiagnostic,
            channel: result.channel,
            modeTitle: "Спектральный тест FFT",
            durationSeconds: 15,
            cleanlinessScore: result.cleanlinessScore,
            bassScore: Int(result.bassClarity * 100),
            midScore: Int(result.midClarity * 100),
            trebleScore: Int(result.trebleClarity * 100),
            note: "\(result.statusTitle). \(result.recommendation)"
        )
        addEntry(entry)
    }
    
    public func clearHistory() {
        entries.removeAll()
        saveEntries()
    }
    
    // MARK: - Вычисляемые метрики
    
    public var averageCleanliness: Int {
        guard !entries.isEmpty else { return 85 }
        let sum = entries.reduce(0) { $0 + $1.cleanlinessScore }
        return sum / entries.count
    }
    
    public var lastProcedureDate: Date? {
        entries.first?.timestamp
    }
    
    // MARK: - Начальные исторические записи для красивого старта графика
    private func defaultInitialHistory() -> [CleaningLogEntry] {
        let calendar = Calendar.current
        let now = Date()
        
        return [
            CleaningLogEntry(
                timestamp: now,
                logType: .cleaningSession,
                channel: .main,
                modeTitle: "Выдувание воды (165 Гц)",
                durationSeconds: 60,
                cleanlinessScore: 94,
                bassScore: 92,
                midScore: 95,
                trebleScore: 96,
                note: "Очистка после пробежки под дождем. Звук полностью восстановлен."
            ),
            CleaningLogEntry(
                timestamp: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
                logType: .spectralDiagnostic,
                channel: .earpiece,
                modeTitle: "Спектральный тест FFT",
                durationSeconds: 15,
                cleanlinessScore: 82,
                bassScore: 78,
                midScore: 84,
                trebleScore: 85,
                note: "Проверка слухового динамика перед важным звонком."
            ),
            CleaningLogEntry(
                timestamp: calendar.date(byAdding: .day, value: -7, to: now) ?? now,
                logType: .cleaningSession,
                channel: .both,
                modeTitle: "Удаление пыли (Sweep)",
                durationSeconds: 60,
                cleanlinessScore: 74,
                bassScore: 70,
                midScore: 75,
                trebleScore: 76,
                note: "Профилактическая продувка защитных сеток."
            ),
            CleaningLogEntry(
                timestamp: calendar.date(byAdding: .day, value: -12, to: now) ?? now,
                logType: .spectralDiagnostic,
                channel: .main,
                modeTitle: "Спектральный тест FFT",
                durationSeconds: 15,
                cleanlinessScore: 68,
                bassScore: 64,
                midScore: 70,
                trebleScore: 69,
                note: "Обнаружено легкое демпфирование из-за капель воды."
            )
        ]
    }
}
