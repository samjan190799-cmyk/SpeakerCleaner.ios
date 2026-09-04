import SwiftUI

// MARK: - Экран детального просмотра инструкции базы знаний
public struct GuideDetailView: View {
    public let guide: CleaningGuide
    
    public init(guide: CleaningGuide) {
        self.guide = guide
    }
    
    public var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Шапка инструкции
                    HStack(spacing: 16) {
                        Circle()
                            .fill(guide.accentColor.opacity(0.18))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: guide.iconName)
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(guide.accentColor)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(guide.category.rawValue)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(guide.accentColor)
                                .textCase(.uppercase)
                            
                            Text(guide.title)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Theme.textPrimary)
                        }
                    }
                    .padding(.top, 10)
                    
                    Text(guide.summary)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                        .lineSpacing(4)
                    
                    // Блок критических предупреждений (если есть)
                    if !guide.warnings.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Theme.dangerRed)
                                Text("Важные предостережения")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Theme.dangerRed)
                            }
                            
                            ForEach(guide.warnings, id: \.self) { warning in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundColor(Theme.dangerRed)
                                    Text(warning)
                                        .font(.system(size: 13))
                                        .foregroundColor(Theme.textPrimary)
                                }
                            }
                        }
                        .padding(14)
                        .liquidGlass(cornerRadius: 16, strokeColor: Theme.dangerRed.opacity(0.4))
                    }
                    
                    // Пошаговый список
                    Text("Пошаговые действия")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                        .padding(.top, 8)
                    
                    VStack(spacing: 14) {
                        ForEach(guide.steps) { step in
                            HStack(alignment: .top, spacing: 14) {
                                // Номер шага
                                ZStack {
                                    Circle()
                                        .fill(guide.accentColor.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    Text("\(step.stepNumber)")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(guide.accentColor)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(step.title)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Theme.textPrimary)
                                    
                                    Text(step.description)
                                        .font(.system(size: 13))
                                        .foregroundColor(Theme.textSecondary)
                                        .lineSpacing(2)
                                    
                                    if let tip = step.tip {
                                        Text("Совет: \(tip)")
                                            .font(.system(size: 12))
                                            .foregroundColor(guide.accentColor)
                                            .padding(.top, 2)
                                    }
                                }
                            }
                            .padding(14)
                            .liquidGlass(cornerRadius: 16)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
