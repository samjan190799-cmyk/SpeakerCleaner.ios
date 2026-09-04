import SwiftUI

// MARK: - Сценарии экстренной помощи при инцидентах
public struct EmergencyCase: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let shortDescription: String
    public let iconName: String
    public let accentColor: Color
    public let requiresWaterEject: Bool
    public let urgentSteps: [EmergencyStep]
    public let deadlyMistakes: [String]
}

public struct EmergencyStep: Identifiable, Sendable {
    public let id = UUID()
    public let order: Int
    public let actionTitle: String
    public let details: String
    public let isActionable: Bool
}

// MARK: - Предустановленные экстренные сценарии
public enum EmergencyData {
    public static let cases: [EmergencyCase] = [
        EmergencyCase(
            id: "water-fresh",
            title: "Уронил в пресную воду",
            shortDescription: "Ванна, раковина, лужа, стакан с водой.",
            iconName: "drop.fill",
            accentColor: Theme.waterCyan,
            requiresWaterEject: true,
            urgentSteps: [
                EmergencyStep(
                    order: 1,
                    actionTitle: "Немедленно извлеките и выключите",
                    details: "Чем меньше телефон находится под напряжением с влагой внутри, тем ниже риск электролиза и короткого замыкания.",
                    isActionable: false
                ),
                EmergencyStep(
                    order: 2,
                    actionTitle: "Снимите чехол и протрите корпус микрофиброй",
                    details: "Чехол задерживает воду вокруг разъемов и динамиков. Насухо сотрите капли с решеток.",
                    isActionable: false
                ),
                EmergencyStep(
                    order: 3,
                    actionTitle: "Поставьте динамиками вниз",
                    details: "Расположите устройство вертикально динамиками вниз, слегка постучите по ладони, чтобы стряхнуть капли из акустической камеры.",
                    isActionable: false
                ),
                EmergencyStep(
                    order: 4,
                    actionTitle: "Запустите выталкивание звуком (Water Eject)",
                    details: "Включите режим «Вода» на 100% громкости. Резонанс 140–165 Гц выбьет остатки влаги из сеток спикеров.",
                    isActionable: true
                ),
                EmergencyStep(
                    order: 5,
                    actionTitle: "Оставьте на просушку минимум на 4–6 часов",
                    details: "Положите смартфон в хорошо проветриваемое сухое место. Не подключайте зарядный кабель!",
                    isActionable: false
                )
            ],
            deadlyMistakes: [
                "НЕ СТАВЬТЕ НА ЗАРЯДКУ — электрический ток в присутствии влаги моментально растворит медные дорожки.",
                "НЕ КЛАДИТЕ В РИС — рисовый крахмал образует цементирующую кашу в разъемах и динамиках.",
                "НЕ СУШИТЕ ГОРЯЧИМ ФЕНОМ — фен плавит водозащитный клей и задувает влагу глубже на материнскую плату."
            ]
        ),
        
        EmergencyCase(
            id: "water-salt",
            title: "Морская вода или бассейн",
            shortDescription: "Соленая морская вода, хлорированный бассейн.",
            iconName: "water.waves",
            accentColor: Color(hex: "0077B6"),
            requiresWaterEject: true,
            urgentSteps: [
                EmergencyStep(
                    order: 1,
                    actionTitle: "Немедленно выключите устройство",
                    details: "Морская соль обладает колоссальной электропроводностью. Секунды решают сохранность чипов.",
                    isActionable: false
                ),
                EmergencyStep(
                    order: 2,
                    actionTitle: "Быстро промойте пресной или дистиллированной водой",
                    details: "Если не смыть соль, кристаллы высохнут на мембране динамика и разорвут ее, а металлы разъема окислятся за несколько часов.",
                    isActionable: false
                ),
                EmergencyStep(
                    order: 3,
                    actionTitle: "Удалите влагу и запустите звуковую чистку",
                    details: "Тщательно промокните телефон салфеткой и активируйте импульсный Water Eject на максимальной громкости.",
                    isActionable: true
                ),
                EmergencyStep(
                    order: 4,
                    actionTitle: "Обратитесь в сервис для вскрытия и отмывки в УЗ-ванне",
                    details: "Морская вода практически всегда требует профессиональной ультразвуковой чистки материнской платы изопропиловым спиртом.",
                    isActionable: false
                )
            ],
            deadlyMistakes: [
                "Не оставляйте телефон сохнуть с солью внутри без предварительного смыва пресной водой.",
                "Не пытайтесь заряжать даже через беспроводную зарядку до полной ревизии разъемов."
            ]
        ),
        
        EmergencyCase(
            id: "beverage",
            title: "Пролил чай, кофе или сладкую газировку",
            shortDescription: "Липкие напитки с сахаром, кислотами и молоком.",
            iconName: "cup.and.saucer.fill",
            accentColor: Color(hex: "FB8500"),
            requiresWaterEject: true,
            urgentSteps: [
                EmergencyStep(
                    order: 1,
                    actionTitle: "Выключите питание и снимите чехол",
                    details: "Сахар и кислоты вызывают коррозию быстрее чистой воды, а при высыхании намертво склеивают диффузор динамика.",
                    isActionable: false
                ),
                EmergencyStep(
                    order: 2,
                    actionTitle: "Удалите липкий налет влажной салфеткой с дистиллятом",
                    details: "Аккуратно сотрите сладкую пленку с корпуса и решеток, пока она не кристаллизовалась.",
                    isActionable: false
                ),
                EmergencyStep(
                    order: 3,
                    actionTitle: "Запустите звуковую продувку динамиков",
                    details: "Звуковые колебания не дадут сахару застыть на тонкой полимерной мембране акустического излучателя.",
                    isActionable: true
                )
            ],
            deadlyMistakes: [
                "Не давайте сладкому напитку высохнуть внутри — застывший сахар обездвижит мембрану, и динамик навсегда потеряет громкость."
            ]
        ),
        
        EmergencyCase(
            id: "overheating",
            title: "Критический перегрев (Нагрелся как утюг)",
            shortDescription: "Солнцепек в машине, тяжелая игра на зарядке.",
            iconName: "flame.fill",
            accentColor: Theme.dangerRed,
            requiresWaterEject: false,
            urgentSteps: [
                EmergencyStep(
                    order: 1,
                    actionTitle: "Снимите чехол и отключите зарядку",
                    details: "Чехол задерживает тепло. Снятие чехла увеличивает рассеивание тепла корпусом в 3 раза.",
                    isActionable: false
                ),
                EmergencyStep(
                    order: 2,
                    actionTitle: "Переместите телефон в прохладную тень",
                    details: "Уберите устройство от прямых солнечных лучей и выключите требовательные приложения.",
                    isActionable: false
                ),
                EmergencyStep(
                    order: 3,
                    actionTitle: "Дайте остыть естественным путем 15–20 минут",
                    details: "Не трогайте экран и не перезагружайте до тех пор, пока корпус не станет комнатной температуры.",
                    isActionable: false
                )
            ],
            deadlyMistakes: [
                "КАТЕГОРИЧЕСКИ ЗАПРЕЩЕНО класть горячий телефон в морозилку или холодильник! Из-за резкого перепада температур внутри корпуса мгновенно выпадет конденсат воды прямо на микросхемы."
            ]
        ),
        
        EmergencyCase(
            id: "dust-sand",
            title: "Уронил в песок или строительную пыль",
            shortDescription: "Пляж, цементная или гипсовая пыль, опилки.",
            iconName: "sparkles",
            accentColor: Theme.dustGold,
            requiresWaterEject: false,
            urgentSteps: [
                EmergencyStep(
                    order: 1,
                    actionTitle: "Не дуйте ртом в отверстия",
                    details: "Дыхание содержит влагу. Песок и цемент от влаги слипнутся в комочки и забьют сетку намертво.",
                    isActionable: false
                ),
                EmergencyStep(
                    order: 2,
                    actionTitle: "Смахните внешний песок ультрамягкой сухой щеткой",
                    details: "Держите телефон под углом 45° и легкими смахивающими движениями снимите песчинки.",
                    isActionable: false
                ),
                EmergencyStep(
                    order: 3,
                    actionTitle: "Запустите режим «Пыль» (Dust Shaker)",
                    details: "Частотный свип с меандром создаст микровибрации, сбрасывающие песчинки с мембраны.",
                    isActionable: true
                )
            ],
            deadlyMistakes: [
                "Не трите экран футболкой с песком — песчинки кварца тверже стекла и оставят глубокие борозды."
            ]
        )
    ]
}
