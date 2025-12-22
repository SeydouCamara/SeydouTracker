import Foundation
import SwiftData
import SwiftUI

@Observable
class TodayViewModel {
    var modelContext: ModelContext?
    var currentDayLog: DayLog?
    var currentCycle: Cycle?

    var selectedDate: Date = Date()
    var selectedDayType: DayType = Date().defaultDayType

    // MARK: - Initialization

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        // Charger le cycle EN PREMIER (pour avoir currentWeek disponible)
        loadOrCreateCycle()
        // Puis charger/créer le DayLog
        loadOrCreateDayLog()
    }

    // MARK: - Day Log Management

    func loadOrCreateDayLog() {
        guard let modelContext else { return }

        let startOfDay = selectedDate.startOfDay
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = #Predicate<DayLog> { log in
            log.date >= startOfDay && log.date < endOfDay
        }

        let descriptor = FetchDescriptor<DayLog>(predicate: predicate)

        do {
            let results = try modelContext.fetch(descriptor)
            if let existingLog = results.first {
                currentDayLog = existingLog
                selectedDayType = existingLog.dayType
            } else {
                createNewDayLog()
            }
        } catch {
            print("Error fetching DayLog: \(error)")
            createNewDayLog()
        }
    }

    private func createNewDayLog() {
        guard let modelContext else { return }

        let newLog = DayLog(
            date: selectedDate,
            dayType: selectedDayType,
            cycleWeek: currentCycle?.currentWeek
        )

        // Créer les repas pour ce jour
        createMeals(for: newLog)

        // Créer les compléments pour ce jour
        createSupplements(for: newLog)

        // Créer les PEDs pour ce jour
        createPEDs(for: newLog)

        modelContext.insert(newLog)
        currentDayLog = newLog

        do {
            try modelContext.save()
        } catch {
            print("Error saving new DayLog: \(error)")
        }
    }

    private func createMeals(for dayLog: DayLog) {
        for mealType in MealType.allCases {
            if mealType.isAvailable(for: selectedDayType) {
                let meal = MealLog(
                    mealType: mealType,
                    scheduledTime: mealType.scheduledTime(for: selectedDayType)
                )
                meal.dayLog = dayLog
                dayLog.meals.append(meal)
            }
        }
    }

    private func createSupplements(for dayLog: DayLog) {
        for supplementType in SupplementType.allCases {
            for timingSlot in supplementType.timingSlots {
                let supplement = SupplementLog(
                    supplementType: supplementType,
                    timingSlot: timingSlot
                )
                supplement.dayLog = dayLog
                dayLog.supplements.append(supplement)
            }
        }
    }

    private func createPEDs(for dayLog: DayLog) {
        let week = currentCycle?.currentWeek ?? 1

        for pedType in PEDType.allCases {
            if pedType.isActive(forWeek: week), let dosage = pedType.dosage(forWeek: week) {
                let ped = PEDLog(
                    pedType: pedType,
                    dosage: dosage
                )
                ped.dayLog = dayLog
                dayLog.peds.append(ped)
            }
        }
    }

    // MARK: - Cycle Management

    func loadOrCreateCycle() {
        guard let modelContext else { return }

        let predicate = #Predicate<Cycle> { cycle in
            cycle.isActive == true
        }

        let descriptor = FetchDescriptor<Cycle>(predicate: predicate)

        do {
            let results = try modelContext.fetch(descriptor)
            if let existingCycle = results.first {
                currentCycle = existingCycle
            } else {
                createNewCycle()
            }
        } catch {
            print("Error fetching Cycle: \(error)")
            createNewCycle()
        }
    }

    private func createNewCycle() {
        guard let modelContext else { return }

        let newCycle = Cycle(startDate: Date(), isActive: true)
        modelContext.insert(newCycle)
        currentCycle = newCycle

        do {
            try modelContext.save()
        } catch {
            print("Error saving new Cycle: \(error)")
        }
    }

    // MARK: - Actions

    func changeDayType(to newType: DayType) {
        selectedDayType = newType
        currentDayLog?.dayType = newType

        // Mettre à jour les horaires des repas
        if let meals = currentDayLog?.meals {
            for meal in meals {
                meal.scheduledTime = meal.mealType.scheduledTime(for: newType)
            }
        }

        saveContext()
    }

    func updateWaterIntake(by amount: Double) {
        guard let dayLog = currentDayLog else { return }
        dayLog.waterIntake = max(0, dayLog.waterIntake + amount)
        saveContext()
    }

    func setSleepHours(_ hours: Double) {
        guard let dayLog = currentDayLog else { return }
        dayLog.sleepHours = hours
        saveContext()
    }

    func setWeight(_ weight: Double?) {
        guard let dayLog = currentDayLog else { return }
        dayLog.weight = weight
        saveContext()
    }

    func toggleMeal(_ meal: MealLog) {
        meal.toggle()
        saveContext()
    }

    func toggleSupplement(_ supplement: SupplementLog) {
        supplement.toggle()
        saveContext()
    }

    func togglePED(_ ped: PEDLog) {
        ped.toggle()
        saveContext()
    }

    private func saveContext() {
        do {
            try modelContext?.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }

    // MARK: - Computed Properties

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: selectedDate).capitalized
    }

    var cycleWeekDisplay: String {
        guard let cycle = currentCycle else { return "—" }
        return "Semaine \(cycle.currentWeek)/8"
    }

    var dailyScore: Int {
        guard let dayLog = currentDayLog else { return 0 }
        return Int(dayLog.dailyScore * 100)
    }

    var scoreColor: Color {
        let score = dailyScore
        if score >= 80 { return .appSuccess }
        if score >= 50 { return .appWarning }
        return .appError
    }
}
