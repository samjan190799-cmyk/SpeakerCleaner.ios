import Foundation
import AVFoundation
import Accelerate

// MARK: - Потокобезопасная RAII-обертка над vDSP FFTSetup для Swift 6
final class FFTSetupWrapper: @unchecked Sendable {
    let setup: FFTSetup?
    
    init(size: Int) {
        let log2n = vDSP_Length(log2(Double(size)))
        self.setup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))
    }
    
    deinit {
        if let setup {
            vDSP_destroy_fftsetup(setup)
        }
    }
}

// MARK: - Раскладка 24 логарифмических полос 100 Гц – 10 кГц по бинам БПФ
struct SpectralBandLayout: Sendable {
    static let bandCount = 24
    static let minFrequency: Float = 100.0
    static let maxFrequency: Float = 10_000.0
    /// Уровень амплитуды (дБ относительно полной шкалы), соответствующий нулевой высоте полосы
    static let dbFloor: Float = -80.0

    /// Диапазон бинов БПФ для каждой полосы (на низких частотах соседние полосы могут делить один бин)
    let binRanges: [Range<Int>]

    init(sampleRate: Double, fftSize: Int) {
        let binWidth = Float(sampleRate) / Float(fftSize)
        let halfSize = fftSize / 2
        let ratio = Self.maxFrequency / Self.minFrequency

        let edgeBins = (0...Self.bandCount).map { edge -> Int in
            let frequency = Self.minFrequency * pow(ratio, Float(edge) / Float(Self.bandCount))
            return min(max(Int((frequency / binWidth).rounded()), 1), halfSize - 1)
        }
        binRanges = (0..<Self.bandCount).map { band in
            edgeBins[band]..<min(max(edgeBins[band + 1], edgeBins[band] + 1), halfSize)
        }
    }

    /// Индекс полосы, в которую попадает частота (за пределами диапазона — крайняя полоса)
    func bandIndex(for frequency: Float) -> Int {
        guard frequency > Self.minFrequency else { return 0 }
        let position = log(frequency / Self.minFrequency) / log(Self.maxFrequency / Self.minFrequency)
        return min(Int(position * Float(Self.bandCount)), Self.bandCount - 1)
    }
}

// MARK: - Спектральный анализатор частотного отклика микрофона на базе Accelerate vDSP
@Observable
@MainActor
public final class SpectralAnalyzer {
    public static let shared = SpectralAnalyzer()
    
    public private(set) var isAnalyzing: Bool = false
    public private(set) var spectrumBands: [Float] = Array(repeating: 0.0, count: SpectralBandLayout.bandCount)
    public private(set) var inputLevelDb: Float = -60.0
    public private(set) var hasMicrophonePermission: Bool = false
    
    @ObservationIgnored private let recordingEngine = AVAudioEngine()
    @ObservationIgnored private let fftSize = 1024
    @ObservationIgnored private let fftWrapper = FFTSetupWrapper(size: 1024)
    @ObservationIgnored private var bandLayout = SpectralBandLayout(sampleRate: 44100, fftSize: 1024)
    
    private init() {
        checkPermission()
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

        // Границы полос зависят от частоты дискретизации входа (44,1 / 48 кГц)
        let layout = SpectralBandLayout(sampleRate: format.sampleRate, fftSize: fftSize)
        self.bandLayout = layout

        let setup = self.fftWrapper.setup
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer, fftSetup: setup, layout: layout)
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
        spectrumBands = Array(repeating: 0.0, count: SpectralBandLayout.bandCount)
        inputLevelDb = -60.0
    }

    /// Уровень (0...1) в полосе тестового тона и в двух соседних: тон на границе полос не теряется
    public func toneLevel(at frequency: Float) -> Float {
        let index = bandLayout.bandIndex(for: frequency)
        let range = max(0, index - 1)...min(spectrumBands.count - 1, index + 1)
        return spectrumBands[range].max() ?? 0.0
    }

    // MARK: - Обработка аудио-буфера с вычислением FFT через vDSP
    private nonisolated func processAudioBuffer(_ buffer: AVAudioPCMBuffer, fftSetup: FFTSetup?, layout: SpectralBandLayout) {
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
                if let fftSetup {
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
        
        // 4. Группировка в 24 логарифмические спектральные полосы (100 Гц – 10 кГц)
        // vDSP_fft_zrip возвращает спектр, масштабированный пропорционально размеру БПФ: приводим к амплитуде
        let amplitudeScale = 1.0 / Float(fftSize)
        var bands = [Float](repeating: 0.0, count: SpectralBandLayout.bandCount)
        
        for (i, binRange) in layout.binRanges.enumerated() {
            // Пик, а не среднее: широкие верхние полосы иначе «размывают» узкий тестовый тон
            var peak: Float = 0.0
            for bin in binRange {
                peak = max(peak, magnitudes[bin])
            }
            // Нормализация в диапазон 0.0 ... 1.0 по шкале dbFloor ... 0 дБ
            let db = 20.0 * log10(max(peak * amplitudeScale, 0.00001))
            bands[i] = min(max((db - SpectralBandLayout.dbFloor) / -SpectralBandLayout.dbFloor, 0.0), 1.0)
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
