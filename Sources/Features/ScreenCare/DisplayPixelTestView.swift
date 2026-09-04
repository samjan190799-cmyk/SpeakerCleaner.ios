import SwiftUI

// MARK: - Тест матрицы дисплея на битые пиксели и выгорание (Display Pixel & OLED Test)
public struct DisplayPixelTestView: View {
    @Environment(\.dismiss) private var dismiss
    
    public struct TestColor: Identifiable {
        public let id = UUID()
        public let name: String
        public let color: Color
        public let purpose: String
        public let isDark: Bool
    }
    
    private let testColors: [TestColor] = [
        TestColor(name: "Чистый белый", color: .white, purpose: "Проверка на темные битые пиксели, пылинки под стеклом и равномерность подсветки.", isDark: false),
        TestColor(name: "Истинный черный", color: .black, purpose: "Проверка OLED-матрицы на остаточное свечение, паразитные пиксели и засветы.", isDark: true),
        TestColor(name: "Красный (Red)", color: Color(red: 1.0, green: 0.0, blue: 0.0), purpose: "Тест красных субпикселей на деградацию и залипание.", isDark: true),
        TestColor(name: "Зеленый (Green)", color: Color(red: 0.0, green: 1.0, blue: 0.0), purpose: "Тест зеленых субпикселей (наиболее заметных человеческому глазу).", isDark: false),
        TestColor(name: "Синий (Blue)", color: Color(red: 0.0, green: 0.0, blue: 1.0), purpose: "Тест синих субпикселей (самый уязвимый к выгоранию компонент в OLED).", isDark: true),
        TestColor(name: "Нейтральный серый (50%)", color: Color(white: 0.5), purpose: "Выявление эффекта 'грязного экрана' (Dirty Screen Effect) и полос бандинга.", isDark: true),
        TestColor(name: "Желтый", color: Color.yellow, purpose: "Комплексный тест смеси красного и зеленого субпикселей.", isDark: false),
        TestColor(name: "Бирюзовый (Cyan)", color: Color.cyan, purpose: "Тест смеси зеленого и синего каналов.", isDark: false),
        TestColor(name: "Пурпурный (Magenta)", color: Color(hex: "FF007F"), purpose: "Тест смеси красного и синего субпикселей.", isDark: true)
    ]
    
    @State private var currentIndex: Int = 0
    @State private var showControls: Bool = true
    
    public init() {}
    
    private var currentColor: TestColor {
        testColors[currentIndex]
    }
    
    public var body: some View {
        ZStack {
            // Полноэкранная цветовая заливка
            currentColor.color
                .ignoresSafeArea()
                .onTapGesture {
                    nextColor()
                }
            
            // Плавающий HUD подсказок
            if showControls {
                VStack {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(currentColor.isDark ? .white.opacity(0.8) : .black.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Text("\(currentIndex + 1) из \(testColors.count)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(currentColor.isDark ? Color.white.opacity(0.2) : Color.black.opacity(0.1))
                            )
                            .foregroundColor(currentColor.isDark ? .white : .black)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Информационная плашка внизу
                    VStack(spacing: 6) {
                        Text(currentColor.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(currentColor.isDark ? .white : .black)
                        
                        Text(currentColor.purpose)
                            .font(.system(size: 13))
                            .foregroundColor(currentColor.isDark ? .white.opacity(0.8) : .black.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                        
                        Text("Нажмите в любом месте для следующего цвета")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(currentColor.isDark ? Theme.waterCyan : Color.blue)
                            .padding(.top, 4)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(currentColor.isDark ? Color.black.opacity(0.6) : Color.white.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(currentColor.isDark ? Color.white.opacity(0.15) : Color.black.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .transition(.opacity)
            }
        }
        .statusBarHidden(true)
    }
    
    private func nextColor() {
        HapticFeedback.selection()
        withAnimation(.easeInOut(duration: 0.15)) {
            currentIndex = (currentIndex + 1) % testColors.count
        }
    }
}
