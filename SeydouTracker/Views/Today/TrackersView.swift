import SwiftUI

struct TrackersView: View {
    @Bindable var viewModel: TodayViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Tracker Poids
            WeightTrackerView(viewModel: viewModel)

            // Tracker Eau
            WaterTrackerView(viewModel: viewModel)

            // Tracker Sommeil
            SleepTrackerView(viewModel: viewModel)
        }
    }
}

// MARK: - Weight Tracker View
struct WeightTrackerView: View {
    @Bindable var viewModel: TodayViewModel
    @State private var showingPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "scalemass.fill")
                    .font(.title3)
                    .foregroundColor(.appPrimary)

                Text("Poids")
                    .font(.headline)

                Spacer()

                // Tendance (si disponible)
                if let trend = weightTrend {
                    HStack(spacing: 4) {
                        Image(systemName: trend.icon)
                            .font(.caption)
                        Text(trend.text)
                            .font(.caption)
                    }
                    .foregroundColor(trend.color)
                }
            }

            // Affichage du poids
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let weight = currentWeight {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(String(format: "%.1f", weight))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.appPrimary)

                            Text("kg")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Non renseigné")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }

                    if let lastWeight = lastRecordedWeight, currentWeight == nil {
                        Text("Dernier: \(String(format: "%.1f", lastWeight)) kg")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Bouton modifier
                Button(action: { showingPicker = true }) {
                    HStack {
                        Image(systemName: currentWeight != nil ? "pencil" : "plus")
                        Text(currentWeight != nil ? "Modifier" : "Ajouter")
                    }
                    .font(.subheadline)
                    .foregroundColor(.appPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.appPrimary.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
        .sheet(isPresented: $showingPicker) {
            WeightPickerSheet(
                weight: Binding(
                    get: { currentWeight ?? lastRecordedWeight ?? 75.0 },
                    set: { viewModel.setWeight($0) }
                ),
                isPresented: $showingPicker
            )
            .presentationDetents([.height(300)])
        }
    }

    // MARK: - Computed Properties

    private var currentWeight: Double? {
        viewModel.currentDayLog?.weight
    }

    private var lastRecordedWeight: Double? {
        // Récupérer le dernier poids enregistré (simplifié pour l'instant)
        nil
    }

    private var weightTrend: (icon: String, text: String, color: Color)? {
        // Tendance calculée à partir de l'historique
        nil
    }
}

// MARK: - Weight Picker Sheet
struct WeightPickerSheet: View {
    @Binding var weight: Double
    @Binding var isPresented: Bool

    @State private var selectedWeight: Double = 75.0

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Entrer ton poids")
                    .font(.headline)

                // Affichage du poids sélectionné
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", selectedWeight))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.appPrimary)

                    Text("kg")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }

                // Slider pour ajuster le poids
                VStack(spacing: 8) {
                    Slider(value: $selectedWeight, in: 40...150, step: 0.1)
                        .accentColor(.appPrimary)

                    HStack {
                        Text("40 kg")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("150 kg")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                // Boutons d'ajustement rapide
                HStack(spacing: 12) {
                    WeightAdjustButton(label: "-0.5", action: { selectedWeight = max(40, selectedWeight - 0.5) })
                    WeightAdjustButton(label: "-0.1", action: { selectedWeight = max(40, selectedWeight - 0.1) })
                    WeightAdjustButton(label: "+0.1", action: { selectedWeight = min(150, selectedWeight + 0.1) })
                    WeightAdjustButton(label: "+0.5", action: { selectedWeight = min(150, selectedWeight + 0.5) })
                }

                Button(action: {
                    weight = selectedWeight
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
                selectedWeight = weight
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

// MARK: - Weight Adjust Button
struct WeightAdjustButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.appPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.appPrimary.opacity(0.1))
                .cornerRadius(8)
        }
    }
}

// MARK: - Water Tracker View
struct WaterTrackerView: View {
    @Bindable var viewModel: TodayViewModel

    private let waterGoal: Double = 3.0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "drop.fill")
                    .font(.title3)
                    .foregroundColor(.blue)

                Text("Hydratation")
                    .font(.headline)

                Spacer()

                Text("\(formattedWater) / \(Int(waterGoal))L")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isGoalReached ? .appSuccess : .secondary)
            }

            // Jauge visuelle
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.15))
                        .frame(height: 40)

                    // Progress
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.6), .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * waterProgress, height: 40)
                        .animation(.spring(response: 0.4), value: waterProgress)

                    // Indicateurs de litres
                    HStack {
                        ForEach(1...3, id: \.self) { liter in
                            Spacer()
                            Rectangle()
                                .fill(Color.white.opacity(0.5))
                                .frame(width: 2, height: 20)
                            if liter == 3 { Spacer() }
                        }
                    }

                    // Icône eau animée
                    HStack {
                        Spacer()
                        Image(systemName: isGoalReached ? "checkmark.circle.fill" : "drop.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(.trailing, 12)
                    }
                }
            }
            .frame(height: 40)

            // Boutons rapides
            HStack(spacing: 10) {
                WaterButton(amount: 0.25, label: "+250ml", color: .blue.opacity(0.7)) {
                    addWater(0.25)
                }

                WaterButton(amount: 0.5, label: "+500ml", color: .blue.opacity(0.85)) {
                    addWater(0.5)
                }

                WaterButton(amount: 1.0, label: "+1L", color: .blue) {
                    addWater(1.0)
                }

                Spacer()

                // Bouton reset
                Button(action: resetWater) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }

    // MARK: - Computed Properties

    private var currentWater: Double {
        viewModel.currentDayLog?.waterIntake ?? 0
    }

    private var waterProgress: Double {
        min(currentWater / waterGoal, 1.0)
    }

    private var isGoalReached: Bool {
        currentWater >= waterGoal
    }

    private var formattedWater: String {
        if currentWater >= 1.0 {
            return String(format: "%.1fL", currentWater)
        } else {
            return "\(Int(currentWater * 1000))ml"
        }
    }

    // MARK: - Actions

    private func addWater(_ amount: Double) {
        let wasGoalReached = currentWater >= waterGoal
        withAnimation(.spring(response: 0.3)) {
            viewModel.updateWaterIntake(by: amount)
        }
        HapticManager.shared.waterDrop()

        // Célébration si objectif atteint pour la première fois
        if !wasGoalReached && currentWater + amount >= waterGoal {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                HapticManager.shared.success()
            }
        }
    }

    private func resetWater() {
        withAnimation(.spring(response: 0.3)) {
            viewModel.updateWaterIntake(by: -currentWater)
        }
        HapticManager.shared.lightImpact()
    }
}

