import SwiftUI

// MARK: - Режим безопасной чистки экрана (Screen Clean Lock)
public struct ScreenCleanLockView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var remainingSeconds: Int = 30
    @State private var isRunning: Bool = true
    @State private var isLightModeActive: Bool = false // Белый фон для поиска темных пылинок
    @State private var unlockProgress: CGFloat = 0.0
    @State private var isHoldingToUnlock: Bool = false
    @State private var timerTask: Task<Void, Never>?
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Фон: глубокий черный или яркий белый для обнаружения соринок
            (isLightModeActive ? Color.white : Color.black)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Верхний блок переключения фона подсветки
                HStack {
                    Button {
                        HapticFeedback.selection()
                        withAnimation(.spring()) {
                            isLightModeActive.toggle()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isLightModeActive ? "moon.fill" : "sun.max.fill")
                            Text(isLightModeActive ? "Темный фон" : "Белый фон")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isLightModeActive ? Color.black.opacity(0.1) : Color.white.opacity(0.12))
                        )
                        .foregroundColor(isLightModeActive ? .black : .white)
                    }
                    
                    Spacer()
                    
                    // Оставшееся время
                    Text("\(remainingSeconds) сек")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(isLightModeActive ? .black.opacity(0.8) : .white.opacity(0.8))
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer()
                
                // Центральная индикация режима протирки
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 64, weight: .light))
                        .foregroundColor(isLightModeActive ? .black.opacity(0.4) : Theme.waterCyan.opacity(0.7))
                        .symbolEffect(.pulse)
                    
                    Text("Сенсор заблокирован")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(isLightModeActive ? .black : .white)
                    
                    Text("Спокойно протирайте экран микрофиброй.\nСлучайные нажатия не сработают.")
                        .font(.system(size: 14))
                        .foregroundColor(isLightModeActive ? .black.opacity(0.6) : .white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Кнопка разблокировки удержанием (3 секунды)
                VStack(spacing: 8) {
                    ZStack {
                        // Фоновая кнопка
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(isLightModeActive ? Color.black.opacity(0.08) : Color.white.opacity(0.1))
                            .frame(height: 56)
                        
                        // Прогресс заполнения при удержании
                        GeometryReader { proxy in
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(isLightModeActive ? Color.black : Theme.waterCyan)
                                .frame(width: proxy.size.width * unlockProgress, height: 56)
                        }
                        .frame(height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        
                        HStack(spacing: 8) {
                            Image(systemName: "lock.open.fill")
                            Text(isHoldingToUnlock ? "Удерживайте для выхода..." : "Удерживайте 3 сек для выхода")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(isLightModeActive ? (unlockProgress > 0.5 ? .white : .black) : (unlockProgress > 0.5 ? .black : .white))
                    }
                    .padding(.horizontal, 24)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !isHoldingToUnlock {
                                    startHoldToUnlock()
                                }
                            }
                            .onEnded { _ in
                                cancelHoldToUnlock()
                            }
                    )
                    
                    Text("Таймер автоматически закроет экран через \(remainingSeconds) сек")
                        .font(.caption2)
                        .foregroundColor(isLightModeActive ? .black.opacity(0.4) : .white.opacity(0.4))
                }
                .padding(.bottom, 30)
            }
        }
        .statusBarHidden(true)
        .onAppear {
            startTimer()
            HapticFeedback.notification(.warning)
        }
        .onDisappear {
            timerTask?.cancel()
        }
    }
    
    private func startTimer() {
        timerTask = Task {
            while remainingSeconds > 0 && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { break }
                remainingSeconds -= 1
            }
            if remainingSeconds == 0 {
                HapticFeedback.notification(.success)
                dismiss()
            }
        }
    }
    
    private func startHoldToUnlock() {
        isHoldingToUnlock = true
        HapticFeedback.impact(.medium)
        withAnimation(.linear(duration: 2.5)) {
            unlockProgress = 1.0
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if isHoldingToUnlock && unlockProgress >= 0.95 {
                HapticFeedback.notification(.success)
                dismiss()
            }
        }
    }
    
    private func cancelHoldToUnlock() {
        isHoldingToUnlock = false
        withAnimation(.easeOut(duration: 0.2)) {
            unlockProgress = 0.0
        }
    }
}
