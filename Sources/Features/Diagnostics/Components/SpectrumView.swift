import SwiftUI

// MARK: - Визуализатор спектрального анализатора (FFT Bar Spectrum)
public struct SpectrumView: View {
    public let bands: [Float] // 24 спектральные полосы
    public let isActive: Bool
    public let tintColor: Color
    
    public init(
        bands: [Float],
        isActive: Bool,
        tintColor: Color = Theme.waterCyan
    ) {
        self.bands = bands
        self.isActive = isActive
        self.tintColor = tintColor
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<bands.count, id: \.self) { index in
                    let value = CGFloat(bands[index])
                    
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [tintColor, tintColor.opacity(0.4)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: max(4, value * 110))
                        .animation(.easeOut(duration: 0.08), value: value)
                }
            }
            .frame(height: 120)
            .padding(.horizontal, 8)
            
            // Частотная разметка по оси X
            HStack {
                Text("100 Гц")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Theme.textTertiary)
                Spacer()
                Text("1 кГц")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Theme.textTertiary)
                Spacer()
                Text("10 кГц")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Theme.textTertiary)
            }
            .padding(.horizontal, 4)
        }
        .padding(14)
        .liquidGlass(cornerRadius: 18)
    }
}
