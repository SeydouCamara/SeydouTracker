import Foundation
import SwiftData

@Model
final class SupplementLog {
    var id: UUID
    var supplementTypeRaw: String
    var timingSlotRaw: String
    var isCompleted: Bool
    var completedAt: Date?

    @Relationship(inverse: \DayLog.supplements) var dayLog: DayLog?

    var supplementType: SupplementType {
        get { SupplementType(rawValue: supplementTypeRaw) ?? .zinc }
        set { supplementTypeRaw = newValue.rawValue }
    }

    var timingSlot: TimingSlot {
        get { TimingSlot(rawValue: timingSlotRaw) ?? .matin }
        set { timingSlotRaw = newValue.rawValue }
    }

    init(
        supplementType: SupplementType,
        timingSlot: TimingSlot,
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = UUID()
        self.supplementTypeRaw = supplementType.rawValue
        self.timingSlotRaw = timingSlot.rawValue
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }

    func toggle() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
    }
}
