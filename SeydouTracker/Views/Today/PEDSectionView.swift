import SwiftUI

struct PEDSectionView: View {
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
                HStack {
                    Image(systemName: "bolt.circle.fill")
                        .font(.title3)
                        .foregroundColor(.appAlert)

                    Text("PEDs")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    // Compteur
                    Text("\(completedPEDs)/\(totalPEDs)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(completedPEDs == totalPEDs && totalPEDs > 0 ? .appSuccess : .secondary)

                    // Mini barre de progression
                    ProgressView(value: pedsProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: completedPEDs == totalPEDs && totalPEDs > 0 ? .appSuccess : .appAlert))
                        .frame(width: 50)

                    // Chevron
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .animation(.spring(response: 0.3), value: isExpanded)
                }
            }
            .buttonStyle(.plain)

            // Contenu (collapsible)
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // Info semaine du cycle
                    if let cycle = viewModel.currentCycle {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.caption)
                                .foregroundColor(.appSecondary)

                            Text("Semaine \(cycle.currentWeek)/8")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("•")
                                .foregroundColor(.secondary)

                            Text("Matin au réveil")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.appAlert)
                        }
                        .padding(.horizontal, 4)
                    }

                    // Liste des PEDs
                    VStack(spacing: 8) {
                        ForEach(sortedPEDs, id: \.id) { ped in
                            PEDRowView(ped: ped, cycleWeek: viewModel.currentCycle?.currentWeek ?? 1) {
                                viewModel.togglePED(ped)
                            }
                        }
                    }

                    // Note d'avertissement
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.appWarning)

                        Text("Bilans sanguins recommandés : S4, S8, S12")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .background(Color.appWarning.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.top, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.appAlert.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Computed Properties

    private var sortedPEDs: [PEDLog] {
        let peds = viewModel.currentDayLog?.peds ?? []
        let order: [PEDType] = [.rad140, .cardarine, .albuterol, .enclomiphene]
        return peds.sorted { ped1, ped2 in
            let index1 = order.firstIndex(of: ped1.pedType) ?? 0
            let index2 = order.firstIndex(of: ped2.pedType) ?? 0
            return index1 < index2
        }
    }

    private var totalPEDs: Int {
        viewModel.currentDayLog?.totalPEDsCount ?? 0
    }

    private var completedPEDs: Int {
        viewModel.currentDayLog?.completedPEDsCount ?? 0
    }

    private var pedsProgress: Double {
        guard totalPEDs > 0 else { return 0 }
        return Double(completedPEDs) / Double(totalPEDs)
    }
}

// MARK: - PED Row View
struct PEDRowView: View {
    let ped: PEDLog
    let cycleWeek: Int
    let onToggle: () -> Void

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                onToggle()
            }
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }) {
            HStack(spacing: 12) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(ped.isCompleted ? Color.appAlert : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 26, height: 26)

                    if ped.isCompleted {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.appAlert)
                            .frame(width: 26, height: 26)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                // Icône
                Image(systemName: ped.pedType.icon)
                    .font(.system(size: 16))
                    .foregroundColor(ped.isCompleted ? .appAlert : .secondary)
                    .frame(width: 24)

                // Infos
                VStack(alignment: .leading, spacing: 2) {
                    Text(ped.pedType.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(ped.isCompleted ? .secondary : .primary)
                        .strikethrough(ped.isCompleted)

                    // Dosage avec indication de changement
                    HStack(spacing: 4) {
                        Text(ped.dosage)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.appAlert)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appAlert.opacity(0.15))
                            .cornerRadius(4)

                        // Indicateur si le dosage change bientôt
                        if let nextDosage = getNextDosageInfo(for: ped.pedType, currentWeek: cycleWeek) {
                            Text(nextDosage)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // Badge spécial pour Enclomiphène (S5+)
                if ped.pedType == .enclomiphene {
                    Text("S5+")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.appSecondary)
                        .cornerRadius(4)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(ped.isCompleted ? Color.appAlert.opacity(0.08) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(ped.isCompleted ? Color.appAlert.opacity(0.2) : Color.gray.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func getNextDosageInfo(for pedType: PEDType, currentWeek: Int) -> String? {
        switch pedType {
        case .rad140:
            if currentWeek == 4 { return "→ 15mg S5" }
        case .albuterol:
            if currentWeek == 2 { return "→ 8mg S3" }
            if currentWeek == 6 { return "→ 10mg S7" }
        default:
            break
        }
        return nil
    }
}

#Preview {
    PEDSectionView(viewModel: TodayViewModel())
        .padding()
        .background(Color.appGroupedBackground)
}
