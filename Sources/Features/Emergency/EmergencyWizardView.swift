import SwiftUI

// MARK: - Интерактивный экстренный визард первой помощи смартфону
public struct EmergencyWizardView: View {
    @State private var selectedCase: EmergencyCase = EmergencyData.cases[0]
    @State private var isEjectingWater: Bool = false
    @State private var ejectProgress: Double = 0.0
    @State private var ejectSecondsRemaining: Int = 30
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Верхний переключатель сценариев ЧП
                        casesPicker
                        
                        // Карточка текущего экстренного сценария
                        caseHeaderCard
                        
                        // Кнопка быстрого звукового выталкивания влаги (если требуется)
                        if selectedCase.requiresWaterEject {
                            waterEjectEmergencyCard
                        }
                        
                        // Критические ошибки (Что нельзя делать)
                        fatalMistakesCard
                        
                        // Пошаговый план спасения
                        rescueStepsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Экстренная помощь")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Компоненты экрана
    
    private var casesPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(EmergencyData.cases) { item in
                    let isSelected = selectedCase.id == item.id
                    Button {
                        HapticFeedback.selection()
                        withAnimation(.spring()) {
                            selectedCase = item
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: item.iconName)
                                .font(.subheadline)
                            Text(item.title)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isSelected ? item.accentColor.opacity(0.25) : Color.white.opacity(0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(isSelected ? item.accentColor : Color.white.opacity(0.08), lineWidth: 1.5)
                                )
                        )
                        .foregroundColor(isSelected ? Theme.textPrimary : Theme.textTertiary)
                    }
                }
            }
        }
    }
    
    private var caseHeaderCard: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(selectedCase.accentColor.opacity(0.2))
                .frame(width: 54, height: 54)
                .overlay(
                    Image(systemName: selectedCase.iconName)
                        .font(.title2)
                        .foregroundColor(selectedCase.accentColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedCase.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                
                Text(selectedCase.shortDescription)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .liquidGlass(cornerRadius: 20, strokeColor: selectedCase.accentColor.opacity(0.3))
    }
    
    private var waterEjectEmergencyCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundColor(Theme.waterCyan)
                Text("Экстренная звуковая продувка")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }
            
            Text("Импульсный низкочастотный резонанс (140–165 Гц) для мгновенного выброса жидкости из сеток динамиков.")
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
            
            if isEjectingWater {
                VStack(spacing: 8) {
                    ProgressView(value: ejectProgress)
                        .tint(Theme.waterCyan)
                    
                    HStack {
                        Text("Выдувание капель... Держите телефон динамиками вниз")
                            .font(.caption2)
                            .foregroundColor(Theme.waterCyan)
                        Spacer()
                        Text("\(ejectSecondsRemaining) сек")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.textPrimary)
                    }
                    
                    Button {
                        stopWaterEject()
                    } label: {
                        Text("Остановить")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Theme.dangerRed.opacity(0.2))
                            .foregroundColor(Theme.dangerRed)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            } else {
                Button {
                    startWaterEject()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "drop.fill")
                        Text("Запустить Water Eject прямо сейчас")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 14))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(LinearGradient.waterGradient)
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 18, strokeColor: Theme.waterCyan.opacity(0.3))
    }
    
    private var fatalMistakesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "xmark.octagon.fill")
                    .foregroundColor(Theme.dangerRed)
                Text("Смертельные ошибки (Не делайте этого!)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.dangerRed)
            }
            
            ForEach(selectedCase.deadlyMistakes, id: \.self) { mistake in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundColor(Theme.dangerRed)
                        .fontWeight(.bold)
                    Text(mistake)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textPrimary)
                        .lineSpacing(2)
                }
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 18, strokeColor: Theme.dangerRed.opacity(0.4))
    }
    
    private var rescueStepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Пошаговый план действий")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            
            VStack(spacing: 10) {
                ForEach(selectedCase.urgentSteps) { step in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(selectedCase.accentColor.opacity(0.2))
                                .frame(width: 28, height: 28)
                            Text("\(step.order)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(selectedCase.accentColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(step.actionTitle)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.textPrimary)
                            
                            Text(step.details)
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textSecondary)
                                .lineSpacing(2)
                        }
                    }
                    .padding(14)
                    .liquidGlass(cornerRadius: 16)
                }
            }
        }
    }
    
    private func startWaterEject() {
        isEjectingWater = true
        ejectSecondsRemaining = 30
        ejectProgress = 0.0
        
        AudioEngineService.shared.startTone(
            frequency: 165.0,
            waveform: .sine,
            volume: 1.0,
            isPulsing: true,
            pulseOn: 0.45,
            pulseOff: 0.15
        )
        HapticFeedback.notification(.warning)
        
        Task {
            for _ in 0..<300 {
                try? await Task.sleep(nanoseconds: 100_000_000)
                guard isEjectingWater else { break }
                ejectProgress += 1.0 / 300.0
                ejectSecondsRemaining = max(0, 30 - Int(ejectProgress * 30))
            }
            stopWaterEject()
        }
    }
    
    private func stopWaterEject() {
        isEjectingWater = false
        AudioEngineService.shared.stop()
        HapticFeedback.notification(.success)
    }
}
