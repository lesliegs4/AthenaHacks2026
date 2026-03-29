import Foundation

enum TLTriageStatus: String, CaseIterable, Identifiable {
    case stable = "Stable"
    case urgent = "Urgent"
    case critical = "Critical"

    var id: String { rawValue }
}

struct TLPatient: Identifiable, Hashable {
    let id: String
    var displayName: String
    var triage: TLTriageStatus
    var heartRate: Int
    var respRate: Int
    var confidence: Double // 0...1
    var notes: String
    var quickFlags: Set<TLQuickNote>
}

enum TLQuickNote: String, CaseIterable, Identifiable, Hashable {
    case unconscious = "Unconscious"
    case bleeding = "Bleeding"
    case difficultyBreathing = "Difficulty breathing"
    case chestPain = "Chest pain"
    case responsive = "Responsive"

    var id: String { rawValue }
}

struct TLIncident: Identifiable, Hashable {
    let id: UUID
    let date: Date
    var location: String
    var severity: TLTriageStatus
    var outcome: String
    var recordingAvailable: Bool
    var summary: String
    var vitalsHistory: [TLVitalsSample]
    var responderNotes: String
    var useForTraining: Bool
}

struct TLDispatchEvent: Identifiable, Hashable {
    let id: UUID
    let time: Date
    let title: String
    let detail: String
}

struct TLDispatchSubmission: Identifiable, Hashable {
    let id: UUID
    var location: String
    var severity: TLTriageStatus
    var unitRequested: String
    var patientSummary: String
    var vitalsSnapshot: String
    var timeline: [TLDispatchEvent]
}

struct TLVitalsSample: Identifiable, Hashable {
    let id = UUID()
    let t: Double
    let hr: Double
    let rr: Double
}

