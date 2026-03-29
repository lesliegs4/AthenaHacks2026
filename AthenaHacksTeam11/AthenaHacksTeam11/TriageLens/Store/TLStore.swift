import Foundation
import SwiftUI
import Combine

@MainActor
final class TLStore: ObservableObject {
    @Published var selectedRoute: TLRoute = .dashboard
    @Published var selectedIncident: TLIncident?

    @Published var activePatient: TLPatient
    @Published var massCasualtyPatients: [TLPatient]
    @Published var incidents: [TLIncident]
    @Published var dispatchDraft: TLDispatchSubmission

    @Published var isDispatchSent: Bool = false
    @Published var isProcessingVitals: Bool = false

    private var timer: Timer?
    private var t: Double = 0

    init() {
        self.activePatient = TLPatient(
            id: "P-0142",
            displayName: "Patient P-0142",
            triage: .urgent,
            heartRate: 104,
            respRate: 22,
            confidence: 0.72,
            notes: "",
            quickFlags: [.difficultyBreathing]
        )

        self.massCasualtyPatients = [
            TLPatient(id: "P-0101", displayName: "P-0101", triage: .critical, heartRate: 138, respRate: 30, confidence: 0.81, notes: "", quickFlags: [.bleeding]),
            TLPatient(id: "P-0112", displayName: "P-0112", triage: .urgent, heartRate: 118, respRate: 26, confidence: 0.68, notes: "", quickFlags: [.chestPain]),
            TLPatient(id: "P-0124", displayName: "P-0124", triage: .stable, heartRate: 84, respRate: 16, confidence: 0.62, notes: "", quickFlags: [.responsive]),
            TLPatient(id: "P-0130", displayName: "P-0130", triage: .critical, heartRate: 154, respRate: 34, confidence: 0.76, notes: "", quickFlags: [.unconscious]),
            TLPatient(id: "P-0137", displayName: "P-0137", triage: .urgent, heartRate: 112, respRate: 24, confidence: 0.70, notes: "", quickFlags: [.difficultyBreathing]),
        ]

        let now = Date()
        self.incidents = [
            TLIncident(
                id: UUID(),
                date: now.addingTimeInterval(-3600 * 2),
                location: "Pier 12, Bay District",
                severity: .critical,
                outcome: "Transported",
                recordingAvailable: true,
                summary: "Respiratory distress; rapid escalation; ALS requested.",
                vitalsHistory: TLStore.makeHistory(seed: 1),
                responderNotes: "Patient cyanotic on arrival. Oxygen + rapid assessment. Escalated within 60s.",
                useForTraining: true
            ),
            TLIncident(
                id: UUID(),
                date: now.addingTimeInterval(-3600 * 14),
                location: "I-10 Exit 42",
                severity: .urgent,
                outcome: "Stabilized",
                recordingAvailable: false,
                summary: "MVC with chest pain; stable vitals; continued monitoring.",
                vitalsHistory: TLStore.makeHistory(seed: 2),
                responderNotes: "No LOC. Pain 6/10. Monitored, no deterioration.",
                useForTraining: false
            ),
            TLIncident(
                id: UUID(),
                date: now.addingTimeInterval(-3600 * 40),
                location: "Elm & 4th",
                severity: .stable,
                outcome: "Released",
                recordingAvailable: true,
                summary: "Minor bleeding controlled; stable, responsive.",
                vitalsHistory: TLStore.makeHistory(seed: 3),
                responderNotes: "Wound cleaned and dressed. Provided instructions.",
                useForTraining: true
            ),
        ]

        self.dispatchDraft = TLDispatchSubmission(
            id: UUID(),
            location: "—",
            severity: .urgent,
            unitRequested: "ALS Unit",
            patientSummary: "Adult, difficulty breathing",
            vitalsSnapshot: "HR 104 • RR 22 • Conf 72%",
            timeline: []
        )
    }

