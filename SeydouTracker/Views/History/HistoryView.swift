import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DayLog.date, order: .reverse) private var allDayLogs: [DayLog]

    private var last7Days: [DayLog] {
        Array(allDayLogs.prefix(7))
    }

    private var weeklyAverage: Int {
        guard !last7Days.isEmpty else { return 0 }
        let total = last7Days.reduce(0) { $0 + Int($1.dailyScore * 100) }
        return total / last7Days.count
    }

    // Données de poids pour le graphique
    private var weightData: [(date: Date, weight: Double)] {
        allDayLogs
            .filter { $0.weight != nil }
            .prefix(14) // 2 semaines max
            .map { (date: $0.date, weight: $0.weight!) }
            .reversed()
    }

    private var weightTrend: (value: Double, isPositive: Bool)? {
        let weightsWithDates = allDayLogs
            .filter { $0.weight != nil }
            .prefix(7)
            .compactMap { $0.weight }

        guard weightsWithDates.count >= 2 else { return nil }
        let latest = weightsWithDates.first!
        let oldest = weightsWithDates.last!
        let diff = latest - oldest
        return (value: abs(diff), isPositive: diff >= 0)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Résumé de la semaine
                    WeeklySummaryCard(
                        average: weeklyAverage,
                        daysTracked: last7Days.count
                    )

                    // Évolution du poids
                    WeightEvolutionCard(
                        weightData: weightData,
                        trend: weightTrend
                    )

                    // Liste des jours
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.appSecondary)
                            Text("7 derniers jours")
                                .font(.headline)
                        }

                        if last7Days.isEmpty {
                            EmptyHistoryView()
                        } else {
                            VStack(spacing: 10) {
                                ForEach(last7Days, id: \.id) { dayLog in
                                    DayHistoryRow(dayLog: dayLog)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.appCardBackground)
                    .cornerRadius(16)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("Historique")
        }
    }
}

// MARK: - Weight Evolution Card
struct WeightEvolutionCard: View {
    let weightData: [(date: Date, weight: Double)]
    let trend: (value: Double, isPositive: Bool)?

    private var minWeight: Double {
        weightData.map(\.weight).min() ?? 0
    }

    private var maxWeight: Double {
        weightData.map(\.weight).max() ?? 100
    }

    private var latestWeight: Double? {
        weightData.last?.weight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "scalemass.fill")
                    .font(.title3)
                    .foregroundColor(.appPrimary)

                Text("Évolution du poids")
                    .font(.headline)

                Spacer()

                // Tendance
                if let trend = trend {
                    HStack(spacing: 4) {
                        Image(systemName: trend.isPositive ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                        Text(String(format: "%+.1f kg", trend.isPositive ? trend.value : -trend.value))
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(trend.isPositive ? .orange : .appSuccess)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((trend.isPositive ? Color.orange : Color.appSuccess).opacity(0.15))
                    .cornerRadius(6)
                }
            }

            if weightData.isEmpty {
                // État vide
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))

