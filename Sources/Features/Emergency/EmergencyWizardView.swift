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
                    VStack(spacing: 18) {
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
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Экстренная помощь")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedCase = item
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: item.iconName)
                                .font(.system(size: 13, weight: .semibold))
                            Text(item.title)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isSelected ? item.accentColor.opacity(0.22) : Color.white.opacity(0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(isSelected ? item.accentColor : Color.white.opacity(0.08), lineWidth: 1.5)
                                )
                        )
                        .foregroundColor(isSelected ? Theme.textPrimary : Theme.textTertiary)
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }
    
    private var caseHeaderCard: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(selectedCase.accentColor.opacity(0.2))
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: selectedCase.iconName)
                        .font(.title2)
                        .foregroundColor(selectedCase.accentColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedCase.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                
                Text(selectedCase.shortDescription)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
                    .lineSpacing(2)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(cornerRadius: 18, strokeColor: selectedCase.accentColor.opacity(0.3))
    }
    
    private var waterEjectEmergencyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundColor(Theme.waterCyan)
                Text("Экстренная звуковая продувка")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Spacer(minLength: 0)
            }
            
            Text("Импульсный низкочастотный резонанс (140–165 Гц) для мгновенного выброса жидкости из сеток динамиков.")
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
                .lineSpacing(2)
            
            if isEjectingWater {
                VStack(spacing: 8) {
                    ProgressView(value: ejectProgress)
                        .tint(Theme.waterCyan)
                    
                    HStack {
                        Text("Выдувание капель... Держите телефон динамиками вниз")
                            .font(.caption2)
                            .foregroundColor(Theme.waterCyan)
                        Spacer(minLength: 0)
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
                            .frame(height: 42)
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(cornerRadius: 18, strokeColor: Theme.waterCyan.opacity(0.3))
    }
    
    private var fatalMistakesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "xmark.octagon.fill")
                    .foregroundColor(Theme.dangerRed)
                Text("Критические ошибки (Не делайте этого!)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.dangerRed)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(selectedCase.deadlyMistakes, id: \.self) { mistake in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.dangerRed.opacity(0.9))
                            .padding(.top, 2)
                        
                        Text(mistake)
                            .font(.system(size: 13))
                            .foregroundColor(Theme.textPrimary)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlass(cornerRadius: 18, strokeColor: Theme.dangerRed.opacity(0.35))
    }
    
    private var rescueStepsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "list.number")
                    .foregroundColor(selectedCase.accentColor)
                Text("Пошаговый план действий")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
            }
            
            VStack(spacing: 12) {
                ForEach(selectedCase.urgentSteps) { step in
                    HStack(alignment: .top, spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(selectedCase.accentColor.opacity(0.2))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(selectedCase.accentColor.opacity(0.35), lineWidth: 1)
                                )
                            Text("\(step.order)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(selectedCase.accentColor)
                        }
                        .padding(.top, 1)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.actionTitle)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Theme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text(step.details)
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textSecondary)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .liquidGlass(cornerRadius: 18, strokeColor: selectedCase.accentColor.opacity(0.18))
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
            pulseOff: 0.15,
            channel: .both
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
