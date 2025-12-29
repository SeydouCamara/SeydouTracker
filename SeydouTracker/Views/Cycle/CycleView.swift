import SwiftUI
import SwiftData

struct CycleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Cycle> { $0.isActive == true }) private var cycles: [Cycle]
    @State private var showingDatePicker = false

    private var currentCycle: Cycle? { cycles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let cycle = currentCycle {
                        // Carte progression
                        ProgressionCard(cycle: cycle, onEditDate: { showingDatePicker = true })

                        // Tableau des dosages
                        DosageTableCard(currentWeek: cycle.currentWeek)

                        // Dates importantes
                        ImportantDatesCard(cycle: cycle)
                    } else {
                        NoCycleView(onCreate: createNewCycle)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("Cycle Suppléments")
            .sheet(isPresented: $showingDatePicker) {
                if let cycle = currentCycle {
                    CycleDatePickerSheet(
                        cycle: cycle,
                        isPresented: $showingDatePicker,
                        onSave: { newDate in
                            cycle.startDate = newDate
                            try? modelContext.save()
                        }
                    )
                    .presentationDetents([.height(350)])
                }
            }
        }
    }

    private func createNewCycle() {
        let newCycle = Cycle(startDate: Date(), isActive: true)
        modelContext.insert(newCycle)
        try? modelContext.save()
    }
}

// MARK: - Cycle Date Picker Sheet
struct CycleDatePickerSheet: View {
    let cycle: Cycle
    @Binding var isPresented: Bool
    let onSave: (Date) -> Void

    @State private var selectedDate: Date = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Modifier la date de début")
                    .font(.headline)

                DatePicker(
                    "Date de début",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding(.horizontal)

                Button(action: {
                    onSave(selectedDate)
                    isPresented = false
                }) {
                    Text("Enregistrer")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appPrimary)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
            .onAppear {
                selectedDate = cycle.startDate
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Progression Card
struct ProgressionCard: View {
    let cycle: Cycle
    var onEditDate: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Progression")
                        .font(.headline)

                    Text("Jour \(cycle.currentDay) / 56")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Semaine actuelle
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Semaine")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(cycle.currentWeek)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.appPrimary)
                }
            }

            // Barre de progression avec semaines
            VStack(spacing: 8) {
                // Barre
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 16)

                        // Progress
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.appPrimary.opacity(0.7), .appPrimary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * cycle.progress, height: 16)
                            .animation(.spring(response: 0.5), value: cycle.progress)

                        // Marqueurs de semaines
                        HStack(spacing: 0) {
                            ForEach(1...7, id: \.self) { week in
                                Spacer()
                                Rectangle()
                                    .fill(Color.white.opacity(0.5))
                                    .frame(width: 1, height: 10)
                            }
                            Spacer()
                        }
                    }
                }
                .frame(height: 16)

                // Labels semaines
                HStack {
                    ForEach(1...8, id: \.self) { week in
                        Text("S\(week)")
                            .font(.caption2)
                            .fontWeight(week == cycle.currentWeek ? .bold : .regular)
                            .foregroundColor(week == cycle.currentWeek ? .appPrimary : .secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }

            Divider()

            // Stats avec bouton modifier
            HStack(spacing: 20) {
                // Date début (cliquable)
                Button(action: { onEditDate?() }) {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(.appSecondary)
                            Image(systemName: "pencil")
                                .font(.system(size: 8))
                                .foregroundColor(.appPrimary)
                        }

                        Text("Début")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text(cycle.formattedStartDate)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)

                StatItem(
                    icon: "flag.checkered",
                    title: "Fin",
                    value: cycle.formattedEndDate
                )

                StatItem(
                    icon: "hourglass",
                    title: "Restant",
                    value: "\(cycle.daysRemaining)j"
                )
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.appSecondary)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Dosage Table Card
struct DosageTableCard: View {
    let currentWeek: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "tablecells")
                    .foregroundColor(.appAlert)
                Text("Dosages par semaine")
                    .font(.headline)
            }

            // Tableau
            VStack(spacing: 0) {
                // Header row
                HStack(spacing: 0) {
                    Text("Composé")
                        .frame(width: 100, alignment: .leading)
                    Text("S1-4")
                        .frame(maxWidth: .infinity)
                    Text("S5-8")
                        .frame(maxWidth: .infinity)
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.gray.opacity(0.1))

                // Data rows
                ForEach(PEDType.allCases, id: \.self) { pedType in
                    DosageRow(
                        pedType: pedType,
                        currentWeek: currentWeek
                    )
                }
            }
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Dosage Row
struct DosageRow: View {
    let pedType: PEDType
    let currentWeek: Int

