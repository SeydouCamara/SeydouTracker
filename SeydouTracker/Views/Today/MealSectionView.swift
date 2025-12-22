import SwiftUI

struct MealSectionView: View {
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
                    title: "Repas",
                    icon: "fork.knife",
                    iconColor: .appPrimary,
                    progress: mealsProgress,
                    total: totalMeals,
                    completed: completedMeals,
                    isExpanded: isExpanded
                )
            }
            .buttonStyle(.plain)

            // Liste des repas (collapsible)
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(sortedMeals, id: \.id) { meal in
                        MealRowView(meal: meal) {
                            viewModel.toggleMeal(meal)
                        }
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

    private var sortedMeals: [MealLog] {
        (viewModel.currentDayLog?.meals ?? []).sorted { meal1, meal2 in
            let order: [MealType] = [.repas1, .repas2, .repas3, .repas4, .preTraining, .postTraining, .repas5, .avantDodo]
            let index1 = order.firstIndex(of: meal1.mealType) ?? 0
            let index2 = order.firstIndex(of: meal2.mealType) ?? 0
            return index1 < index2
        }
    }

    private var totalMeals: Int {
        viewModel.currentDayLog?.totalMealsCount ?? 0
    }

    private var completedMeals: Int {
        viewModel.currentDayLog?.completedMealsCount ?? 0
    }

    private var mealsProgress: Double {
        guard totalMeals > 0 else { return 0 }
        return Double(completedMeals) / Double(totalMeals)
    }
}

// MARK: - Collapsible Section Header (Réutilisable)
struct CollapsibleSectionHeader: View {
    let title: String
    let icon: String
    let iconColor: Color
    let progress: Double
    let total: Int
    let completed: Int
    let isExpanded: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)

            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            // Compteur
            Text("\(completed)/\(total)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(completed == total && total > 0 ? .appSuccess : .secondary)

            // Mini barre de progression
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: completed == total && total > 0 ? .appSuccess : iconColor))
                .frame(width: 50)

            // Chevron
            Image(systemName: "chevron.down")
                .font(.caption)
                .foregroundColor(.secondary)
                .rotationEffect(.degrees(isExpanded ? 0 : -90))
                .animation(.spring(response: 0.3), value: isExpanded)
        }
    }
}

// MARK: - Meal Row View
struct MealRowView: View {
    let meal: MealLog
    let onToggle: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                onToggle()
            }
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }) {
            HStack(spacing: 12) {
                // Checkbox
                ZStack {
                    Circle()
                        .stroke(meal.isCompleted ? Color.appPrimary : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 28, height: 28)

                    if meal.isCompleted {
                        Circle()
                            .fill(Color.appPrimary)
                            .frame(width: 28, height: 28)

                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                // Icône du repas
                Image(systemName: meal.mealType.icon)
                    .font(.system(size: 16))
                    .foregroundColor(meal.isCompleted ? .appPrimary : .secondary)
                    .frame(width: 24)

                // Contenu
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(meal.mealType.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(meal.isCompleted ? .secondary : .primary)
                            .strikethrough(meal.isCompleted)

                        Spacer()

                        Text(meal.scheduledTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }

                    Text(meal.mealType.content)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(meal.isCompleted ? Color.appPrimary.opacity(0.08) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(meal.isCompleted ? Color.appPrimary.opacity(0.2) : Color.gray.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section Header (Pour compatibilité)
struct SectionHeader: View {
    let title: String
    let icon: String
    let progress: Double
    let total: Int
    let completed: Int

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.appPrimary)

            Text(title)
                .font(.headline)

            Spacer()

            // Compteur
            Text("\(completed)/\(total)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(completed == total && total > 0 ? .appSuccess : .secondary)

            // Mini barre de progression
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: completed == total && total > 0 ? .appSuccess : .appPrimary))
                .frame(width: 50)
        }
    }
}

#Preview {
    MealSectionView(viewModel: TodayViewModel())
        .padding()
        .background(Color.appGroupedBackground)
}
