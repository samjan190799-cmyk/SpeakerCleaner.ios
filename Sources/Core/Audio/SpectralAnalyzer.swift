import Foundation
import AVFoundation
import Accelerate

// MARK: - Спектральный анализатор частотного отклика микрофона на базе Accelerate vDSP
@Observable
@MainActor
public final class SpectralAnalyzer {
    public static let shared = SpectralAnalyzer()
    
    public private(set) var isAnalyzing: Bool = false
    public private(set) var spectrumBands: [Float] = Array(repeating: 0.0, count: 24)
    public private(set) var inputLevelDb: Float = -60.0
    public private(set) var hasMicrophonePermission: Bool = false
    
    private let recordingEngine = AVAudioEngine()
    private let fftSize = 1024
    private var fftSetup: FFTSetup?
    
    private init() {
        checkPermission()
        setupFFT()
    }
    
    deinit {
        if let fftSetup {
            vDSP_destroy_fftsetup(fftSetup)
        }
    }
    
    private func setupFFT() {
        let log2n = vDSP_Length(log2(Double(fftSize)))
        fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))
    }
    
    public func checkPermission() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            hasMicrophonePermission = true
        case .denied:
            hasMicrophonePermission = false
        case .undetermined:
            hasMicrophonePermission = false
        @unknown default:
            hasMicrophonePermission = false
        }
    }
    
    public func requestPermission() async -> Bool {
        let granted = await AVAudioApplication.requestRecordPermission()
        self.hasMicrophonePermission = granted
        return granted
    }
    
    // MARK: - Запуск спектрального захвата
    public func start() {
        guard hasMicrophonePermission else { return }
        guard !recordingEngine.isRunning else { return }
        
        let inputNode = recordingEngine.inputNode
        let format = inputNode.inputFormat(forBus: 0)
        guard format.sampleRate > 0 else { return }
        
        let bufferSize = AVAudioFrameCount(fftSize)
        
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        
        do {
            try recordingEngine.start()
            isAnalyzing = true
        } catch {
            print("❌ Ошибка запуска анализатора микрофона: \(error.localizedDescription)")
        }
    }
    
    public func stop() {
        guard recordingEngine.isRunning else { return }
        recordingEngine.inputNode.removeTap(onBus: 0)
        recordingEngine.stop()
        isAnalyzing = false
        // Сброс полос спектра
        spectrumBands = Array(repeating: 0.0, count: 24)
        inputLevelDb = -60.0
    }
    
    // MARK: - Обработка аудио-буфера с вычислением FFT через vDSP
    private nonisolated func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)
        guard frameCount >= fftSize else { return }
        
        // 1. Применение оконной функции Хэннинга (Hanning Window)
        var window = [Float](repeating: 0.0, count: fftSize)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
        
        var windowedSamples = [Float](repeating: 0.0, count: fftSize)
        vDSP_vmul(channelData, 1, window, 1, &windowedSamples, 1, vDSP_Length(fftSize))
        
        // 2. Подготовка комплексного массива (DSPSplitComplex)
        var realp = [Float](repeating: 0.0, count: fftSize / 2)
        var imagp = [Float](repeating: 0.0, count: fftSize / 2)
        
        realp.withUnsafeMutableBufferPointer { realPtr in
            imagp.withUnsafeMutableBufferPointer { imagPtr in
                var splitComplex = DSPSplitComplex(
                    realp: realPtr.baseAddress!,
                    imagp: imagPtr.baseAddress!
                )
                
                windowedSamples.withUnsafeBytes { rawBuffer in
                    let complexBuffer = rawBuffer.bindMemory(to: DSPComplex.self)
                    vDSP_ctoz(complexBuffer.baseAddress!, 2, &splitComplex, 1, vDSP_Length(fftSize / 2))
                }
                
                let log2n = vDSP_Length(log2(Double(fftSize)))
                if let fftSetup = self.fftSetup {
                    vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))
                }
            }
        }
        
        // 3. Вычисление амплитудного спектра (Magnitudes)
        var magnitudes = [Float](repeating: 0.0, count: fftSize / 2)
        realp.withUnsafeBufferPointer { rPtr in
            imagp.withUnsafeBufferPointer { iPtr in
                var split = DSPSplitComplex(realp: UnsafeMutablePointer(mutating: rPtr.baseAddress!),
                                            imagp: UnsafeMutablePointer(mutating: iPtr.baseAddress!))
                vDSP_zvabs(&split, 1, &magnitudes, 1, vDSP_Length(fftSize / 2))
            }
        }
        
        // 4. Группировка в 24 логарифмические спектральные полосы
        let bandCount = 24
        var bands = [Float](repeating: 0.0, count: bandCount)
        let binsPerBand = (fftSize / 2) / bandCount
        
        for i in 0..<bandCount {
            var bandSum: Float = 0.0
            for j in 0..<binsPerBand {
                let index = i * binsPerBand + j
                bandSum += magnitudes[index]
            }
            let avg = bandSum / Float(binsPerBand)
            // Нормализация в диапазон 0.0 ... 1.0 с логарифмической шкалой
            let db = 20.0 * log10(max(avg, 0.0001))
            let normalized = min(max((db + 60.0) / 60.0, 0.0), 1.0)
            bands[i] = normalized
        }
        
        // 5. Расчет RMS уровня громкости входа
        var rms: Float = 0.0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameCount))
        let dbLevel = 20.0 * log10(max(rms, 0.00001))
        
        // Обновление на главном потоке
        Task { @MainActor in
            self.spectrumBands = bands
            self.inputLevelDb = dbLevel
        }
    }
}
