import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allDayLogs: [DayLog]
    @Query private var allCycles: [Cycle]

    @State private var notificationsEnabled = false
    @State private var morningReminderTime = Date()
    @State private var eveningReminderTime = Date()
    @State private var showingResetAlert = false
    @State private var showingResetCycleAlert = false
    @State private var showingDeleteDataAlert = false
    @State private var showingPermissionAlert = false
    @State private var pendingNotificationsCount = 0
    @State private var hideAdvancedSupplements = false

    private let notificationManager = NotificationManager.shared

    var body: some View {
        NavigationStack {
            List {
                // Section Notifications
                Section {
                    Toggle(isOn: $notificationsEnabled) {
                        SettingsRow(
                            icon: "bell.fill",
                            iconColor: .appPrimary,
                            title: "Notifications"
                        )
                    }
                    .tint(.appPrimary)
                    .onChange(of: notificationsEnabled) { _, newValue in
                        handleNotificationToggle(newValue)
                    }

                    if notificationsEnabled {
                        DatePicker(selection: $morningReminderTime, displayedComponents: .hourAndMinute) {
                            SettingsRow(
                                icon: "sunrise.fill",
                                iconColor: .orange,
                                title: "Rappel matin"
                            )
                        }
                        .onChange(of: morningReminderTime) { _, _ in
                            saveAndScheduleNotifications()
                        }

                        DatePicker(selection: $eveningReminderTime, displayedComponents: .hourAndMinute) {
                            SettingsRow(
                                icon: "moon.fill",
                                iconColor: .indigo,
                                title: "Rappel soir"
                            )
                        }
                        .onChange(of: eveningReminderTime) { _, _ in
                            saveAndScheduleNotifications()
                        }

                        // Info sur les notifications programmées
                        HStack {
                            SettingsRow(
                                icon: "clock.fill",
                                iconColor: .appSecondary,
                                title: "Notifications actives"
                            )
                            Spacer()
                            Text("\(pendingNotificationsCount)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    if notificationsEnabled {
                        Text("Tu recevras des rappels pour : suppléments (matin), repas, hydratation, et bilan du soir.")
                    } else {
                        Text("Active les notifications pour ne rien oublier.")
                    }
                }

                // Section Cycle (masquée si suppléments cachés)
                if !hideAdvancedSupplements {
                    Section {
                        Button(action: { showingResetCycleAlert = true }) {
                            SettingsRow(
                                icon: "arrow.clockwise",
                                iconColor: .appSecondary,
                                title: "Nouveau cycle",
                                subtitle: "Démarre un nouveau cycle de 8 semaines"
                            )
                        }

                        if let activeCycle = allCycles.first(where: { $0.isActive }) {
                            HStack {
                                SettingsRow(
                                    icon: "calendar",
                                    iconColor: .appPrimary,
                                    title: "Cycle actuel"
                                )
                                Spacer()
                                Text("Semaine \(activeCycle.currentWeek)/8")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } header: {
                        Text("Cycle Suppléments")
                    }
                }

                // Section Affichage Suppléments
                Section {
                    Toggle(isOn: $hideAdvancedSupplements) {
                        SettingsRow(
                            icon: "eye.slash.fill",
                            iconColor: .appAlert,
                            title: "Masquer les suppléments"
                        )
                    }
                    .tint(.appAlert)
                    .onChange(of: hideAdvancedSupplements) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: "hideAdvancedSupplements")
                    }
                } header: {
                    Text("Affichage")
                } footer: {
                    Text("Masque la section suppléments (RAD-140, Cardarine, etc.) de la vue Aujourd'hui et du cycle.")
                }

                // Section Données
                Section {
                    Button(action: { showingResetAlert = true }) {
                        SettingsRow(
                            icon: "arrow.counterclockwise",
                            iconColor: .appWarning,
                            title: "Reset journée",
                            subtitle: "Réinitialise les données d'aujourd'hui"
                        )
                    }

                    Button(action: { showingDeleteDataAlert = true }) {
                        SettingsRow(
                            icon: "trash.fill",
                            iconColor: .appError,
                            title: "Supprimer tout",
                            subtitle: "Efface toutes les données de l'app"
                        )
                    }
                } header: {
                    Text("Données")
                } footer: {
                    Text("Attention : ces actions sont irréversibles.")
                }

                // Section Statistiques
                Section {
                    HStack {
                        SettingsRow(
                            icon: "chart.bar.fill",
                            iconColor: .appSecondary,
                            title: "Jours trackés"
                        )
                        Spacer()
                        Text("\(allDayLogs.count)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.appPrimary)
                    }

                    HStack {
                        SettingsRow(
                            icon: "flame.fill",
                            iconColor: .orange,
                            title: "Score moyen"
                        )
                        Spacer()
                        Text("\(averageScore)%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(scoreColor)
                    }

                    if let firstDate = allDayLogs.map(\.date).min() {
                        HStack {
                            SettingsRow(
                                icon: "calendar.badge.clock",
                                iconColor: .appPrimary,
                                title: "Début tracking"
                            )
                            Spacer()
                            Text(formatDate(firstDate))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Statistiques")
                }

                // Section À propos
                Section {
                    HStack {
                        SettingsRow(
                            icon: "info.circle.fill",
                            iconColor: .blue,
                            title: "Version"
                        )
                        Spacer()
                        Text("1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        SettingsRow(
                            icon: "person.fill",
                            iconColor: .appPrimary,
                            title: "Athlète"
                        )
                        Spacer()
                        Text("Seydou CAMARA")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("À propos")
                }
            }
            .navigationTitle("Réglages")
            .onAppear(perform: loadSettings)
            .task {
                await updatePendingNotificationsCount()
            }
            .alert("Reset journée", isPresented: $showingResetAlert) {
                Button("Annuler", role: .cancel) { }
                Button("Réinitialiser", role: .destructive) {
                    resetToday()
                }
            } message: {
                Text("Cela va réinitialiser tous les repas, compléments et suppléments d'aujourd'hui. Cette action est irréversible.")
            }
            .alert("Nouveau cycle", isPresented: $showingResetCycleAlert) {
                Button("Annuler", role: .cancel) { }
                Button("Démarrer", role: .destructive) {
                    startNewCycle()
                }
            } message: {
                Text("Cela va terminer le cycle actuel et en démarrer un nouveau à partir d'aujourd'hui.")
            }
            .alert("Supprimer toutes les données", isPresented: $showingDeleteDataAlert) {
                Button("Annuler", role: .cancel) { }
                Button("Supprimer", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("Cela va supprimer définitivement toutes les données : historique, cycles, et paramètres. Cette action est irréversible.")
            }
            .alert("Notifications désactivées", isPresented: $showingPermissionAlert) {
                Button("Réglages", role: .none) {
                    openAppSettings()
                }
                Button("Annuler", role: .cancel) {
                    notificationsEnabled = false
                }
            } message: {
                Text("Pour activer les notifications, autorise-les dans les Réglages de ton iPhone.")
            }
        }
    }

    // MARK: - Computed Properties

    private var averageScore: Int {
        guard !allDayLogs.isEmpty else { return 0 }
        let total = allDayLogs.reduce(0) { $0 + Int($1.dailyScore * 100) }
        return total / allDayLogs.count
    }

    private var scoreColor: Color {
        if averageScore >= 80 { return .appSuccess }
        if averageScore >= 50 { return .appWarning }
        return .appError
    }

    // MARK: - Actions

    private func loadSettings() {
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        hideAdvancedSupplements = UserDefaults.standard.bool(forKey: "hideAdvancedSupplements")

        if let morningData = UserDefaults.standard.object(forKey: "morningReminderTime") as? Date {
            morningReminderTime = morningData
        } else {
            var components = DateComponents()
            components.hour = 7
            components.minute = 0
            morningReminderTime = Calendar.current.date(from: components) ?? Date()
        }

        if let eveningData = UserDefaults.standard.object(forKey: "eveningReminderTime") as? Date {
            eveningReminderTime = eveningData
        } else {
            var components = DateComponents()
            components.hour = 21
            components.minute = 0
            eveningReminderTime = Calendar.current.date(from: components) ?? Date()
        }
    }

    private func handleNotificationToggle(_ enabled: Bool) {
        if enabled {
            Task {
                let granted = await notificationManager.requestAuthorization()
                await MainActor.run {
                    if granted {
                        saveAndScheduleNotifications()
                    } else {
                        showingPermissionAlert = true
                    }
                }
            }
        } else {
            notificationManager.cancelAllNotifications()
            UserDefaults.standard.set(false, forKey: "notificationsEnabled")
            pendingNotificationsCount = 0
        }
    }

    private func saveAndScheduleNotifications() {
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(morningReminderTime, forKey: "morningReminderTime")
        UserDefaults.standard.set(eveningReminderTime, forKey: "eveningReminderTime")

        notificationManager.scheduleAllNotifications()

        Task {
            await updatePendingNotificationsCount()
        }
    }

    private func updatePendingNotificationsCount() async {
        let pending = await notificationManager.getPendingNotifications()
        await MainActor.run {
            pendingNotificationsCount = pending.count
        }
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func resetToday() {
        let today = Date().startOfDay
        let endOfToday = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        if let todayLog = allDayLogs.first(where: { $0.date >= today && $0.date < endOfToday }) {
            for meal in todayLog.meals {
                meal.isCompleted = false
                meal.completedAt = nil
            }

            for supplement in todayLog.supplements {
                supplement.isCompleted = false
                supplement.completedAt = nil
            }

            for ped in todayLog.peds {
                ped.isCompleted = false
                ped.completedAt = nil
            }

            todayLog.waterIntake = 0
            todayLog.sleepHours = 0
            todayLog.weight = nil

            try? modelContext.save()
        }

        let impactFeedback = UINotificationFeedbackGenerator()
        impactFeedback.notificationOccurred(.success)
    }

    private func startNewCycle() {
        for cycle in allCycles {
            cycle.isActive = false
        }

        let newCycle = Cycle(startDate: Date(), isActive: true)
        modelContext.insert(newCycle)

        try? modelContext.save()

        let impactFeedback = UINotificationFeedbackGenerator()
        impactFeedback.notificationOccurred(.success)
    }

    private func deleteAllData() {
        for dayLog in allDayLogs {
            modelContext.delete(dayLog)
        }

        for cycle in allCycles {
            modelContext.delete(cycle)
        }

        UserDefaults.standard.removeObject(forKey: "notificationsEnabled")
        UserDefaults.standard.removeObject(forKey: "morningReminderTime")
        UserDefaults.standard.removeObject(forKey: "eveningReminderTime")
        UserDefaults.standard.removeObject(forKey: "hideAdvancedSupplements")

        notificationManager.cancelAllNotifications()

        try? modelContext.save()

        notificationsEnabled = false
        hideAdvancedSupplements = false

        let impactFeedback = UINotificationFeedbackGenerator()
        impactFeedback.notificationOccurred(.warning)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(iconColor)
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [DayLog.self, Cycle.self])
}