                    Text("Aucune donnée de poids")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Ajoute ton poids dans l'onglet Aujourd'hui pour voir l'évolution ici.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Poids actuel
                if let latest = latestWeight {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", latest))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.appPrimary)

                        Text("kg")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(weightData.count) mesures")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Mini graphique
                if weightData.count >= 2 {
                    WeightMiniChart(
                        data: weightData,
                        minWeight: minWeight,
                        maxWeight: maxWeight
                    )
                    .frame(height: 80)
                }

                // Range
                HStack {
                    VStack(alignment: .leading) {
                        Text("Min")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f kg", minWeight))
                            .font(.caption)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("Max")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f kg", maxWeight))
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Weight Mini Chart
struct WeightMiniChart: View {
    let data: [(date: Date, weight: Double)]
    let minWeight: Double
    let maxWeight: Double

    private var range: Double {
        max(maxWeight - minWeight, 1)
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let stepX = width / CGFloat(max(data.count - 1, 1))

            ZStack {
                // Ligne de fond
                Path { path in
                    for (index, item) in data.enumerated() {
                        let x = CGFloat(index) * stepX
                        let normalizedY = (item.weight - minWeight) / range
                        let y = height - (CGFloat(normalizedY) * height * 0.8 + height * 0.1)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [.appPrimary.opacity(0.6), .appPrimary],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )

                // Zone remplie
                Path { path in
                    path.move(to: CGPoint(x: 0, y: height))

                    for (index, item) in data.enumerated() {
                        let x = CGFloat(index) * stepX
                        let normalizedY = (item.weight - minWeight) / range
                        let y = height - (CGFloat(normalizedY) * height * 0.8 + height * 0.1)

                        if index == 0 {
                            path.addLine(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }

                    path.addLine(to: CGPoint(x: width, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [.appPrimary.opacity(0.3), .appPrimary.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Points
                ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                    let x = CGFloat(index) * stepX
                    let normalizedY = (item.weight - minWeight) / range
                    let y = height - (CGFloat(normalizedY) * height * 0.8 + height * 0.1)

                    Circle()
                        .fill(Color.appPrimary)
                        .frame(width: 6, height: 6)
                        .position(x: x, y: y)
                }
            }
        }
    }
}

// MARK: - Weekly Summary Card
struct WeeklySummaryCard: View {
    let average: Int
    let daysTracked: Int

    private var averageColor: Color {
        if average >= 80 { return .appSuccess }
        if average >= 50 { return .appWarning }
        return .appError
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Résumé hebdomadaire")
                        .font(.headline)

                    Text("\(daysTracked) jour\(daysTracked > 1 ? "s" : "") suivis")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Score moyen
                VStack(spacing: 2) {
                    Text("Moyenne")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(average)%")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(averageColor)
                }
            }

            // Barre de progression visuelle
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [averageColor.opacity(0.7), averageColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(average) / 100, height: 12)
                        .animation(.spring(response: 0.5), value: average)
                }
            }
            .frame(height: 12)

            Divider()

            // Stats rapides
            HStack(spacing: 0) {
                WeeklyStatItem(
                    icon: "flame.fill",
                    value: "\(daysTracked)",
                    label: "Jours actifs",
                    color: .appPrimary
                )

                WeeklyStatItem(
                    icon: "trophy.fill",
                    value: average >= 80 ? "Excellent" : (average >= 50 ? "Bien" : "À améliorer"),
                    label: "Performance",
                    color: averageColor
                )

                WeeklyStatItem(
                    icon: "arrow.up.right",
                    value: "—",
                    label: "Tendance",
                    color: .appSecondary
                )
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Weekly Stat Item
struct WeeklyStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Day History Row
struct DayHistoryRow: View {
    let dayLog: DayLog

    private var score: Int {
        Int(dayLog.dailyScore * 100)
    }

    private var scoreColor: Color {
        if score >= 80 { return .appSuccess }
        if score >= 50 { return .appWarning }
        return .appError
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(dayLog.date)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Date
            VStack(spacing: 2) {
                Text(dayOfWeek)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isToday ? .appPrimary : .secondary)

                Text(dayNumber)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isToday ? .appPrimary : .primary)
            }
            .frame(width: 50)

            // Détails
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(dayLog.dayType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if isToday {
                        Text("Aujourd'hui")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appPrimary)
                            .cornerRadius(4)
                    }

                    // Poids du jour si disponible
                    if let weight = dayLog.weight {
                        Text(String(format: "%.1f kg", weight))
                            .font(.caption)
                            .foregroundColor(.appPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appPrimary.opacity(0.1))
                            .cornerRadius(4)
                    }
                }

                // Mini barres de progression
                HStack(spacing: 8) {
                    MiniProgressBar(
                        icon: "fork.knife",
                        progress: dayLog.totalMealsCount > 0 ? Double(dayLog.completedMealsCount) / Double(dayLog.totalMealsCount) : 0,
                        color: .appPrimary
                    )

                    MiniProgressBar(
                        icon: "pills",
                        progress: dayLog.totalSupplementsCount > 0 ? Double(dayLog.completedSupplementsCount) / Double(dayLog.totalSupplementsCount) : 0,
                        color: .appSecondary
                    )

                    MiniProgressBar(
                        icon: "bolt.fill",
                        progress: dayLog.totalPEDsCount > 0 ? Double(dayLog.completedPEDsCount) / Double(dayLog.totalPEDsCount) : 0,
                        color: .appAlert
                    )

                    MiniProgressBar(
                        icon: "drop.fill",
                        progress: dayLog.waterProgress,
                        color: .blue
                    )
                }
            }

            Spacer()

            // Score
            ZStack {
                Circle()
                    .stroke(scoreColor.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))

                Text("\(score)%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isToday ? Color.appPrimary.opacity(0.08) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isToday ? Color.appPrimary.opacity(0.3) : Color.gray.opacity(0.15), lineWidth: 1)
        )
    }

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEE"
        return formatter.string(from: dayLog.date).capitalized
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: dayLog.date)
    }
}

// MARK: - Mini Progress Bar
struct MiniProgressBar: View {
    let icon: String
    let progress: Double
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 4)
                }
            }
            .frame(height: 4)
        }
        .frame(width: 50)
    }
}

// MARK: - Empty History View
struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.5))

            Text("Aucun historique")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Commence à tracker tes journées pour voir ton historique ici.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [DayLog.self, MealLog.self, SupplementLog.self, PEDLog.self])
}
