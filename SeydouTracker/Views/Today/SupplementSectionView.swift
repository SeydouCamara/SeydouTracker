import SwiftUI

struct SupplementSectionView: View {
    @Bindable var viewModel: TodayViewModel
    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header de section (cliquable)
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }) {
                CollapsibleSectionHeader(
                    title: "Compléments",
                    icon: "pill.fill",
                    iconColor: .appSecondary,
                    progress: supplementsProgress,
                    total: totalSupplements,
                    completed: completedSupplements,
                    isExpanded: isExpanded
                )
            }
            .buttonStyle(.plain)

            // Groupes par timing (collapsible)
            if isExpanded {
                VStack(spacing: 16) {
                    // Matin
                    if !morningSupplements.isEmpty {
                        SupplementGroupView(
                            title: "Matin",
                            icon: "sunrise.fill",
                            color: .orange,
                            supplements: morningSupplements,
                            onToggle: { viewModel.toggleSupplement($0) }
                        )
                    }

                    // Midi
                    if !noonSupplements.isEmpty {
                        SupplementGroupView(
                            title: "Midi",
                            icon: "sun.max.fill",
                            color: .yellow,
                            supplements: noonSupplements,
                            onToggle: { viewModel.toggleSupplement($0) }
                        )
                    }

                    // Soir
                    if !eveningSupplements.isEmpty {
                        SupplementGroupView(
                            title: "Soir",
                            icon: "moon.fill",
                            color: .indigo,
                            supplements: eveningSupplements,
                            onToggle: { viewModel.toggleSupplement($0) }
                        )
                    }
                }
                .padding(.top, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }

    // MARK: - Computed Properties

    private var allSupplements: [SupplementLog] {
        viewModel.currentDayLog?.supplements ?? []
    }

    private var morningSupplements: [SupplementLog] {
        allSupplements.filter { $0.timingSlot == .matin }
    }

    private var noonSupplements: [SupplementLog] {
        allSupplements.filter { $0.timingSlot == .midi }
    }

    private var eveningSupplements: [SupplementLog] {
        allSupplements.filter { $0.timingSlot == .soir }
    }

    private var totalSupplements: Int {
        viewModel.currentDayLog?.totalSupplementsCount ?? 0
    }

    private var completedSupplements: Int {
        viewModel.currentDayLog?.completedSupplementsCount ?? 0
    }

    private var supplementsProgress: Double {
        guard totalSupplements > 0 else { return 0 }
        return Double(completedSupplements) / Double(totalSupplements)
    }
}

// MARK: - Supplement Group View
struct SupplementGroupView: View {
    let title: String
    let icon: String
    let color: Color
    let supplements: [SupplementLog]
    let onToggle: (SupplementLog) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header du groupe
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Spacer()

                // Compteur du groupe
                let completed = supplements.filter { $0.isCompleted }.count
                Text("\(completed)/\(supplements.count)")
                    .font(.caption)
                    .foregroundColor(completed == supplements.count ? .appSuccess : .secondary)
            }
            .padding(.horizontal, 4)

            // Liste des compléments
            VStack(spacing: 6) {
                ForEach(supplements, id: \.id) { supplement in
                    SupplementRowView(supplement: supplement) {
                        onToggle(supplement)
                    }
                }
            }
        }
        .padding(12)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }
}

// MARK: - Supplement Row View
struct SupplementRowView: View {
    let supplement: SupplementLog
    let onToggle: () -> Void

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                onToggle()
            }
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            HStack(spacing: 10) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(supplement.isCompleted ? Color.appPrimary : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if supplement.isCompleted {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.appPrimary)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                // Icône
                Image(systemName: supplement.supplementType.icon)
                    .font(.system(size: 14))
                    .foregroundColor(supplement.isCompleted ? .appPrimary : .secondary)
                    .frame(width: 20)

                // Infos
                VStack(alignment: .leading, spacing: 1) {
                    Text(supplement.supplementType.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(supplement.isCompleted ? .secondary : .primary)
                        .strikethrough(supplement.isCompleted)

                    HStack(spacing: 4) {
                        Text(supplement.supplementType.dosage)
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        if let note = supplement.supplementType.note {
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(note)
                                .font(.caption2)
                                .foregroundColor(.appSecondary)
                        }
                    }
                }

                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(supplement.isCompleted ? Color.appPrimary.opacity(0.1) : Color.appCardBackground)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SupplementSectionView(viewModel: TodayViewModel())
        .padding()
        .background(Color.appGroupedBackground)
}
