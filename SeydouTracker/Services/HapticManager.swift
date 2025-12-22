import SwiftUI
import CoreHaptics

// MARK: - Haptic Manager
/// Service centralisé pour les retours haptiques de l'app
final class HapticManager {
    static let shared = HapticManager()

    private var engine: CHHapticEngine?

    private init() {
        prepareHaptics()
    }

    // MARK: - Engine Setup

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Error creating haptic engine: \(error)")
        }
    }

    // MARK: - Standard Haptics

    /// Impact léger - pour les sélections et toggles mineurs
    func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Impact medium - pour les toggles de repas/compléments
    func mediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Impact fort - pour les actions importantes
    func heavyImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Impact soft - pour les retours subtils
    func softImpact() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Impact rigid - pour les confirmations
    func rigidImpact() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        generator.impactOccurred()
    }

    // MARK: - Notification Haptics

    /// Succès - objectif atteint, tâche complétée
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    /// Erreur - action impossible
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }

    /// Avertissement - attention requise
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }

    // MARK: - Selection Haptics

    /// Sélection - changement de sélection dans une liste
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    // MARK: - Custom Haptics

    /// Pattern double tap - pour les confirmations d'actions importantes
    func doubleTap() {
        lightImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.lightImpact()
        }
    }

    /// Pattern success avec crescendo
    func successCrescendo() {
        softImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.mediumImpact()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.success()
        }
    }

    /// Pattern score 100% - célébration
    func celebration() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = engine else {
            success()
            return
        }

        var events = [CHHapticEvent]()

        // Pattern de célébration
        for i in stride(from: 0, to: 0.5, by: 0.1) {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.5 + i))
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(0.5 + i))
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: i)
            events.append(event)
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            success()
        }
    }

    /// Pattern eau - simulation goutte
    func waterDrop() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = engine else {
            softImpact()
            return
        }

        var events = [CHHapticEvent]()

        // Goutte qui tombe
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        events.append(event)

        // Petite ondulation
        let intensity2 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3)
        let sharpness2 = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
        let event2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity2, sharpness2], relativeTime: 0.1)
        events.append(event2)

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            softImpact()
        }
    }
}

// MARK: - View Extension pour faciliter l'accès
extension View {
    func hapticOnTap(_ type: HapticType = .light) -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    switch type {
                    case .light:
                        HapticManager.shared.lightImpact()
                    case .medium:
                        HapticManager.shared.mediumImpact()
                    case .heavy:
                        HapticManager.shared.heavyImpact()
                    case .success:
                        HapticManager.shared.success()
                    case .selection:
                        HapticManager.shared.selection()
                    }
                }
        )
    }
}

enum HapticType {
    case light
    case medium
    case heavy
    case success
    case selection
}
