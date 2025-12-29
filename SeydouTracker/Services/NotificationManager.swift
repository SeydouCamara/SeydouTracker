import Foundation
import UserNotifications
import SwiftUI

@Observable
class NotificationManager {
    static let shared = NotificationManager()

    var isAuthorized = false
    var pendingNotifications: [UNNotificationRequest] = []

    private init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Schedule Notifications

    func scheduleAllNotifications() {
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else {
            cancelAllNotifications()
            return
        }

        // Récupérer les heures configurées
        let morningTime = UserDefaults.standard.object(forKey: "morningReminderTime") as? Date ?? defaultMorningTime
        let eveningTime = UserDefaults.standard.object(forKey: "eveningReminderTime") as? Date ?? defaultEveningTime

        // Annuler les anciennes notifications
        cancelAllNotifications()

        // Programmer les nouvelles
        scheduleMorningNotifications(at: morningTime)
        scheduleEveningNotifications(at: eveningTime)
        scheduleSupplementReminder(at: morningTime)
        scheduleWaterReminders()
    }

    // MARK: - Morning Notifications

    private func scheduleMorningNotifications(at time: Date) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)

        // Notification Suppléments + Compléments matin
        let content = UNMutableNotificationContent()
        content.title = "Bonjour Seydou ! 💪"
        content.body = "N'oublie pas tes suppléments et compléments du matin."
        content.sound = .default
        content.badge = 1

        var trigger = DateComponents()
        trigger.hour = components.hour
        trigger.minute = components.minute

        let request = UNNotificationRequest(
            identifier: "morning-reminder",
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: trigger, repeats: true)
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Evening Notifications

    private func scheduleEveningNotifications(at time: Date) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)

        // Notification bilan journée
        let content = UNMutableNotificationContent()
        content.title = "Bilan de la journée 📊"
        content.body = "As-tu bien tracké tous tes repas et compléments aujourd'hui ?"
        content.sound = .default

        var trigger = DateComponents()
        trigger.hour = components.hour
        trigger.minute = components.minute

        let request = UNNotificationRequest(
            identifier: "evening-reminder",
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: trigger, repeats: true)
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Supplement Reminder

    private func scheduleSupplementReminder(at morningTime: Date) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: morningTime)
        // 30 minutes après le réveil
        components.minute = (components.minute ?? 0) + 30

        let content = UNMutableNotificationContent()
        content.title = "Suppléments du jour 💊"
        content.body = "Pense à prendre tes suppléments : RAD-140, Cardarine, Albuterol"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "supplement-reminder",
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        )

        UNUserNotificationCenter.current().add(request)
    }

    // Alias pour compatibilité
    private func schedulePEDReminder(at morningTime: Date) {
        scheduleSupplementReminder(at: morningTime)
    }

    // MARK: - Water Reminders

    private func scheduleWaterReminders() {
        // Rappels toutes les 2 heures entre 8h et 20h
        let waterHours = [10, 12, 14, 16, 18]

        for hour in waterHours {
            let content = UNMutableNotificationContent()
            content.title = "Hydratation 💧"
            content.body = "Pense à boire de l'eau ! Objectif : 3L/jour"
            content.sound = .default

            var trigger = DateComponents()
            trigger.hour = hour
            trigger.minute = 0

            let request = UNNotificationRequest(
                identifier: "water-reminder-\(hour)",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: trigger, repeats: true)
            )

            UNUserNotificationCenter.current().add(request)
        }
    }

    // MARK: - Meal Reminders

    func scheduleMealReminder(mealType: MealType, scheduledTime: String, dayType: DayType) {
        // Parser l'heure du repas
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        guard let time = formatter.date(from: scheduledTime) else { return }

        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: time)
        // 15 minutes avant le repas
        if let minute = components.minute {
            components.minute = minute - 15
        }

        let content = UNMutableNotificationContent()
        content.title = "Repas \(mealType.displayName) 🍽️"
        content.body = "Prépare ton repas : \(mealType.content.prefix(50))..."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "meal-\(mealType.rawValue)",
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Blood Work Reminder

    func scheduleBloodWorkReminder(week: Int, date: Date) {
        // Rappel 2 jours avant
        let reminderDate = Calendar.current.date(byAdding: .day, value: -2, to: date)!

        let content = UNMutableNotificationContent()
        content.title = "Bilan sanguin S\(week) 🩸"
        content.body = "N'oublie pas ton bilan sanguin dans 2 jours !"
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: reminderDate)

        let request = UNNotificationRequest(
            identifier: "bloodwork-s\(week)",
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Cancel Notifications

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: - Get Pending Notifications

    func getPendingNotifications() async -> [UNNotificationRequest] {
        await UNUserNotificationCenter.current().pendingNotificationRequests()
    }

    // MARK: - Helpers

    private var defaultMorningTime: Date {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    private var defaultEveningTime: Date {
        var components = DateComponents()
        components.hour = 21
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    // MARK: - Badge Management

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    func setBadge(count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count)
    }
}
