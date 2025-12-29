import Foundation
import SwiftData

@Model
final class DayLog {
    var id: UUID
    var date: Date
    var dayTypeRaw: String
    var cycleWeek: Int?
    var waterIntake: Double  // en litres
    var sleepHours: Double
    var weight: Double?  // en kg

    @Relationship(deleteRule: .cascade) var meals: [MealLog]
    @Relationship(deleteRule: .cascade) var supplements: [SupplementLog]
    @Relationship(deleteRule: .cascade) var advancedSupplements: [AdvancedSupplementLog]

    // Alias pour compatibilité
    var peds: [AdvancedSupplementLog] {
        get { advancedSupplements }
        set { advancedSupplements = newValue }
    }

    var dayType: DayType {
        get { DayType(rawValue: dayTypeRaw) ?? .soir }
        set { dayTypeRaw = newValue.rawValue }
    }

    init(
        date: Date = Date(),
        dayType: DayType = .soir,
        cycleWeek: Int? = nil,
        waterIntake: Double = 0,
        sleepHours: Double = 0,
        weight: Double? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.dayTypeRaw = dayType.rawValue
        self.cycleWeek = cycleWeek
        self.waterIntake = waterIntake
        self.sleepHours = sleepHours
        self.weight = weight
        self.meals = []
        self.supplements = []
        self.advancedSupplements = []
    }

    // MARK: - Computed Properties

    var completedMealsCount: Int {
        meals.filter { $0.isCompleted }.count
    }

    var totalMealsCount: Int {
        meals.count
    }

    var completedSupplementsCount: Int {
        supplements.filter { $0.isCompleted }.count
    }

    var totalSupplementsCount: Int {
        supplements.count
    }

    var completedAdvancedSupplementsCount: Int {
        advancedSupplements.filter { $0.isCompleted }.count
    }

    var totalAdvancedSupplementsCount: Int {
        advancedSupplements.count
    }

    // Alias pour compatibilité
    var completedPEDsCount: Int { completedAdvancedSupplementsCount }
    var totalPEDsCount: Int { totalAdvancedSupplementsCount }

    var waterProgress: Double {
        min(waterIntake / 3.0, 1.0)  // Objectif 3L
    }

    var sleepStatus: SleepStatus {
        if sleepHours >= 7 && sleepHours <= 9 {
            return .optimal
        } else if sleepHours >= 6 && sleepHours < 7 {
            return .acceptable
        } else {
            return .insufficient
        }
    }

    var dailyScore: Double {
        let mealScore = totalMealsCount > 0 ? Double(completedMealsCount) / Double(totalMealsCount) : 0
        let supplementScore = totalSupplementsCount > 0 ? Double(completedSupplementsCount) / Double(totalSupplementsCount) : 0
        let advancedSupplementScore = totalAdvancedSupplementsCount > 0 ? Double(completedAdvancedSupplementsCount) / Double(totalAdvancedSupplementsCount) : 0
        let waterScore = waterProgress
        let sleepScore = sleepStatus == .optimal ? 1.0 : (sleepStatus == .acceptable ? 0.7 : 0.3)

        // Pondération : Repas 40%, Compléments 25%, Suppléments avancés 15%, Eau 10%, Sommeil 10%
        return (mealScore * 0.40) + (supplementScore * 0.25) + (advancedSupplementScore * 0.15) + (waterScore * 0.10) + (sleepScore * 0.10)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: date).capitalized
    }
}

// MARK: - Sleep Status
enum SleepStatus {
    case optimal      // 7-9h
    case acceptable   // 6-7h
    case insufficient // <6h ou >9h

    var color: String {
        switch self {
        case .optimal: return "green"
        case .acceptable: return "orange"
        case .insufficient: return "red"
        }
    }

    var icon: String {
        switch self {
        case .optimal: return "checkmark.circle.fill"
        case .acceptable: return "exclamationmark.circle.fill"
        case .insufficient: return "xmark.circle.fill"
        }
    }
}
