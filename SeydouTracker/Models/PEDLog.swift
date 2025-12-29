import Foundation
import SwiftData

@Model
final class AdvancedSupplementLog {
    var id: UUID
    var supplementTypeRaw: String
    var dosage: String
    var isCompleted: Bool
    var completedAt: Date?

    @Relationship(inverse: \DayLog.advancedSupplements) var dayLog: DayLog?

    var supplementType: AdvancedSupplementType {
        get { AdvancedSupplementType(rawValue: supplementTypeRaw) ?? .rad140 }
        set { supplementTypeRaw = newValue.rawValue }
    }

    // Alias pour compatibilité
    var pedType: AdvancedSupplementType {
        get { supplementType }
        set { supplementType = newValue }
    }

    init(
        supplementType: AdvancedSupplementType,
        dosage: String,
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = UUID()
        self.supplementTypeRaw = supplementType.rawValue
        self.dosage = dosage
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }

    // Convenience initializer pour compatibilité
    convenience init(
        pedType: AdvancedSupplementType,
        dosage: String,
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.init(supplementType: pedType, dosage: dosage, isCompleted: isCompleted, completedAt: completedAt)
    }

    func toggle() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
    }
}

// Alias pour compatibilité
typealias PEDLog = AdvancedSupplementLog
