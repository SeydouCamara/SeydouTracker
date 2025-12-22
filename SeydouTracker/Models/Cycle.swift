import Foundation
import SwiftData

@Model
final class Cycle {
    var id: UUID
    var startDate: Date
    var endDate: Date
    var isActive: Bool

    init(
        startDate: Date = Date(),
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.startDate = startDate
        // Cycle de 8 semaines
        self.endDate = Calendar.current.date(byAdding: .weekOfYear, value: 8, to: startDate) ?? startDate
        self.isActive = isActive
    }

    // MARK: - Computed Properties

    /// Semaine actuelle du cycle (1-8)
    var currentWeek: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: Date())
        let days = components.day ?? 0
        let week = (days / 7) + 1
        return min(max(week, 1), 8)
    }

    /// Jour actuel dans le cycle (1-56)
    var currentDay: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: Date())
        return min(max((components.day ?? 0) + 1, 1), 56)
    }

    /// Progression du cycle (0.0 - 1.0)
    var progress: Double {
        return Double(currentDay) / 56.0
    }

    /// Jours restants
    var daysRemaining: Int {
        return max(56 - currentDay, 0)
    }

    /// Est-ce que le cycle est terminé ?
    var isCompleted: Bool {
        return Date() >= endDate
    }

    /// Date formatée du début
    var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: startDate)
    }

    /// Date formatée de fin
    var formattedEndDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: endDate)
    }

    /// Dates des bilans sanguins recommandés
    var bloodWorkDates: [(week: Int, date: Date, label: String)] {
        let calendar = Calendar.current
        return [
            (4, calendar.date(byAdding: .weekOfYear, value: 4, to: startDate)!, "Bilan S4 (mi-cycle)"),
            (8, calendar.date(byAdding: .weekOfYear, value: 8, to: startDate)!, "Bilan S8 (fin cycle)"),
            (12, calendar.date(byAdding: .weekOfYear, value: 12, to: startDate)!, "Bilan S12 (post-cycle)")
        ]
    }
}
