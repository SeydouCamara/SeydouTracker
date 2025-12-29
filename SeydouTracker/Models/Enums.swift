import Foundation

// MARK: - Type de journée selon l'heure d'entraînement
enum DayType: String, CaseIterable, Codable {
    case soir = "SOIR"          // Entraînement 20h (Lundi, Mercredi, Jeudi)
    case midi = "MIDI"          // Entraînement 12h30 (Vendredi)
    case aprem = "APRÈS-MIDI"   // Entraînement 17h (Samedi)
    case repos = "REPOS"        // Jour de repos (Mardi, Dimanche)

    var displayName: String {
        switch self {
        case .soir: return "Soir (20h)"
        case .midi: return "Midi (12h30)"
        case .aprem: return "Après-midi (17h)"
        case .repos: return "Repos"
        }
    }

    var trainingTime: String {
        switch self {
        case .soir: return "20h00"
        case .midi: return "12h30"
        case .aprem: return "17h00"
        case .repos: return "—"
        }
    }
}

// MARK: - Types de repas
enum MealType: String, CaseIterable, Codable {
    case repas1 = "REPAS_1"
    case repas2 = "REPAS_2"
    case repas3 = "REPAS_3"
    case repas4 = "REPAS_4"
    case preTraining = "PRE_TRAINING"
    case postTraining = "POST_TRAINING"
    case repas5 = "REPAS_5"
    case avantDodo = "AVANT_DODO"

    var displayName: String {
        switch self {
        case .repas1: return "Repas 1"
        case .repas2: return "Repas 2"
        case .repas3: return "Repas 3"
        case .repas4: return "Repas 4"
        case .preTraining: return "Pré-training"
        case .postTraining: return "Post-training"
        case .repas5: return "Repas 5"
        case .avantDodo: return "Avant dodo"
        }
    }

    var content: String {
        switch self {
        case .repas1: return "Eau tiède + citron + 2 steaks 5% + 3 blancs d'œuf"
        case .repas2: return "140g poulet + ½ avocat"
        case .repas3: return "140g poulet + 100g riz basmati cuit"
        case .repas4: return "6 blancs d'œufs + 3 galettes de riz"
        case .preTraining: return "1 banane + 1 scoop isolate"
        case .postTraining: return "2 compotes + 2 scoops isolate"
        case .repas5: return "2 steaks 5% + 200g légumes crucifères"
        case .avantDodo: return "Fromage blanc 0% + thon + épinards + noix pécan"
        }
    }

    var icon: String {
        switch self {
        case .repas1: return "sunrise"
        case .repas2: return "sun.min"
        case .repas3: return "sun.max"
        case .repas4: return "cloud.sun"
        case .preTraining: return "figure.run"
        case .postTraining: return "figure.cooldown"
        case .repas5: return "moon.haze"
        case .avantDodo: return "moon.zzz"
        }
    }

    // Horaires pour journée SOIR (20h)
    func scheduledTime(for dayType: DayType) -> String {
        switch dayType {
        case .soir:
            switch self {
            case .repas1: return "07:00"
            case .repas2: return "10:00"
            case .repas3: return "13:00"
            case .repas4: return "16:00"
            case .preTraining: return "19:50"
            case .postTraining: return "21:15"
            case .repas5: return "22:00"
            case .avantDodo: return "23:30"
            }
        case .midi:
            switch self {
            case .repas1: return "07:00"
            case .repas2: return "09:30"
            case .repas3: return "12:00"
            case .preTraining: return "12:20"
            case .postTraining: return "13:45"
            case .repas4: return "16:00"
            case .repas5: return "19:00"
            case .avantDodo: return "22:00"
            }
        case .aprem:
            switch self {
            case .repas1: return "07:00"
            case .repas2: return "10:00"
            case .repas3: return "13:00"
            case .preTraining: return "16:50"
            case .postTraining: return "18:15"
            case .repas4: return "19:00"
            case .repas5: return "21:00"
            case .avantDodo: return "23:00"
            }
        case .repos:
            switch self {
            case .repas1: return "08:00"
            case .repas2: return "10:30"
            case .repas3: return "13:00"
            case .repas4: return "16:00"
            case .preTraining: return "—"
            case .postTraining: return "—"
            case .repas5: return "19:00"
            case .avantDodo: return "22:00"
            }
        }
    }

