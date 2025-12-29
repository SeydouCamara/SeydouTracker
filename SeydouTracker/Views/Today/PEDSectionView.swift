import SwiftUI

struct AdvancedSupplementSectionView: View {
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

                    Text("Suppléments")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    // Compteur
                    Text("\(completedSupplements)/\(totalSupplements)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(completedSupplements == totalSupplements && totalSupplements > 0 ? .appSuccess : .secondary)

                    // Mini barre de progression
                    ProgressView(value: supplementsProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: completedSupplements == totalSupplements && totalSupplements > 0 ? .appSuccess : .appAlert))
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

                    // Liste des suppléments
                    VStack(spacing: 8) {
                        ForEach(sortedSupplements, id: \.id) { supplement in
                            AdvancedSupplementRowView(supplement: supplement, cycleWeek: viewModel.currentCycle?.currentWeek ?? 1) {
                                viewModel.toggleAdvancedSupplement(supplement)
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

    private var sortedSupplements: [AdvancedSupplementLog] {
        let supplements = viewModel.currentDayLog?.advancedSupplements ?? []
        let order: [AdvancedSupplementType] = [.rad140, .cardarine, .albuterol, .enclomiphene]
        return supplements.sorted { s1, s2 in
            let index1 = order.firstIndex(of: s1.supplementType) ?? 0
            let index2 = order.firstIndex(of: s2.supplementType) ?? 0
            return index1 < index2
        }
    }

    private var totalSupplements: Int {
        viewModel.currentDayLog?.totalAdvancedSupplementsCount ?? 0
    }

    private var completedSupplements: Int {
        viewModel.currentDayLog?.completedAdvancedSupplementsCount ?? 0
    }

    private var supplementsProgress: Double {
        guard totalSupplements > 0 else { return 0 }
        return Double(completedSupplements) / Double(totalSupplements)
    }
}

// Alias pour compatibilité
typealias PEDSectionView = AdvancedSupplementSectionView

// MARK: - Advanced Supplement Row View
struct AdvancedSupplementRowView: View {
    let supplement: AdvancedSupplementLog
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
                        .stroke(supplement.isCompleted ? Color.appAlert : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 26, height: 26)

                    if supplement.isCompleted {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.appAlert)
                            .frame(width: 26, height: 26)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                // Icône
                Image(systemName: supplement.supplementType.icon)
                    .font(.system(size: 16))
                    .foregroundColor(supplement.isCompleted ? .appAlert : .secondary)
                    .frame(width: 24)

                // Infos
                VStack(alignment: .leading, spacing: 2) {
                    Text(supplement.supplementType.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(supplement.isCompleted ? .secondary : .primary)
                        .strikethrough(supplement.isCompleted)

                    // Dosage avec indication de changement
                    HStack(spacing: 4) {
                        Text(supplement.dosage)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.appAlert)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appAlert.opacity(0.15))
                            .cornerRadius(4)

                        // Indicateur si le dosage change bientôt
                        if let nextDosage = getNextDosageInfo(for: supplement.supplementType, currentWeek: cycleWeek) {
                            Text(nextDosage)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // Badge spécial pour Enclomiphène (S5+)
                if supplement.supplementType == .enclomiphene {
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
                    .fill(supplement.isCompleted ? Color.appAlert.opacity(0.08) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(supplement.isCompleted ? Color.appAlert.opacity(0.2) : Color.gray.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func getNextDosageInfo(for supplementType: AdvancedSupplementType, currentWeek: Int) -> String? {
        switch supplementType {
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

// Alias pour compatibilité
typealias PEDRowView = AdvancedSupplementRowView

#Preview {
    AdvancedSupplementSectionView(viewModel: TodayViewModel())
        .padding()
        .background(Color.appGroupedBackground)
}
