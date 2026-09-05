import SwiftUI

// MARK: - Режимы очистки динамика
public enum CleaningMode: String, CaseIterable, Identifiable, Sendable, Codable {
    case water = "Вода"
    case dust = "Пыль"
    case pro = "Pro-режим"
    
    public var id: String { rawValue }
    public var title: String { rawValue }
    
    public var subtitle: String {
        switch self {
        case .water:
            return "Water Eject • 140–165 Гц"
        case .dust:
            return "Dust Shaker • 100 Гц – 10 кГц"
        case .pro:
            return "Custom Synth • 20 Гц – 20 кГц"
        }
    }
    
    public var detailedDescription: String {
        switch self {
        case .water:
            return "Генерирует низкочастотные резонансные импульсы (140–165 Гц) в сочетании с мощной тактильной отдачей для преодоления поверхностного натяжения и выталкивания капель воды из акустической камеры."
        case .dust:
            return "Использует высокочастотный свип с меандром и пилообразной волной, богатыми гармониками. Микровибрации акустической мембраны отряхивают сухую пыль и частицы грязи."
        case .pro:
            return "Полный контроль над параметрами звука: точная настройка частоты от 20 Гц до 20 кГц, выбор формы волны (синус, меандр, пила, треугольник) и частоты импульсной модуляции."
        }
    }
    
    public var iconName: String {
        switch self {
        case .water: return "drop.fill"
        case .dust: return "sparkles"
        case .pro: return "slider.horizontal.3"
        }
    }
    
    public var primaryColor: Color {
        switch self {
        case .water: return Theme.waterCyan
        case .dust: return Theme.dustGold
        case .pro: return Theme.proPurple
        }
    }
    
    public var gradient: LinearGradient {
        switch self {
        case .water: return LinearGradient.waterGradient
        case .dust: return LinearGradient.dustGradient
        case .pro: return LinearGradient.proGradient
        }
    }
    
    public var defaultDurationSeconds: Double {
        switch self {
        case .water: return 60.0 // 60 секунд стандартного цикла выталкивания воды
        case .dust: return 75.0  // 75 секунд полного спектрального свипа
        case .pro: return 120.0  // 120 секунд для ручной настройки
        }
    }
}
