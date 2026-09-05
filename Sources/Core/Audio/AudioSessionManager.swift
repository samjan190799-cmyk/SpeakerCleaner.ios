import Foundation
import AVFoundation
import Combine

// MARK: - Менеджер аудио-сессии и маршрутизации каналов спикеров
@Observable
@MainActor
public final class AudioSessionManager {
    public static let shared = AudioSessionManager()
    
    public private(set) var currentVolume: Float = 1.0
    public private(set) var isMaxVolume: Bool = true
    public private(set) var activeChannel: SpeakerChannel = .main
    public private(set) var isHeadphonesConnected: Bool = false
    
    private var volumeObservation: NSKeyValueObservation?
    
    private init() {
        configureSession()
        observeVolumeChanges()
        checkConnectedOutputs()
    }
    
    /// Первоначальная настройка AVAudioSession для одновременного воспроизведения и спектрального анализа
    public func configureSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playAndRecord,
                mode: .measurement,
                options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers]
            )
            try session.setActive(true)
            self.currentVolume = session.outputVolume
            self.isMaxVolume = session.outputVolume >= 0.99
            applyChannelRouting(activeChannel)
        } catch {
            print("❌ Ошибка настройки AVAudioSession: \(error.localizedDescription)")
        }
    }
    
    /// Переключение канала вывода звука (Нижний мультимедийный спикер или Верхний разговорный динамик)
    public func setChannel(_ channel: SpeakerChannel) {
        self.activeChannel = channel
        applyChannelRouting(channel)
        AudioEngineService.shared.setChannel(channel)
    }
    
    private func applyChannelRouting(_ channel: SpeakerChannel) {
        let session = AVAudioSession.sharedInstance()
        do {
            switch channel {
            case .main:
                // Нижний динамик: строгая изоляция громкоговорителя без стерео-подмешивания в верхний спикер
                try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
                try session.overrideOutputAudioPort(.speaker)
            case .both:
                // Оба динамика: стерео-режим воспроизведения мультимедиа
                try session.setCategory(.playback, mode: .default, options: [.duckOthers])
                try session.overrideOutputAudioPort(.speaker)
            case .earpiece:
                // Верхний разговорный динамик (ресивер): чистый режим .default без телефонного глушения и компрессии
                try session.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth])
                try session.overrideOutputAudioPort(.none)
            }
            try session.setActive(true)
        } catch {
            print("❌ Ошибка маршрутизации аудио-порта \(channel.rawValue): \(error.localizedDescription)")
        }
    }
    
    /// Мониторинг системной громкости
    private func observeVolumeChanges() {
        let session = AVAudioSession.sharedInstance()
        volumeObservation = session.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
            guard let newVol = change.newValue else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.currentVolume = newVol
                self.isMaxVolume = newVol >= 0.99
            }
        }
    }
    
    /// Проверка подключенных наушников или внешних колонок
    public func checkConnectedOutputs() {
        let session = AVAudioSession.sharedInstance()
        let outputs = session.currentRoute.outputs
        let headphones = outputs.contains { port in
            port.portType == .headphones ||
            port.portType == .bluetoothA2DP ||
            port.portType == .bluetoothHFP ||
            port.portType == .bluetoothLE
        }
        self.isHeadphonesConnected = headphones
    }
}
