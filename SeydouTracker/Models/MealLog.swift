import Foundation
import SwiftData

@Model
final class MealLog {
    var id: UUID
    var mealTypeRaw: String
    var scheduledTime: String
    var isCompleted: Bool
    var completedAt: Date?

    @Relationship(inverse: \DayLog.meals) var dayLog: DayLog?

    var mealType: MealType {
        get { MealType(rawValue: mealTypeRaw) ?? .repas1 }
        set { mealTypeRaw = newValue.rawValue }
    }

    init(
        mealType: MealType,
        scheduledTime: String,
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = UUID()
        self.mealTypeRaw = mealType.rawValue
        self.scheduledTime = scheduledTime
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }

    func toggle() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
    }
}