    // Les jours de repos n'ont pas de pré/post training
    func isAvailable(for dayType: DayType) -> Bool {
        if dayType == .repos {
            return self != .preTraining && self != .postTraining
        }
        return true
    }
}

// MARK: - Types de compléments
enum SupplementType: String, CaseIterable, Codable {
    case zinc = "ZINC"
    case vitD3 = "VIT_D3"
    case fishOil = "FISH_OIL"
    case nac = "NAC"
    case taurine = "TAURINE"
    case magnesium = "MAGNESIUM"

    var displayName: String {
        switch self {
        case .zinc: return "Zinc (picolinate)"
        case .vitD3: return "Vitamine D3"
        case .fishOil: return "Fish Oil (Oméga 3)"
        case .nac: return "NAC"
        case .taurine: return "Taurine"
        case .magnesium: return "Magnésium B6"
        }
    }

    var dosage: String {
        switch self {
        case .zinc: return "25-30mg"
        case .vitD3: return "5000-10000 UI"
        case .fishOil: return "2 capsules"
        case .nac: return "500mg"
        case .taurine: return "3-5g"
        case .magnesium: return "1 dose"
        }
    }

    var timingSlots: [TimingSlot] {
        switch self {
        case .zinc: return [.soir]
        case .vitD3: return [.matin]  // Avec repas 2 (avocat)
        case .fishOil: return [.matin, .midi, .soir]
        case .nac: return [.matin, .soir]
        case .taurine: return [.matin]
        case .magnesium: return [.soir]
        }
    }

    var icon: String {
        switch self {
        case .zinc: return "pill"
        case .vitD3: return "sun.max"
        case .fishOil: return "drop"
        case .nac: return "cross.vial"
        case .taurine: return "bolt"
        case .magnesium: return "moon.stars"
        }
    }

    var note: String? {
        switch self {
        case .vitD3: return "Avec avocat (Repas 2)"
        case .zinc, .magnesium: return "Avant dodo"
        default: return nil
        }
    }
}

// MARK: - Créneaux horaires pour compléments
enum TimingSlot: String, CaseIterable, Codable {
    case matin = "MATIN"
    case midi = "MIDI"
    case soir = "SOIR"

    var displayName: String {
        switch self {
        case .matin: return "Matin"
        case .midi: return "Midi"
        case .soir: return "Soir"
        }
    }

    var icon: String {
        switch self {
        case .matin: return "sunrise"
        case .midi: return "sun.max"
        case .soir: return "moon"
        }
    }
}

// MARK: - Types de Suppléments Avancés (anciennement PEDs)
enum AdvancedSupplementType: String, CaseIterable, Codable {
    case rad140 = "RAD_140"
    case cardarine = "CARDARINE"
    case albuterol = "ALBUTEROL"
    case enclomiphene = "ENCLOMIPHENE"

    var displayName: String {
        switch self {
        case .rad140: return "RAD-140"
        case .cardarine: return "Cardarine"
        case .albuterol: return "Albuterol"
        case .enclomiphene: return "Enclomiphène"
        }
    }

    var timing: String {
        return "Matin au réveil"
    }

    var icon: String {
        switch self {
        case .rad140: return "bolt.circle"
        case .cardarine: return "flame"
        case .albuterol: return "wind"
        case .enclomiphene: return "arrow.up.heart"
        }
    }

    // Dosage selon la semaine du cycle (1-8)
    func dosage(forWeek week: Int) -> String? {
        switch self {
        case .rad140:
            return week <= 4 ? "10mg" : "15mg"
        case .cardarine:
            return "20mg"
        case .albuterol:
            if week <= 2 { return "4mg" }
            else if week <= 4 { return "8mg" }
            else if week <= 6 { return "8mg" }
            else { return "10mg" }
        case .enclomiphene:
            return week >= 5 ? "12.5mg" : nil  // Commence semaine 5
        }
    }

    // Est-ce que ce supplément est actif cette semaine ?
    func isActive(forWeek week: Int) -> Bool {
        if self == .enclomiphene {
            return week >= 5
        }
        return true
    }
}

// Alias pour compatibilité
typealias PEDType = AdvancedSupplementType
