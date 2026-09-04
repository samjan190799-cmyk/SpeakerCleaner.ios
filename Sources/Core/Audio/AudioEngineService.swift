import Foundation
import AVFoundation
import Accelerate

// MARK: - Потокобезопасный контекст рендеринга звука для аудио-потока реального времени
final class AudioRenderContext: @unchecked Sendable {
    private var lock = os_unfair_lock_s()
    
    private var _frequency: Float = 165.0
    private var _waveform: WaveformType = .sine
    private var _volume: Float = 1.0
    private var _isPulsing: Bool = false
    private var _pulseOnDuration: Double = 0.45
    private var _pulseOffDuration: Double = 0.15
    private var _isSweeping: Bool = false
    private var _sweepStartFreq: Float = 100.0
    private var _sweepEndFreq: Float = 10000.0
    private var _sweepDuration: Double = 5.0
    
    // Внутренние параметры аудио-потока
    var phase: Float = 0.0
    var sampleRate: Float = 44100.0
    var pulseTimer: Double = 0.0
    var isPulseActive: Bool = true
    var currentEnvelope: Float = 1.0
    var sweepTimer: Double = 0.0
    
    func updateParams(
        frequency: Float,
        waveform: WaveformType,
        volume: Float,
        isPulsing: Bool,
        pulseOn: Double = 0.45,
        pulseOff: Double = 0.15,
        isSweeping: Bool = false,
        sweepStart: Float = 100.0,
        sweepEnd: Float = 10000.0,
        sweepDuration: Double = 5.0
    ) {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        self._frequency = frequency
        self._waveform = waveform
        self._volume = volume
        self._isPulsing = isPulsing
        self._pulseOnDuration = pulseOn
        self._pulseOffDuration = pulseOff
        self._isSweeping = isSweeping
        self._sweepStartFreq = sweepStart
        self._sweepEndFreq = sweepEnd
        self._sweepDuration = sweepDuration
    }
    
    func getParams() -> (
        frequency: Float,
        waveform: WaveformType,
        volume: Float,
        isPulsing: Bool,
        pulseOn: Double,
        pulseOff: Double,
        isSweeping: Bool,
        sweepStart: Float,
        sweepEnd: Float,
        sweepDuration: Double
    ) {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        return (
            _frequency,
            _waveform,
            _volume,
            _isPulsing,
            _pulseOnDuration,
            _pulseOffDuration,
            _isSweeping,
            _sweepStartFreq,
            _sweepEndFreq,
            _sweepDuration
        )
    }
}

// MARK: - Сервис низкоуровневого синтеза звуковых волн на AVAudioEngine
public final class AudioEngineService: @unchecked Sendable {
    public static let shared = AudioEngineService()
    
    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private let renderContext = AudioRenderContext()
    private var isEngineRunning = false
    
    // Коллбэк импульса (для синхронизации с тактильным моторчиком CoreHaptics)
    public var onPulseBurstTriggered: (@Sendable () -> Void)?
    
    private init() {
        setupSourceNode()
    }
    
    private func setupSourceNode() {
        let context = self.renderContext
        
        // Создаем низкоуровневый источник звука с буфером реального времени
        let node = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard let firstBuffer = ablPointer.first, let rawData = firstBuffer.mData else {
                return noErr
            }
            
            let channels = ablPointer.count
            let ptr = rawData.assumingMemoryBound(to: Float.self)
            
            let params = context.getParams()
            let dt = 1.0 / Double(context.sampleRate)
            
            for frame in 0..<Int(frameCount) {
                // Обработка частотного свипа
                var currentFreq = params.frequency
                if params.isSweeping && params.sweepDuration > 0 {
                    context.sweepTimer += dt
                    let progress = Float(fmod(context.sweepTimer, params.sweepDuration) / params.sweepDuration)
                    // Логарифмический свип для равномерного акустического восприятия
                    let logStart = log(params.sweepStart)
                    let logEnd = log(params.sweepEnd)
                    currentFreq = exp(logStart + progress * (logEnd - logStart))
                }
                
                // Обработка импульсного режима (Water Eject)
                if params.isPulsing {
                    context.pulseTimer += dt
                    let cyclePeriod = params.pulseOn + params.pulseOff
                    let cyclePos = fmod(context.pulseTimer, cyclePeriod)
                    
                    if cyclePos < params.pulseOn {
                        if !context.isPulseActive {
                            context.isPulseActive = true
                            self.onPulseBurstTriggered?()
                        }
                        // Плавное нарастание/удержание амплитуды (без щелчков)
                        context.currentEnvelope = min(1.0, context.currentEnvelope + 0.01)
                    } else {
                        context.isPulseActive = false
                        // Плавный спад
                        context.currentEnvelope = max(0.0, context.currentEnvelope - 0.01)
                    }
                } else {
                    context.currentEnvelope = 1.0
                }
                
                // Расчет приращения фазы
                let phaseInc = (2.0 * Float.pi * currentFreq) / context.sampleRate
                context.phase += phaseInc
                if context.phase >= (2.0 * Float.pi) {
                    context.phase -= (2.0 * Float.pi)
                }
                
                // Вычисление сэмпла волны с огибающей и громкостью
                let sampleValue = params.waveform.sample(at: context.phase) * params.volume * context.currentEnvelope
                
                // Запись сэмпла во все активные стерео-каналы
                for channel in 0..<channels {
                    let channelBuffer = ablPointer[channel]
                    let channelPtr = channelBuffer.mData?.assumingMemoryBound(to: Float.self)
                    channelPtr?[frame] = sampleValue
                }
            }
            
            return noErr
        }
        
