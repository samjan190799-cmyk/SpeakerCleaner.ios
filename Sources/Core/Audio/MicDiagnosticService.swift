import Foundation
import AVFoundation
import SwiftUI

// MARK: - Сервис расширенной диагностики микрофонов (Loopback тест, замер шума, VU-метр)
@Observable
@MainActor
public final class MicDiagnosticService: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate, @unchecked Sendable {
    public static let shared = MicDiagnosticService()
    
    public private(set) var isRecording: Bool = false
    public private(set) var isPlayingBack: Bool = false
    public private(set) var recordDuration: Double = 0.0
    public private(set) var currentDecibels: Float = -60.0
    public private(set) var peakDecibels: Float = -60.0
    public private(set) var hasRecordedAudio: Bool = false
    public private(set) var noiseFloorLevel: Float = -45.0 // Уровень шума в комнате
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Task<Void, Never>?
    private let recordingURL: URL
    
    override private init() {
        self.recordingURL = FileManager.default.temporaryDirectory.appendingPathComponent("mic_diagnostic_test.m4a")
        super.init()
    }
    
    // MARK: - Запуск теста записи голоса (Loopback)
    public func startVoiceRecord() {
        guard !isRecording, !isPlayingBack else { return }
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            isRecording = true
            recordDuration = 0.0
            hasRecordedAudio = false
            currentDecibels = -60.0
            peakDecibels = -60.0
            
            HapticFeedback.notification(.warning)
            startMeteringLoop()
        } catch {
            print("❌ Ошибка запуска записи микрофона: \(error.localizedDescription)")
        }
    }
    
    public func stopRecordAndPlayback() {
        guard isRecording else { return }
        audioRecorder?.stop()
        recordingTimer?.cancel()
        recordingTimer = nil
        isRecording = false
        hasRecordedAudio = true
        
        HapticFeedback.notification(.success)
        playBackRecordedAudio()
    }
    
    public func playBackRecordedAudio() {
        guard FileManager.default.fileExists(atPath: recordingURL.path) else { return }
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.overrideOutputAudioPort(.speaker)
            
            audioPlayer = try AVAudioPlayer(contentsOf: recordingURL)
            audioPlayer?.delegate = self
            audioPlayer?.volume = 1.0
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            isPlayingBack = true
            HapticFeedback.impact(.medium)
        } catch {
            print("❌ Ошибка воспроизведения записи: \(error.localizedDescription)")
        }
    }
    
    public func stopPlayback() {
        audioPlayer?.stop()
        isPlayingBack = false
        HapticFeedback.impact(.light)
    }
    
    // MARK: - Мониторинг VU-метра и шума
    private func startMeteringLoop() {
        recordingTimer?.cancel()
        recordingTimer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 50_000_000) // 50 мс
                guard let self, self.isRecording, let recorder = self.audioRecorder else { break }
                
                recorder.updateMeters()
                let avg = recorder.averagePower(forChannel: 0)
                let peak = recorder.peakPower(forChannel: 0)
                
                self.currentDecibels = avg
                self.peakDecibels = max(self.peakDecibels, peak)
                self.recordDuration += 0.05
                
                // Автоматическое ограничение записи 6 секундами
                if self.recordDuration >= 6.0 {
                    self.stopRecordAndPlayback()
                    break
                }
            }
        }
    }
    
    // MARK: - Делегаты AVAudioRecorder / AVAudioPlayer
    public nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlayingBack = false
            HapticFeedback.notification(.success)
        }
    }
    
    public nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            self.isRecording = false
        }
    }
}
