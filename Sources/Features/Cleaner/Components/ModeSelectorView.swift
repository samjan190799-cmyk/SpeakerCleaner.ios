import SwiftUI

// MARK: - Селектор режимов очистки в стиле Glassmorphism
public struct ModeSelectorView: View {
    @Binding public var selectedMode: CleaningMode
    public let isRunning: Bool
    
    public init(selectedMode: Binding<CleaningMode>, isRunning: Bool) {
        self._selectedMode = selectedMode
        self.isRunning = isRunning
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            ForEach(CleaningMode.allCases) { mode in
                let isSelected = selectedMode == mode
                
                Button {
                    guard !isRunning else { return }
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedMode = mode
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 14, weight: .semibold))
                        
                        Text(mode.rawValue)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        ZStack {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(mode.primaryColor.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(mode.primaryColor, lineWidth: 1.5)
                                    )
                                    .shadow(color: mode.primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                            } else {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.04))
                            }
                        }
                    )
                    .foregroundColor(isSelected ? Theme.textPrimary : Theme.textTertiary)
                }
                .disabled(isRunning)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Theme.cardBorder, lineWidth: 1)
                )
        )
    }
}