        self.sourceNode = node
        engine.attach(node)
        
        let outputFormat = engine.outputNode.outputFormat(forBus: 0)
        let renderFormat = AVAudioFormat(standardFormatWithSampleRate: outputFormat.sampleRate, channels: 2) ?? outputFormat
        context.sampleRate = Float(renderFormat.sampleRate)
        
        engine.connect(node, to: engine.mainMixerNode, format: renderFormat)
    }
    
    // MARK: - Публичные методы управления
    
    public func startTone(
        frequency: Float,
        waveform: WaveformType = .sine,
        volume: Float = 1.0,
        isPulsing: Bool = false,
        pulseOn: Double = 0.45,
        pulseOff: Double = 0.15
    ) {
        renderContext.updateParams(
            frequency: frequency,
            waveform: waveform,
            volume: volume,
            isPulsing: isPulsing,
            pulseOn: pulseOn,
            pulseOff: pulseOff,
            isSweeping: false
        )
        startEngineIfNeeded()
    }
    
    public func startSweep(
        startFreq: Float = 100.0,
        endFreq: Float = 10000.0,
        duration: Double = 4.0,
        waveform: WaveformType = .sawtooth,
        volume: Float = 1.0
    ) {
        renderContext.updateParams(
            frequency: startFreq,
            waveform: waveform,
            volume: volume,
            isPulsing: false,
            isSweeping: true,
            sweepStart: startFreq,
            sweepEnd: endFreq,
            sweepDuration: duration
        )
        startEngineIfNeeded()
    }
    
    public func updateFrequency(_ frequency: Float) {
        let params = renderContext.getParams()
        renderContext.updateParams(
            frequency: frequency,
            waveform: params.waveform,
            volume: params.volume,
            isPulsing: params.isPulsing,
            pulseOn: params.pulseOn,
            pulseOff: params.pulseOff,
            isSweeping: params.isSweeping,
            sweepStart: params.sweepStart,
            sweepEnd: params.sweepEnd,
            sweepDuration: params.sweepDuration
        )
    }
    
    public func updateWaveform(_ waveform: WaveformType) {
        let params = renderContext.getParams()
        renderContext.updateParams(
            frequency: params.frequency,
            waveform: waveform,
            volume: params.volume,
            isPulsing: params.isPulsing,
            pulseOn: params.pulseOn,
            pulseOff: params.pulseOff,
            isSweeping: params.isSweeping,
            sweepStart: params.sweepStart,
            sweepEnd: params.sweepEnd,
            sweepDuration: params.sweepDuration
        )
    }
    
    public func updateVolume(_ volume: Float) {
        let params = renderContext.getParams()
        renderContext.updateParams(
            frequency: params.frequency,
            waveform: params.waveform,
            volume: volume,
            isPulsing: params.isPulsing,
            pulseOn: params.pulseOn,
            pulseOff: params.pulseOff,
            isSweeping: params.isSweeping,
            sweepStart: params.sweepStart,
            sweepEnd: params.sweepEnd,
            sweepDuration: params.sweepDuration
        )
    }
    
    public func stop() {
        if engine.isRunning {
            engine.pause()
            isEngineRunning = false
        }
        renderContext.phase = 0
        renderContext.pulseTimer = 0
        renderContext.sweepTimer = 0
        renderContext.currentEnvelope = 0
    }
    
    private func startEngineIfNeeded() {
        guard !engine.isRunning else { return }
        do {
            try engine.start()
            isEngineRunning = true
        } catch {
            print("❌ Ошибка запуска AVAudioEngine: \(error.localizedDescription)")
        }
    }
}
