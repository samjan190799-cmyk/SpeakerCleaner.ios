import SwiftUI

// MARK: - Экран чек-листа гигиены и индекса заботы о гаджете (Care Score)
public struct CareChecklistView: View {
    @State private var items: [CareChecklistItem] = CareChecklistData.initialItems
    
    public init() {}
    
    private var careScore: Int {
        guard !items.isEmpty else { return 0 }
        let completedCount = items.filter { $0.isCompleted }.count
        return Int((Double(completedCount) / Double(items.count)) * 100)
    }
    
    private var scoreColor: Color {
        switch careScore {
        case 80...100: return Theme.successGreen
        case 50...79: return Theme.waterCyan
        case 20...49: return Theme.warningYellow
        default: return Theme.dangerRed
        }
    }
    
    private var scoreDescription: String {
        switch careScore {
        case 100: return "Идеальное состояние устройства! Все узлы обслужены."
        case 80...99: return "Отличный уровень заботы. Смартфон прослужит долго."
        case 50...79: return "Хорошо, но пара важных процедур ухода пропущена."
        default: return "Устройство нуждается в базовой гигиенической чистке."
        }
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Карточка общего индекса заботы
            scoreCard
            
            // Список процедур чек-листа
            VStack(spacing: 12) {
                ForEach($items) { $item in
                    checklistRow(item: $item)
                }
            }
        }
    }
    
    private var scoreCard: some View {
        HStack(spacing: 18) {
            // Круговой датчик
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 8)
                Circle()
                    .trim(from: 0.0, to: CGFloat(careScore) / 100.0)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: careScore)
                
                Text("\(careScore)%")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
            }
            .frame(width: 76, height: 76)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Индекс заботы о гаджете")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                
                Text(scoreDescription)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(18)
        .liquidGlass(cornerRadius: 20, strokeColor: scoreColor.opacity(0.35))
    }
    
    private func checklistRow(item: Binding<CareChecklistItem>) -> some View {
        Button {
            HapticFeedback.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                item.wrappedValue.isCompleted.toggle()
                if item.wrappedValue.isCompleted {
                    item.wrappedValue.lastCompletedDate = Date()
                }
            }
            if careScore == 100 {
                HapticFeedback.notification(.success)
            }
        } label: {
            HStack(spacing: 14) {
                // Чекбокс
                ZStack {
                    Circle()
                        .fill(item.wrappedValue.isCompleted ? item.wrappedValue.iconColor : Color.white.opacity(0.06))
                        .frame(width: 28, height: 28)
                    
                    if item.wrappedValue.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
                
                // Иконка категории
                Image(systemName: item.wrappedValue.iconName)
                    .font(.system(size: 16))
                    .foregroundColor(item.wrappedValue.iconColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.wrappedValue.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(item.wrappedValue.isCompleted ? Theme.textPrimary : Theme.textSecondary)
                    
                    Text("Рекомендовано каждые \(item.wrappedValue.recommendedIntervalDays) дн.")
                        .font(.caption2)
                        .foregroundColor(Theme.textTertiary)
                }
                
                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(item.wrappedValue.isCompleted ? item.wrappedValue.iconColor.opacity(0.12) : Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(item.wrappedValue.isCompleted ? item.wrappedValue.iconColor.opacity(0.3) : Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
    }
}
