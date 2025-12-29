import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TodayViewModel()
    @AppStorage("hideAdvancedSupplements") private var hideAdvancedSupplements = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Card
                    HeaderCard(viewModel: viewModel)

                    // Section Repas
                    MealSectionView(viewModel: viewModel)

                    // Section Compléments
                    SupplementSectionView(viewModel: viewModel)

                    // Section Suppléments (anciennement PEDs) - masquable
                    if !hideAdvancedSupplements {
                        AdvancedSupplementSectionView(viewModel: viewModel)
                    }

                    // Trackers Eau & Sommeil
                    TrackersView(viewModel: viewModel)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color.appGroupedBackground)
            .navigationTitle("Aujourd'hui")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            viewModel.setup(modelContext: modelContext)
        }
    }
}

// MARK: - Header Card
struct HeaderCard: View {
    @Bindable var viewModel: TodayViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Date et Score
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.formattedDate)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(viewModel.cycleWeekDisplay)
                        .font(.subheadline)
                        .foregroundColor(.appSecondary)
                }

                Spacer()

                // Score circulaire
                ScoreCircle(score: viewModel.dailyScore, color: viewModel.scoreColor)
            }

            Divider()

            // Sélecteur de type de journée
            VStack(alignment: .leading, spacing: 8) {
                Text("Type de journée")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                DayTypePicker(selectedDayType: Binding(
                    get: { viewModel.selectedDayType },
                    set: { viewModel.changeDayType(to: $0) }
                ))
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Score Circle
struct ScoreCircle: View {
    let score: Int
    let color: Color

    @State private var animatedScore: CGFloat = 0
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 8)
                .frame(width: 70, height: 70)

            // Progress circle with gradient animation
            Circle()
                .trim(from: 0, to: animatedScore / 100)
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.5), color],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 70, height: 70)
                .rotationEffect(.degrees(-90))

            // Glow effect when score is high
            if score >= 80 {
                Circle()
                    .stroke(color, lineWidth: 2)
                    .frame(width: 78, height: 78)
                    .opacity(isPulsing ? 0.6 : 0)
                    .scaleEffect(isPulsing ? 1.1 : 1.0)
            }

            // Score text
            VStack(spacing: 0) {
                Text("\(Int(animatedScore))%")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                    .contentTransition(.numericText())
            }

            // Celebration particles when 100%
            if score == 100 {
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(color)
                        .frame(width: 4, height: 4)
                        .offset(y: isPulsing ? -45 : -35)
                        .rotationEffect(.degrees(Double(index) * 60))
                        .opacity(isPulsing ? 0 : 1)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedScore = CGFloat(score)
            }
            if score >= 80 {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
        .onChange(of: score) { oldValue, newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedScore = CGFloat(newValue)
            }
            if newValue == 100 && oldValue < 100 {
                HapticManager.shared.celebration()
            } else if newValue >= 80 && oldValue < 80 {
                HapticManager.shared.success()
            }
        }
    }
}

// MARK: - Day Type Picker
struct DayTypePicker: View {
    @Binding var selectedDayType: DayType

    var body: some View {
        HStack(spacing: 8) {
            ForEach(DayType.allCases, id: \.self) { dayType in
                DayTypeButton(
                    dayType: dayType,
                    isSelected: selectedDayType == dayType,
                    action: { selectedDayType = dayType }
                )
            }
        }
    }
}

struct DayTypeButton: View {
    let dayType: DayType
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticManager.shared.selection()
            action()
        }) {
            VStack(spacing: 4) {
                Text(dayType.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .medium)

                Text(dayType.trainingTime)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [Color.appPrimary, Color.appPrimary.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    } else {
                        Color.appCardBackground
                    }
                }
            )
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(.plain)
        .pressEvents {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = false
            }
        }
    }
}

// MARK: - Press Events Modifier
struct PressEventsModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Coming Soon Card (Placeholder)
struct ComingSoonCard: View {
    let title: String
    let phase: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.appPrimary)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(phase)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "clock")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [DayLog.self, MealLog.self, SupplementLog.self, PEDLog.self, Cycle.self])
}