    var body: some View {
        HStack(spacing: 0) {
            // Nom
            HStack(spacing: 6) {
                Image(systemName: pedType.icon)
                    .font(.caption)
                    .foregroundColor(.appAlert)

                Text(pedType.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 100, alignment: .leading)

            // Dosage S1-4
            DosageCell(
                dosage: pedType.dosage(forWeek: 1),
                isActive: currentWeek <= 4 && pedType.isActive(forWeek: 1),
                isCurrent: currentWeek <= 4
            )

            // Dosage S5-8
            DosageCell(
                dosage: pedType.dosage(forWeek: 5),
                isActive: currentWeek >= 5 && pedType.isActive(forWeek: 5),
                isCurrent: currentWeek >= 5
            )
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.appCardBackground)
    }
}

// MARK: - Dosage Cell
struct DosageCell: View {
    let dosage: String?
    let isActive: Bool
    let isCurrent: Bool

    var body: some View {
        Group {
            if let dosage = dosage {
                Text(dosage)
                    .font(.caption)
                    .fontWeight(isCurrent ? .bold : .regular)
                    .foregroundColor(isCurrent ? .appAlert : .primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        isCurrent ? Color.appAlert.opacity(0.15) : Color.clear
                    )
                    .cornerRadius(4)
            } else {
                Text("—")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Important Dates Card
struct ImportantDatesCard: View {
    let cycle: Cycle

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.appWarning)
                Text("Bilans sanguins")
                    .font(.headline)
            }

            // Liste des dates
            VStack(spacing: 8) {
                ForEach(cycle.bloodWorkDates, id: \.week) { item in
                    BloodWorkDateRow(
                        week: item.week,
                        date: item.date,
                        label: item.label,
                        currentWeek: cycle.currentWeek
                    )
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Blood Work Date Row
struct BloodWorkDateRow: View {
    let week: Int
    let date: Date
    let label: String
    let currentWeek: Int

    private var isPast: Bool { currentWeek > week }
    private var isCurrent: Bool { currentWeek == week }
    private var isUpcoming: Bool { currentWeek < week }

    var body: some View {
        HStack {
            // Icône statut
            Image(systemName: statusIcon)
                .font(.caption)
                .foregroundColor(statusColor)
                .frame(width: 24)

            // Label
            Text(label)
                .font(.subheadline)
                .foregroundColor(isPast ? .secondary : .primary)

            Spacer()

            // Date
            Text(formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isCurrent ? Color.appWarning.opacity(0.2) : Color.gray.opacity(0.1))
                .cornerRadius(4)
        }
        .padding(.vertical, 6)
    }

    private var statusIcon: String {
        if isPast { return "checkmark.circle.fill" }
        if isCurrent { return "exclamationmark.circle.fill" }
        return "circle"
    }

    private var statusColor: Color {
        if isPast { return .appSuccess }
        if isCurrent { return .appWarning }
        return .secondary
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}

// MARK: - No Cycle View
struct NoCycleView: View {
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.appPrimary.opacity(0.5))

            Text("Aucun cycle actif")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Démarre un nouveau cycle de 8 semaines pour suivre tes suppléments.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: onCreate) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Démarrer un cycle")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.appPrimary)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }
}

#Preview {
    CycleView()
        .modelContainer(for: [Cycle.self])
}