    func startVitals() {
        guard timer == nil else { return }
        isProcessingVitals = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func stopVitals() {
        timer?.invalidate()
        timer = nil
        isProcessingVitals = false
    }

    private func tick() {
        t += 0.7
        let drift = sin(t / 3.5) * 6
        let noise = Double.random(in: -3...3)

        let baseHR: Double
        let baseRR: Double
        switch activePatient.triage {
        case .stable:
            baseHR = 82
            baseRR = 16
        case .urgent:
            baseHR = 108
            baseRR = 22
        case .critical:
            baseHR = 142
            baseRR = 30
        }

        let hr = Int(max(40, min(190, (baseHR + drift + noise).rounded())))
        let rr = Int(max(8, min(45, (baseRR + drift / 3 + Double.random(in: -2...2)).rounded())))
        let conf = max(0.35, min(0.96, activePatient.confidence + Double.random(in: -0.05...0.05)))

        activePatient.heartRate = hr
        activePatient.respRate = rr
        activePatient.confidence = conf

        dispatchDraft.vitalsSnapshot = "HR \(hr) • RR \(rr) • Conf \(Int(conf * 100))%"
    }

    func escalateToDispatch() {
        dispatchDraft.severity = activePatient.triage
        dispatchDraft.patientSummary = buildPatientSummary(activePatient)
        isDispatchSent = false

        let now = Date()
        dispatchDraft.timeline = [
            TLDispatchEvent(id: UUID(), time: now, title: "Draft created", detail: "Vitals snapshot attached"),
        ]
        selectedRoute = .dispatch
    }

    func sendDispatch() {
        let now = Date()
        dispatchDraft.timeline.append(TLDispatchEvent(id: UUID(), time: now, title: "Sent to dispatch", detail: "Unit: \(dispatchDraft.unitRequested)"))
        dispatchDraft.timeline.append(TLDispatchEvent(id: UUID(), time: now.addingTimeInterval(30), title: "Acknowledged", detail: "Dispatch confirmed receipt"))
        isDispatchSent = true

        let incident = TLIncident(
            id: UUID(),
            date: now,
            location: dispatchDraft.location.isEmpty ? "Unspecified location" : dispatchDraft.location,
            severity: dispatchDraft.severity,
            outcome: "Pending",
            recordingAvailable: true,
            summary: dispatchDraft.patientSummary,
            vitalsHistory: TLStore.makeHistory(seed: Int.random(in: 10...99)),
            responderNotes: activePatient.notes,
            useForTraining: false
        )
        incidents.insert(incident, at: 0)
    }

    func selectIncident(_ incident: TLIncident) {
        selectedIncident = incident
    }

    func updateTriage(for patientId: String, to status: TLTriageStatus) {
        if activePatient.id == patientId {
            activePatient.triage = status
            return
        }
        if let idx = massCasualtyPatients.firstIndex(where: { $0.id == patientId }) {
            massCasualtyPatients[idx].triage = status
        }
    }

    func sortedMassCasualty() -> [TLPatient] {
        massCasualtyPatients.sorted { lhs, rhs in
            TLStore.severityRank(lhs.triage) > TLStore.severityRank(rhs.triage)
        }
    }

    private static func severityRank(_ status: TLTriageStatus) -> Int {
        switch status {
        case .stable: return 0
        case .urgent: return 1
        case .critical: return 2
        }
    }

    private func buildPatientSummary(_ p: TLPatient) -> String {
        let flags = p.quickFlags.map(\.rawValue).sorted()
        let flagsText = flags.isEmpty ? "No flags" : flags.joined(separator: ", ")
        return "\(p.displayName): \(flagsText)"
    }

    private static func makeHistory(seed: Int) -> [TLVitalsSample] {
        var rng = SeededGenerator(seed: UInt64(seed))
        var out: [TLVitalsSample] = []
        var hr: Double = Double.random(in: 88...130, using: &rng)
        var rr: Double = Double.random(in: 14...28, using: &rng)
        for i in 0..<30 {
            hr = max(45, min(180, hr + Double.random(in: -4...4, using: &rng)))
            rr = max(8, min(40, rr + Double.random(in: -2...2, using: &rng)))
            out.append(TLVitalsSample(t: Double(i), hr: hr, rr: rr))
        }
        return out
    }
}

enum TLRoute: String, CaseIterable, Identifiable {
    case dashboard = "Landing / Dashboard"
    case liveAssessment = "Live Assessment"
    case massCasualty = "Mass Casualty Mode"
    case incidentLogs = "Incident Logs"
    case dispatch = "Dispatch"
    case trainingReview = "Training Review"

    var id: String { rawValue }
}

// Minimal deterministic generator so mock charts look consistent.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 0x12345678 : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

