import Foundation
import SwiftData

@Model
final class PEDLog {
    var id: UUID
    var pedTypeRaw: String
    var dosage: String
    var isCompleted: Bool
    var completedAt: Date?

    @Relationship(inverse: \DayLog.peds) var dayLog: DayLog?

    var pedType: PEDType {
        get { PEDType(rawValue: pedTypeRaw) ?? .rad140 }
        set { pedTypeRaw = newValue.rawValue }
    }

    init(
        pedType: PEDType,
        dosage: String,
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = UUID()
        self.pedTypeRaw = pedType.rawValue
        self.dosage = dosage
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }

    func toggle() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
    }
}