// MARK: - Water Button
struct WaterButton: View {
    let amount: Double
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(color)
                .cornerRadius(8)
        }
    }
}

// MARK: - Sleep Tracker View
struct SleepTrackerView: View {
    @Bindable var viewModel: TodayViewModel
    @State private var showingPicker = false

    private let sleepMin: Double = 7.0
    private let sleepMax: Double = 9.0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "moon.zzz.fill")
                    .font(.title3)
                    .foregroundColor(.indigo)

                Text("Sommeil")
                    .font(.headline)

                Spacer()

                // Indicateur de statut
                HStack(spacing: 4) {
                    Image(systemName: sleepStatus.icon)
                        .foregroundColor(sleepStatusColor)

                    Text(sleepStatusText)
                        .font(.caption)
                        .foregroundColor(sleepStatusColor)
                }
            }

            // Affichage heures + bouton modifier
            HStack {
                // Heures de sommeil
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(formattedSleep)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(sleepStatusColor)

                        Text("heures")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text("Objectif: \(Int(sleepMin))-\(Int(sleepMax))h")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Bouton modifier
                Button(action: { showingPicker = true }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Modifier")
                    }
                    .font(.subheadline)
                    .foregroundColor(.indigo)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.indigo.opacity(0.1))
                    .cornerRadius(8)
                }
            }

            // Barre de progression du sommeil
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background avec zones
                    HStack(spacing: 0) {
                        // Zone insuffisante (0-7h)
                        Rectangle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: geometry.size.width * (sleepMin / 12))

                        // Zone optimale (7-9h)
                        Rectangle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: geometry.size.width * ((sleepMax - sleepMin) / 12))

                        // Zone excessive (9-12h)
                        Rectangle()
                            .fill(Color.orange.opacity(0.2))
                    }
                    .frame(height: 24)
                    .cornerRadius(6)

                    // Indicateur position
                    if currentSleep > 0 {
                        Circle()
                            .fill(sleepStatusColor)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .shadow(radius: 2)
                            .offset(x: geometry.size.width * min(currentSleep / 12, 1.0) - 10)
                            .animation(.spring(response: 0.4), value: currentSleep)
                    }
                }
            }
            .frame(height: 24)

            // Légende
            HStack {
                LegendItem(color: .red, text: "<7h")
                Spacer()
                LegendItem(color: .green, text: "7-9h")
                Spacer()
                LegendItem(color: .orange, text: ">9h")
            }
            .font(.caption2)
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
        .sheet(isPresented: $showingPicker) {
            SleepPickerSheet(
                hours: Binding(
                    get: { currentSleep },
                    set: { viewModel.setSleepHours($0) }
                ),
                isPresented: $showingPicker
            )
            .presentationDetents([.height(300)])
        }
    }

    // MARK: - Computed Properties

    private var currentSleep: Double {
        viewModel.currentDayLog?.sleepHours ?? 0
    }

    private var sleepStatus: SleepStatus {
        viewModel.currentDayLog?.sleepStatus ?? .insufficient
    }

    private var sleepStatusColor: Color {
        switch sleepStatus {
        case .optimal: return .green
        case .acceptable: return .orange
        case .insufficient: return .red
        }
    }

    private var sleepStatusText: String {
        switch sleepStatus {
        case .optimal: return "Optimal"
        case .acceptable: return "Acceptable"
        case .insufficient: return currentSleep == 0 ? "Non renseigné" : "Insuffisant"
        }
    }

    private var formattedSleep: String {
        if currentSleep == 0 {
            return "—"
        }
        let hours = Int(currentSleep)
        let minutes = Int((currentSleep - Double(hours)) * 60)
        if minutes > 0 {
            return "\(hours)h\(minutes)"
        }
        return "\(hours)"
    }
}

// MARK: - Legend Item
struct LegendItem: View {
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Sleep Picker Sheet
struct SleepPickerSheet: View {
    @Binding var hours: Double
    @Binding var isPresented: Bool

    @State private var selectedHours: Int = 7
    @State private var selectedMinutes: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Heures de sommeil")
                    .font(.headline)

                HStack(spacing: 0) {
                    // Heures
                    Picker("Heures", selection: $selectedHours) {
                        ForEach(0...12, id: \.self) { hour in
                            Text("\(hour)h").tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100)

                    // Minutes
                    Picker("Minutes", selection: $selectedMinutes) {
                        ForEach([0, 15, 30, 45], id: \.self) { minute in
                            Text("\(minute)min").tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100)
                }

                Button("Confirmer") {
                    hours = Double(selectedHours) + Double(selectedMinutes) / 60.0
                    isPresented = false
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.indigo)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding()
            .onAppear {
                selectedHours = Int(hours)
                selectedMinutes = Int((hours - Double(Int(hours))) * 60)
            }
        }
    }
}

#Preview {
    TrackersView(viewModel: TodayViewModel())
        .padding()
        .background(Color.appGroupedBackground)
}
