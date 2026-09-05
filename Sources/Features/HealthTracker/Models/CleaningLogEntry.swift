import Foundation
import SwiftUI

// MARK: - Тип записи в журнале процедур
public enum CleaningLogType: String, Codable, Sendable {
    case cleaningSession = "Очистка динамика"
    case spectralDiagnostic = "Спектральный анализ"
    case manualChecklist = "Гигиена устройства"
}

// MARK: - Запись в журнале акустического здоровья и ухода за устройством
public struct CleaningLogEntry: Identifiable, Codable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let logType: CleaningLogType
    public let channel: SpeakerChannel
    public let modeTitle: String
    public let durationSeconds: Int
    public let cleanlinessScore: Int // 0 ... 100%
    public let bassScore: Int // 0 ... 100%
    public let midScore: Int // 0 ... 100%
    public let trebleScore: Int // 0 ... 100%
    public let note: String
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        logType: CleaningLogType = .cleaningSession,
        channel: SpeakerChannel = .main,
        modeTitle: String = "Вода (165 Гц)",
        durationSeconds: Int = 60,
        cleanlinessScore: Int = 85,
        bassScore: Int = 80,
        midScore: Int = 85,
        trebleScore: Int = 90,
        note: String = "Процедура выполнена успешно"
    ) {
        self.id = id
        self.timestamp = timestamp
        self.logType = logType
        self.channel = channel
        self.modeTitle = modeTitle
        self.durationSeconds = durationSeconds
        self.cleanlinessScore = cleanlinessScore
        self.bassScore = bassScore
        self.midScore = midScore
        self.trebleScore = trebleScore
        self.note = note
    }
}
