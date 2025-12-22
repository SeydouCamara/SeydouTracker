import SwiftUI

// MARK: - App Constants
enum AppConstants {
    static let appName = "SeydouTracker"
    static let waterGoal: Double = 3.0  // Litres
    static let sleepMinGoal: Double = 7.0  // Heures
    static let sleepMaxGoal: Double = 9.0  // Heures
    static let cycleWeeks = 8
    static let caloriesGoal = 2280
    static let proteinsGoal = 316  // grammes
    static let carbsGoal = 120    // grammes
    static let fatsGoal = 60      // grammes
}

// MARK: - App Colors
extension Color {
    // Couleurs principales
    static let appPrimary = Color(hex: "2E7D32")      // Vert santé
    static let appSecondary = Color(hex: "1565C0")   // Bleu confiance
    static let appAccent = Color(hex: "E65100")      // Orange énergie
    static let appAlert = Color(hex: "C62828")       // Rouge PEDs

    // Couleurs fonctionnelles
    static let appSuccess = Color(hex: "4CAF50")
    static let appWarning = Color(hex: "FF9800")
    static let appError = Color(hex: "F44336")

    // Couleurs de fond
    static let appBackground = Color(UIColor.systemBackground)
    static let appCardBackground = Color(UIColor.secondarySystemBackground)
    static let appGroupedBackground = Color(UIColor.systemGroupedBackground)
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Date Extensions
extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }

    /// Retourne le type de journée par défaut basé sur le jour de la semaine
    var defaultDayType: DayType {
        let weekday = Calendar.current.component(.weekday, from: self)
        switch weekday {
        case 2, 4, 5: return .soir      // Lundi, Mercredi, Jeudi
        case 6: return .midi            // Vendredi
        case 7: return .aprem           // Samedi
        default: return .repos          // Mardi, Dimanche
        }
    }
}
