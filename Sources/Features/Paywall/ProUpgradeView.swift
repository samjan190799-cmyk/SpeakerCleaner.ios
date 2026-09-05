import SwiftUI

// MARK: - Премиальный экран Pro-версии (Apple HIG 2026, Liquid Glassmorphism)
public struct ProUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: Int = 0 // 0: Годовой, 1: Пожизненный
    @State private var isPulsing: Bool = false
    @State private var isPurchasing: Bool = false
    @State private var showSuccessAlert: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            // Фоновое сияние
            ambientPaywallGlow
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    // Верхняя панель закрытия и восстановления
                    topBar
                    
                    // Блок брендинга Pro
                    heroHeader
                    
                    // Сетка преимуществ
                    featuresGrid
                    
                    // Карточки выбора тарифа
                    planSelectionCards
                    
                    // Большая кнопка оформления
                    ctaButton
                    
                    // Подвал с юридической информацией и гарантией
                    legalFooter
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
        }
        .alert("Pro-доступ активирован!", isPresented: $showSuccessAlert) {
            Button("Отлично", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Все профессиональные акустические функции, генератор до 22 кГц и безлимитный FFT-анализ успешно разблокированы.")
        }
    }
    
    // MARK: - Компоненты экрана
    
    private var ambientPaywallGlow: some View {
        VStack {
            Circle()
                .fill(Theme.dustGold.opacity(0.16))
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .offset(y: -40)
            Spacer()
        }
        .ignoresSafeArea()
    }
    
    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color.white.opacity(0.4))
            }
            
            Spacer()
            
            Button {
                HapticFeedback.selection()
                // Имитация восстановления покупок
                showSuccessAlert = true
            } label: {
                Text("Восстановить")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(.top, 12)
    }
    
    private var heroHeader: some View {
        VStack(spacing: 12) {
            // Анимированная иконка кристалла/алмаза
            ZStack {
                Circle()
                    .fill(Theme.dustGold.opacity(0.18))
                    .frame(width: 84, height: 84)
                    .scaleEffect(isPulsing ? 1.12 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isPulsing)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.dustGold, Color(hex: "FFAA00")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Theme.dustGold.opacity(0.6), radius: 14)
            }
            .onAppear {
                isPulsing = true
            }
            
            VStack(spacing: 4) {
                Text("PhoneCare Pro Hub")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                
                Text("Максимальная защита и чистота динамиков вашего iPhone без ограничений.")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
    }
    
    private var featuresGrid: some View {
        VStack(spacing: 12) {
            featureRow(
                icon: "waveform.badge.magnifyingglass",
                color: Theme.waterCyan,
                title: "Безлимитный генератор до 22 000 Гц",
                subtitle: "Тонкая очистка на суббасах 10 Гц и ультразвуковом диапазоне."
            )
            
            featureRow(
                icon: "waveform.path.ecg",
                color: Theme.dustGold,
                title: "Глубокая спектральная FFT-оценка",
                subtitle: "Снятие амплитудно-частотной характеристики через микрофон."
            )
            
            featureRow(
                icon: "bolt.shield.fill",
                color: Theme.proPurple,
                title: "Экстренный Water Eject Pro",
                subtitle: "Усиленный импульсный режим двойной мощности с Taptic Boost."
            )
            
            featureRow(
                icon: "bell.badge.waveform.fill",
                color: Theme.successGreen,
                title: "Умное расписание и виджеты",
                subtitle: "Регулярная гигиена и предотвращение необратимого окисления сеток."
            )
        }
        .padding(16)
        .liquidGlass(cornerRadius: 20)
    }
    
    private func featureRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(color.opacity(0.16))
                .frame(width: 38, height: 38)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(Theme.textSecondary)
            }
            Spacer()
        }
    }
    
    private var planSelectionCards: some View {
        VStack(spacing: 10) {
            // Годовой тариф (Лучший выбор)
            planCard(
                index: 0,
                title: "1 Год — Полный доступ",
                price: "990 ₽ / год",
                detail: "3 дня бесплатно, затем ~82 ₽/мес",
                badge: "ВЫГОДА 70%"
            )
            
            // Пожизненный Pro
            planCard(
                index: 1,
                title: "Пожизненная лицензия",
                price: "1 990 ₽ разово",
                detail: "Все будущие обновления навсегда",
                badge: "РАЗ И НАВСЕГДА"
            )
        }
    }
    
    private func planCard(index: Int, title: String, price: String, detail: String, badge: String?) -> some View {
        let isSelected = selectedPlan == index
        
        return Button {
            HapticFeedback.selection()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedPlan = index
            }
        } label: {
            HStack(spacing: 14) {
                // Радиокнопка
                Circle()
                    .fill(isSelected ? Theme.dustGold : Color.white.opacity(0.06))
                    .frame(width: 22, height: 22)
                    .overlay(
                        Circle()
                            .fill(Color.black)
                            .frame(width: 8, height: 8)
                            .opacity(isSelected ? 1.0 : 0.0)
                    )
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        
                        if let badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .black))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.dustGold.opacity(0.25))
                                .foregroundColor(Theme.dustGold)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(detail)
                        .font(.caption2)
                        .foregroundColor(Theme.textSecondary)
                }
                
                Spacer()
                
                Text(price)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? Theme.dustGold : Theme.textPrimary)
            }
            .padding(14)
            .background(isSelected ? Theme.dustGold.opacity(0.12) : Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Theme.dustGold : Color.white.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
            )
        }
    }
    
    private var ctaButton: some View {
        Button {
            HapticFeedback.impact(.heavy)
            isPurchasing = true
            Task {
                try? await Task.sleep(nanoseconds: 800_000_000)
                isPurchasing = false
                showSuccessAlert = true
            }
        } label: {
            HStack(spacing: 8) {
                if isPurchasing {
                    ProgressView()
                        .tint(.black)
                } else {
                    Image(systemName: "sparkles")
                    Text(selectedPlan == 0 ? "Попробовать бесплатно 3 дня" : "Активировать навсегда")
                        .fontWeight(.bold)
                }
            }
            .font(.system(size: 16))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [Theme.dustGold, Color(hex: "FFAA00")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.black)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Theme.dustGold.opacity(0.45), radius: 14, x: 0, y: 5)
        }
        .disabled(isPurchasing)
    }
    
    private var legalFooter: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Link("Условия использования", destination: URL(string: "https://apple.com")!)
                Text("•")
                    .foregroundColor(Theme.textTertiary)
                Link("Конфиденциальность", destination: URL(string: "https://apple.com")!)
            }
            .font(.caption2)
            .foregroundColor(Theme.textTertiary)
            
            Text("Оплата через Apple App Store. Подписку можно отменить в любое время в настройках Apple ID.")
                .font(.system(size: 10))
                .foregroundColor(Theme.textTertiary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 4)
    }
}
