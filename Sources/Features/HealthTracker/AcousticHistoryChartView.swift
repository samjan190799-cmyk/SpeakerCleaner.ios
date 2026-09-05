import SwiftUI
import Charts

// MARK: - Экран интерактивного графика акустического здоровья (Swift Charts, iOS 16+)
public struct AcousticHistoryChartView: View {
    @State private var historyManager = CleaningHistoryManager.shared
    @State private var selectedEntry: CleaningLogEntry?
    @State private var selectedTimeFilter: Int = 0 // 0: Все, 1: Очистка, 2: Тесты
    
    public init() {}
    
    private var filteredEntries: [CleaningLogEntry] {
        switch selectedTimeFilter {
        case 1:
            return historyManager.entries.filter { $0.logType == .cleaningSession }
        case 2:
            return historyManager.entries.filter { $0.logType == .spectralDiagnostic }
        default:
            return historyManager.entries
        }
    }
    
    // Хронологический порядок для графика (слева направо от старых к новым)
    private var chronologicalEntries: [CleaningLogEntry] {
        filteredEntries.reversed()
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Метрики состояния
            summaryStatsHeader
            
            // Фильтр по типам записей
            filterSegmentBar
            
            // Интерактивный график Swift Charts
            chartCard
            
            // Журнал недавних процедур
            recentEntriesList
        }
    }
    
    // MARK: - Сводная статистика
    
    private var summaryStatsHeader: some View {
        HStack(spacing: 12) {
            statMetricCard(
                title: "Индекс звука",
                value: "\(historyManager.averageCleanliness)%",
                icon: "waveform.badge.magnifyingglass",
                color: Theme.waterCyan
            )
            
            statMetricCard(
                title: "Процедур",
                value: "\(historyManager.entries.count)",
                icon: "sparkles",
                color: Theme.dustGold
            )
            
            statMetricCard(
                title: "Статус",
                value: historyManager.averageCleanliness >= 80 ? "Идеал" : "Норма",
                icon: "shield.lefthalf.filled",
                color: Theme.successGreen
            )
        }
    }
    
    private func statMetricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                Spacer()
            }
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .liquidGlass(cornerRadius: 16)
    }
    
    // MARK: - Переключатель фильтра
    
    private var filterSegmentBar: some View {
        HStack(spacing: 8) {
            filterButton(title: "Все (\(historyManager.entries.count))", index: 0)
            filterButton(title: "Очистка", index: 1)
            filterButton(title: "Тесты FFT", index: 2)
        }
    }
    
    private func filterButton(title: String, index: Int) -> some View {
        let isSelected = selectedTimeFilter == index
        return Button {
            HapticFeedback.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedTimeFilter = index
                selectedEntry = nil
            }
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(
                    Capsule()
                        .fill(isSelected ? Theme.waterCyan.opacity(0.2) : Color.white.opacity(0.04))
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Theme.waterCyan.opacity(0.8) : Color.clear, lineWidth: 1)
                        )
                )
                .foregroundColor(isSelected ? Theme.textPrimary : Theme.textTertiary)
        }
    }
    
    // MARK: - График Swift Charts
    
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Динамика чистоты звучания")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Text("Коэффициент акустической прозрачности (0–100%)")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                
                if let selected = selectedEntry {
                    Text("\(selected.cleanlinessScore)%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.waterCyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.waterCyan.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            
            if chronologicalEntries.count >= 2 {
                Chart {
                    ForEach(chronologicalEntries) { item in
                        // Градиентная заливка под графиком
                        AreaMark(
                            x: .value("Дата", item.timestamp),
                            y: .value("Чистота", item.cleanlinessScore)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Theme.waterCyan.opacity(0.35),
                                    Theme.waterCyan.opacity(0.02)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        // Основная линия графика
                        LineMark(
                            x: .value("Дата", item.timestamp),
                            y: .value("Чистота", item.cleanlinessScore)
                        )
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .foregroundStyle(Theme.waterCyan)
                        
                        // Точки на линии
                        PointMark(
                            x: .value("Дата", item.timestamp),
                            y: .value("Чистота", item.cleanlinessScore)
                        )
                        .symbol(Circle())
                        .symbolSize(selectedEntry?.id == item.id ? 80 : 35)
                        .foregroundStyle(selectedEntry?.id == item.id ? Theme.dustGold : Theme.waterCyan)
                    }
                }
                .chartYScale(domain: 50...100)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(Color.white.opacity(0.1))
                        AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.2))
                        AxisValueLabel(format: .dateTime.day().month(.defaultDigits))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: [60, 80, 100]) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                            .foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel {
                            if let intVal = value.as(Int.self) {
                                Text("\(intVal)%")
                                    .font(.caption2)
                                    .foregroundColor(Theme.textTertiary)
                            }
                        }
                    }
                }
                .frame(height: 180)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.largeTitle)
                        .foregroundColor(Theme.textTertiary)
                    Text("Недостаточно данных для графика")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    Text("Запустите очистку или спектральный тест для накопления истории.")
                        .font(.caption2)
                        .foregroundColor(Theme.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
            }
        }
        .padding(18)
        .liquidGlass(cornerRadius: 20)
    }
    
    // MARK: - Список недавних процедур
    
    private var recentEntriesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("История процедур")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            
            if filteredEntries.isEmpty {
                Text("Записей пока нет")
                    .font(.caption)
                    .foregroundColor(Theme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 10) {
                    ForEach(filteredEntries) { entry in
                        logEntryRow(entry: entry)
                    }
                }
            }
        }
    }
    
    private func logEntryRow(entry: CleaningLogEntry) -> some View {
        let isCleaning = entry.logType == .cleaningSession
        let iconColor = isCleaning ? Theme.waterCyan : Theme.dustGold
        let icon = isCleaning ? "sparkles" : "waveform.badge.mic"
        
        return Button {
            HapticFeedback.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedEntry = entry
            }
        } label: {
            HStack(spacing: 12) {
                // Иконка типа процедуры
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(iconColor)
                    )
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(entry.modeTitle)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        
                        Text(entry.channel.shortTitle)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                            .foregroundColor(Theme.textSecondary)
                    }
                    
                    Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(Theme.textTertiary)
                }
                
                Spacer()
                
                // Бейдж чистоты
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(entry.cleanlinessScore)%")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(iconColor)
                    Text("чистота")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textTertiary)
                }
            }
            .padding(12)
            .background(selectedEntry?.id == entry.id ? iconColor.opacity(0.12) : Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selectedEntry?.id == entry.id ? iconColor.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
    }
}
