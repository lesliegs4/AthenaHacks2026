import SwiftUI
import Combine

struct TLMassCasualtyView: View {
    var body: some View {
        MassCasualityModeView()
    }
}

struct TLIncidentLogsView: View {
    var body: some View {
        TLTrainingReviewView()
    }
}

struct TLTrainingReviewView: View {
    @EnvironmentObject private var store: TLStore

    @State private var isLoading: Bool = true
    @State private var selection: TLIncidentSelection? = nil
    @State private var filter: TLTrainingReviewFilter = .all
    @State private var searchText: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TLTheme.Spacing.lg) {
                TLSectionHeader(
                    title: "Incident Logs / Training Review",
                    subtitle: "Review saved incidents, replay vitals, and tag cases for training."
                )

                metricsRow

                filterRow

                if isLoading {
                    loadingGrid
                        .transition(.opacity)
                } else if filteredIncidents.isEmpty {
                    emptyState
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    incidentsGrid
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                TLDisclaimerFooter()
                    .padding(.horizontal, -TLTheme.Spacing.lg)
                    .padding(.bottom, -TLTheme.Spacing.lg)
            }
            .padding(TLTheme.Spacing.lg)
        }
        .task {
            guard isLoading else { return }
            try? await Task.sleep(nanoseconds: 650_000_000)
            withAnimation(.easeInOut(duration: 0.2)) {
                isLoading = false
            }
        }
        .sheet(item: $selection) { selection in
            TLTrainingReviewSheetHost(incidentId: selection.incidentId)
        }
        .animation(.easeInOut(duration: 0.2), value: filter)
        .animation(.easeInOut(duration: 0.2), value: searchText)
    }

    private var metricsRow: some View {
        let total = store.incidents.count
        let recordings = store.incidents.filter(\.recordingAvailable).count
        let training = store.incidents.filter(\.useForTraining).count
        let critical = store.incidents.filter { $0.severity == .critical }.count

        let cols = [GridItem(.adaptive(minimum: 240), spacing: TLTheme.Spacing.md)]
        return LazyVGrid(columns: cols, spacing: TLTheme.Spacing.md) {
            TLMetricCard(title: "Saved logs", value: "\(total)", footnote: "mock data", tint: TLTheme.ColorToken.blue, icon: "tray.full.fill")
            TLMetricCard(title: "Recordings", value: "\(recordings)", footnote: "available", tint: TLTheme.ColorToken.green, icon: "play.rectangle.fill")
            TLMetricCard(title: "Training tagged", value: "\(training)", footnote: "use for review", tint: TLTheme.ColorToken.amber, icon: "tag.fill")
            TLMetricCard(title: "Critical cases", value: "\(critical)", footnote: "high priority", tint: TLTheme.ColorToken.red, icon: "exclamationmark.triangle.fill")
        }
    }

    private var filterRow: some View {
        VStack(alignment: .leading, spacing: TLTheme.Spacing.md) {
            HStack(spacing: 10) {
                ForEach(TLTrainingReviewFilter.allCases) { f in
                    TLChip(text: f.label, isSelected: filter == f, tint: TLTheme.ColorToken.surface) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            filter = f
                        }
                    }
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(TLTheme.ColorToken.textTertiary)
                TextField("Search by location or outcome", text: $searchText)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(false)
                    .foregroundStyle(TLTheme.ColorToken.text)
                if !searchText.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            searchText = ""
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(TLTheme.ColorToken.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(12)
            .background(TLTheme.ColorToken.surface2)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .tlCard()
    }

    private var incidentsGrid: some View {
        let cols = [GridItem(.adaptive(minimum: 320), spacing: TLTheme.Spacing.md)]
        return LazyVGrid(columns: cols, spacing: TLTheme.Spacing.md) {
            ForEach(filteredIncidents) { incident in
                Button {
                    selection = TLIncidentSelection(incidentId: incident.id)
                } label: {
                    TLIncidentLogCard(incident: incident)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var loadingGrid: some View {
        let cols = [GridItem(.adaptive(minimum: 320), spacing: TLTheme.Spacing.md)]
        return LazyVGrid(columns: cols, spacing: TLTheme.Spacing.md) {
            ForEach(0..<6, id: \.self) { _ in
                TLIncidentLogCard(incident: TLTrainingReviewMock.placeholderIncident())
                    .redacted(reason: .placeholder)
                    .overlay(alignment: .topTrailing) {
                        ProgressView()
                            .tint(TLTheme.ColorToken.textTertiary)
                            .padding(12)
                    }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No matching incidents")
                .font(.headline.weight(.semibold))
                .foregroundStyle(TLTheme.ColorToken.text)
            Text("Try clearing filters, searching a different location, or tag more cases for review.")
                .font(.subheadline)
                .foregroundStyle(TLTheme.ColorToken.textSecondary)
            HStack(spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        filter = .all
                        searchText = ""
                    }
                } label: {
                    Label("Clear filters", systemImage: "arrow.counterclockwise")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .tint(TLTheme.ColorToken.surface2)
            }
            .padding(.top, 6)
        }
        .tlCard()
    }

    private var filteredIncidents: [TLIncident] {
        var base = store.incidents
        switch filter {
        case .all:
            break
        case .recording:
            base = base.filter(\.recordingAvailable)
        case .trainingTagged:
            base = base.filter(\.useForTraining)
        case .criticalOnly:
            base = base.filter { $0.severity == .critical }
        }

        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            base = base.filter { i in
                i.location.lowercased().contains(q) ||
                i.outcome.lowercased().contains(q) ||
                i.summary.lowercased().contains(q)
            }
        }
        return base.sorted { $0.date > $1.date }
    }

    private func incidentBinding(for id: UUID) -> Binding<TLIncident>? {
        guard store.incidents.contains(where: { $0.id == id }) else { return nil }
        return Binding(
            get: { store.incidents.first(where: { $0.id == id })! },
            set: { updated in
                if let idx = store.incidents.firstIndex(where: { $0.id == id }) {
                    store.incidents[idx] = updated
                }
            }
        )
    }
}

private struct TLTrainingReviewSheetHost: View {
    @EnvironmentObject private var store: TLStore
    let incidentId: UUID

    var body: some View {
        Group {
            if let binding = incidentBinding(for: incidentId) {
                TLTrainingReviewDetailSheet(incident: binding)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            } else {
                TLTrainingReviewMissingIncidentSheet()
                    .presentationDetents([.medium])
            }
        }
    }

    private func incidentBinding(for id: UUID) -> Binding<TLIncident>? {
        guard store.incidents.contains(where: { $0.id == id }) else { return nil }
        return Binding(
            get: { store.incidents.first(where: { $0.id == id })! },
            set: { updated in
                if let idx = store.incidents.firstIndex(where: { $0.id == id }) {
                    store.incidents[idx] = updated
                }
            }
        )
    }
}

private struct TLTrainingReviewMissingIncidentSheet: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Incident unavailable")
                .font(.headline.weight(.semibold))
                .foregroundStyle(TLTheme.ColorToken.text)
            Text("This incident is no longer in the log.")
                .font(.subheadline)
                .foregroundStyle(TLTheme.ColorToken.textSecondary)
        }
        .padding()
    }
}

// MARK: - Incident log card

private struct TLIncidentLogCard: View {
    let incident: TLIncident

    private var recordingTint: Color {
        incident.recordingAvailable ? TLTheme.ColorToken.green : TLTheme.ColorToken.textTertiary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                TLTriageBadge(status: incident.severity)

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 6) {
                    TLStatusPill(
                        icon: incident.recordingAvailable ? "play.fill" : "play.slash.fill",
                        text: incident.recordingAvailable ? "Recording" : "No recording",
                        tint: recordingTint
                    )
                    if incident.useForTraining {
                        TLStatusPill(icon: "tag.fill", text: "Training", tint: TLTheme.ColorToken.amber)
                    }
                }
            }

            Text(incident.location)
                .font(.headline.weight(.semibold))
                .foregroundStyle(TLTheme.ColorToken.text)
                .lineLimit(2)

            Text(incident.summary)
                .font(.subheadline)
                .foregroundStyle(TLTheme.ColorToken.textSecondary)
                .lineLimit(2)

            HStack(spacing: 12) {
                Label(incident.date.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(TLTheme.ColorToken.textTertiary)

                Spacer(minLength: 0)

                Text("Outcome: \(incident.outcome)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TLTheme.ColorToken.textSecondary)
                    .lineLimit(1)
            }

            TLSeverityBar(status: incident.severity)
        }
        .tlCard()
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "chevron.up.right")
                .foregroundStyle(TLTheme.ColorToken.textTertiary)
                .font(.caption.weight(.semibold))
                .padding(14)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(incident.location), \(incident.severity.rawValue), \(incident.recordingAvailable ? "recording available" : "no recording")")
    }
}

private struct TLStatusPill: View {
    let icon: String
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(tint.opacity(0.14))
        .overlay(
            RoundedRectangle(cornerRadius: 999)
                .stroke(tint.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 999))
    }
}

private struct TLSeverityBar: View {
    let status: TLTriageStatus

    private var value: Double {
        switch status {
        case .stable: return 0.33
        case .urgent: return 0.66
        case .critical: return 1.0
        }
    }

    private var tint: Color {
        switch status {
        case .stable: return TLTheme.ColorToken.green
        case .urgent: return TLTheme.ColorToken.amber
        case .critical: return TLTheme.ColorToken.red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Severity")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TLTheme.ColorToken.textSecondary)
                Spacer(minLength: 0)
                Text(status.rawValue)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 999)
                        .fill(TLTheme.ColorToken.surface2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 999)
                                .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
                        )
                    RoundedRectangle(cornerRadius: 999)
                        .fill(tint)
                        .frame(width: max(10, geo.size.width * value))
                        .animation(.easeInOut(duration: 0.35), value: value)
                }
            }
            .frame(height: 10)
        }
        .padding(.top, 4)
    }
}

// MARK: - Detail sheet

private struct TLTrainingReviewDetailSheet: View {
    @Binding var incident: TLIncident

    @Environment(\.dismiss) private var dismiss
    @State private var showSavedBanner: Bool = false
    @State private var isDetailLoading: Bool = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TLTheme.Spacing.lg) {
                    headerCard

                    if isDetailLoading {
                        TLPlaybackPlaceholder(isAvailable: incident.recordingAvailable, isLoading: true)
                            .redacted(reason: .placeholder)
                            .transition(.opacity)
                    } else {
                        TLPlaybackPlaceholder(isAvailable: incident.recordingAvailable, isLoading: false)
                            .transition(.opacity)
                    }

                    timelineCard

                    TLPatientsInvolvedCard(seed: incident.id, severity: incident.severity)

                    TLAnimatedVitalsHistoryCard(baseHistory: incident.vitalsHistory, seed: incident.id)

                    notesCard

                    trainingTagCard

                    dispatchFollowupCard

                    TLDisclaimerFooter()
                        .padding(.horizontal, -TLTheme.Spacing.lg)
                        .padding(.bottom, -TLTheme.Spacing.lg)
                }
                .padding(TLTheme.Spacing.lg)
            }
            .navigationTitle("Training Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.headline.weight(.semibold))
                }
            }
        }
        .task {
            guard isDetailLoading else { return }
            try? await Task.sleep(nanoseconds: 350_000_000)
            withAnimation(.easeInOut(duration: 0.2)) {
                isDetailLoading = false
            }
        }
        .overlay(alignment: .top) {
            if showSavedBanner {
                TLSuccessBanner(text: "Saved for training review")
                    .padding(.horizontal, TLTheme.Spacing.lg)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showSavedBanner)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(incident.location)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(TLTheme.ColorToken.text)
                    Text(incident.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(TLTheme.ColorToken.textSecondary)
                }

                Spacer(minLength: 0)

                TLTriageBadge(status: incident.severity, isLarge: true)
            }

            HStack(spacing: 10) {
                TLStatusPill(icon: "checkmark.circle.fill", text: incident.outcome, tint: TLTheme.ColorToken.blue)
                TLStatusPill(
                    icon: incident.recordingAvailable ? "video.fill" : "video.slash.fill",
                    text: incident.recordingAvailable ? "Recording available" : "No recording",
                    tint: incident.recordingAvailable ? TLTheme.ColorToken.green : TLTheme.ColorToken.textTertiary
                )
                Spacer(minLength: 0)
            }
        }
        .tlCard()
    }

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: TLTheme.Spacing.md) {
            TLSectionHeader(title: "Assessment timeline", subtitle: "Key events captured for review")
            VStack(alignment: .leading, spacing: 0) {
                let events = TLTrainingReviewMock.timeline(for: incident).sorted { $0.time < $1.time }
                ForEach(Array(events.enumerated()), id: \.element.id) { idx, e in
                    TLTimelineRow(
                        time: e.timeLabel,
                        title: e.title,
                        detail: e.detail,
                        tint: e.tint,
                        isFirst: idx == 0,
                        isLast: idx == events.count - 1
                    )
                }
            }
            .padding(.top, 4)
        }
        .tlCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: TLTheme.Spacing.md) {
            TLSectionHeader(title: "Notes from responder", subtitle: "Context for debrief and QA")
            Text(incident.responderNotes.isEmpty ? "No notes recorded." : incident.responderNotes)
                .font(.subheadline)
                .foregroundStyle(incident.responderNotes.isEmpty ? TLTheme.ColorToken.textTertiary : TLTheme.ColorToken.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .tlCard()
    }

    private var trainingTagCard: some View {
        VStack(alignment: .leading, spacing: TLTheme.Spacing.md) {
            TLSectionHeader(title: "Training tag", subtitle: "Mark cases for coaching and simulation review")

            Toggle(isOn: trainingBinding) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Use for training review")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(TLTheme.ColorToken.text)
                    Text("Adds this incident to review queues and scenario libraries.")
                        .font(.caption)
                        .foregroundStyle(TLTheme.ColorToken.textSecondary)
                }
            }
            .tint(TLTheme.ColorToken.amber)
        }
        .tlCard()
    }

    private var dispatchFollowupCard: some View {
        TLDispatchFollowupCard(location: incident.location, severity: incident.severity)
            .tlCard()
    }

    private var trainingBinding: Binding<Bool> {
        Binding(
            get: { incident.useForTraining },
            set: { setUseForTraining($0) }
        )
    }

    private func setUseForTraining(_ newValue: Bool) {
        withAnimation(.easeInOut(duration: 0.15)) {
            incident.useForTraining = newValue
        }
        guard newValue else { return }
        flashSavedBanner()
    }

    private func flashSavedBanner() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showSavedBanner = true
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_150_000_000)
            withAnimation(.easeInOut(duration: 0.2)) {
                showSavedBanner = false
            }
        }
    }
}

private struct TLSuccessBanner: View {
    let text: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(TLTheme.ColorToken.green)
                .font(.headline.weight(.bold))
            Text(text)
                .font(.headline.weight(.semibold))
                .foregroundStyle(TLTheme.ColorToken.text)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(TLTheme.ColorToken.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct TLPlaybackPlaceholder: View {
    let isAvailable: Bool
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: TLTheme.Spacing.md) {
            HStack {
                TLSectionHeader(title: "Playback", subtitle: "Recording area placeholder")
                Spacer(minLength: 0)
                TLStatusPill(
                    icon: isAvailable ? "video.fill" : "video.slash.fill",
                    text: isAvailable ? "Available" : "Unavailable",
                    tint: isAvailable ? TLTheme.ColorToken.green : TLTheme.ColorToken.textTertiary
                )
            }

            ZStack {
                RoundedRectangle(cornerRadius: TLTheme.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [TLTheme.ColorToken.surface2, Color.black, TLTheme.ColorToken.surface2],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: TLTheme.cornerRadius)
                    .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)

                VStack(spacing: 10) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.title.weight(.semibold))
                        .foregroundStyle(isAvailable ? TLTheme.ColorToken.green : TLTheme.ColorToken.textSecondary)
                    Text(isLoading ? "Loading preview…" : (isAvailable ? "Playback preview" : "Recording not captured"))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(TLTheme.ColorToken.text)
                    Text("Placeholder only • integrate secure playback later")
                        .font(.footnote)
                        .foregroundStyle(TLTheme.ColorToken.textSecondary)
                }
                .padding(18)
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding()

                if isLoading {
                    ProgressView()
                        .tint(TLTheme.ColorToken.textSecondary)
                        .scaleEffect(1.1)
                }
            }
            .frame(height: 220)
            .opacity(isAvailable ? 1 : 0.92)
        }
        .tlCard()
    }
}

// MARK: - Timeline row

private struct TLReviewEvent: Identifiable, Hashable {
    let id: UUID
    let time: Date
    let timeLabel: String
    let title: String
    let detail: String
    let tint: Color
}

private struct TLTimelineRow: View {
    let time: String
    let title: String
    let detail: String
    let tint: Color
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(TLTheme.ColorToken.stroke)
                        .frame(width: 2, height: 10)
                } else {
                    Spacer().frame(height: 10)
                }

                Circle()
                    .fill(tint.opacity(0.92))
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(TLTheme.ColorToken.stroke, lineWidth: 1))

                if !isLast {
                    Rectangle()
                        .fill(TLTheme.ColorToken.stroke)
                        .frame(width: 2, height: 34)
                } else {
                    Spacer().frame(height: 34)
                }
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Text(time)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TLTheme.ColorToken.textTertiary)
                        .monospacedDigit()
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TLTheme.ColorToken.text)
                    Spacer(minLength: 0)
                }
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(TLTheme.ColorToken.textSecondary)
            }
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Patient cards (mock)

private struct TLPatientsInvolvedCard: View {
    let seed: UUID
    let severity: TLTriageStatus

    private var patients: [TLPatient] {
        TLTrainingReviewMock.patients(for: seed, severity: severity)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TLTheme.Spacing.md) {
            TLSectionHeader(title: "Patients involved", subtitle: "Mock patients for training context")

            let cols = [GridItem(.adaptive(minimum: 240), spacing: TLTheme.Spacing.md)]
            LazyVGrid(columns: cols, spacing: TLTheme.Spacing.md) {
                ForEach(patients) { p in
                    TLPatientCard(patient: p)
                }
            }
        }
        .tlCard()
    }
}

private struct TLPatientCard: View {
    let patient: TLPatient

    private var tint: Color {
        switch patient.triage {
        case .stable: return TLTheme.ColorToken.green
        case .urgent: return TLTheme.ColorToken.amber
        case .critical: return TLTheme.ColorToken.red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(patient.displayName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(TLTheme.ColorToken.text)
                Spacer(minLength: 0)
                TLTriageBadge(status: patient.triage)
            }

            HStack(spacing: 12) {
                TLKeyValuePill(key: "HR", value: "\(patient.heartRate) bpm", tint: TLTheme.ColorToken.red)
                TLKeyValuePill(key: "RR", value: "\(patient.respRate) rpm", tint: TLTheme.ColorToken.blue)
            }

            TLProgressBar(label: "Confidence", value: patient.confidence, tint: tint)
        }
        .padding(12)
        .background(TLTheme.ColorToken.surface2)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct TLKeyValuePill: View {
    let key: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(key)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TLTheme.ColorToken.textSecondary)
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(tint.opacity(0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 999)
                .stroke(tint.opacity(0.30), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 999))
    }
}

private struct TLProgressBar: View {
    let label: String
    let value: Double // 0..1
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TLTheme.ColorToken.textSecondary)
                Spacer(minLength: 0)
                Text("\(Int(max(0, min(1, value)) * 100))%")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TLTheme.ColorToken.textTertiary)
                    .monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 999)
                        .fill(TLTheme.ColorToken.surface)
                        .overlay(RoundedRectangle(cornerRadius: 999).stroke(TLTheme.ColorToken.stroke, lineWidth: 1))
                    RoundedRectangle(cornerRadius: 999)
                        .fill(tint)
                        .frame(width: max(8, geo.size.width * max(0, min(1, value))))
                        .animation(.easeInOut(duration: 0.35), value: value)
                }
            }
            .frame(height: 10)
        }
    }
}

// MARK: - Animated vitals chart

private struct TLAnimatedVitalsHistoryCard: View {
    let baseHistory: [TLVitalsSample]
    let seed: UUID

    @State private var isLive: Bool = true
    @State private var samples: [TLVitalsSample] = []

    var body: some View {
        VStack(alignment: .leading, spacing: TLTheme.Spacing.md) {
            HStack(alignment: .top) {
                TLSectionHeader(title: "Vitals history", subtitle: "Dynamic replay (mock)")
                Spacer(minLength: 0)
                Toggle(isOn: $isLive) {
                    Text("Live")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TLTheme.ColorToken.textSecondary)
                }
                .toggleStyle(.switch)
                .tint(TLTheme.ColorToken.green)
            }

            TLLineChart(series: chartSeries)
            .frame(height: 180)
            .padding(12)
            .background(TLTheme.ColorToken.surface2)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))

            HStack(spacing: 12) {
                TLStatusPill(icon: "heart.fill", text: "HR", tint: TLTheme.ColorToken.red)
                TLStatusPill(icon: "lungs.fill", text: "RR", tint: TLTheme.ColorToken.blue)
                Spacer(minLength: 0)
                if let last = samples.last {
                    Text("Latest: HR \(Int(last.hr)) • RR \(Int(last.rr))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TLTheme.ColorToken.textSecondary)
                        .monospacedDigit()
                }
            }
        }
        .tlCard()
        .onAppear {
            samples = baseHistory.isEmpty ? TLTrainingReviewMock.placeholderIncident().vitalsHistory : baseHistory
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 850_000_000)
                guard isLive else { continue }
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        samples = TLTrainingReviewMock.tickVitals(samples: samples, seed: seed)
                    }
                }
            }
        }
    }

    private var chartSeries: [TLLineSeries] {
        let hrValues: [Double] = samples.map(\.hr)
        let rrValues: [Double] = samples.map(\.rr)
        return [
            TLLineSeries(name: "HR", color: TLTheme.ColorToken.red, values: hrValues),
            TLLineSeries(name: "RR", color: TLTheme.ColorToken.blue, values: rrValues),
        ]
    }
}

private struct TLLineSeries: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let color: Color
    let values: [Double]
}

private struct TLLineChart: View {
    let series: [TLLineSeries]

    private var allValues: [Double] {
        series.flatMap(\.values)
    }

    private var minValue: Double {
        allValues.min() ?? 0
    }

    private var maxValue: Double {
        allValues.max() ?? 1
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let minV = minValue
            let maxV = maxValue
            let range = max(1e-6, maxV - minV)

            ZStack(alignment: .topLeading) {
                // grid
                Path { path in
                    let rows = 4
                    let cols = 6
                    for r in 0...rows {
                        let y = h * CGFloat(r) / CGFloat(rows)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: w, y: y))
                    }
                    for c in 0...cols {
                        let x = w * CGFloat(c) / CGFloat(cols)
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: h))
                    }
                }
                .stroke(Color.white.opacity(0.06), lineWidth: 1)

                ForEach(series) { s in
                    let pts = s.values
                    if pts.count >= 2 {
                        Path { path in
                            for idx in pts.indices {
                                let x = w * CGFloat(idx) / CGFloat(max(1, pts.count - 1))
                                let yNorm = (pts[idx] - minV) / range
                                let y = h * CGFloat(1 - yNorm)
                                if idx == pts.startIndex {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(s.color.opacity(0.9), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Range \(Int(minV))–\(Int(maxV))")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(TLTheme.ColorToken.textTertiary)
                        .monospacedDigit()
                    HStack(spacing: 10) {
                        ForEach(series) { s in
                            HStack(spacing: 6) {
                                Circle().fill(s.color).frame(width: 8, height: 8)
                                Text(s.name)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(TLTheme.ColorToken.textSecondary)
                            }
                        }
                    }
                }
                .padding(10)
            }
        }
    }
}

// MARK: - Dispatch follow-up mini-form (mock)

private struct TLDispatchFollowupCard: View {
    let location: String
    let severity: TLTriageStatus

    @State private var unitRequested: String = "ALS Unit"
    @State private var followupOutcome: String = ""
    @State private var saved: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: TLTheme.Spacing.md) {
            TLSectionHeader(title: "Dispatch form", subtitle: "Mock follow-up submission (training)")

            HStack(spacing: 10) {
                TLStatusPill(icon: "mappin.and.ellipse", text: location, tint: TLTheme.ColorToken.textSecondary)
                Spacer(minLength: 0)
                TLTriageBadge(status: severity)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Unit requested")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLTheme.ColorToken.textSecondary)

                Picker("Unit requested", selection: $unitRequested) {
                    Text("ALS Unit").tag("ALS Unit")
                    Text("BLS Unit").tag("BLS Unit")
                    Text("Rescue / Extraction").tag("Rescue / Extraction")
                    Text("Air Medical").tag("Air Medical")
                }
                .pickerStyle(.menu)
                .tint(TLTheme.ColorToken.textSecondary)
                .padding(12)
                .background(TLTheme.ColorToken.surface2)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Outcome notes")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLTheme.ColorToken.textSecondary)

                TextField("e.g., Transported to ED, patient stable on arrival…", text: $followupOutcome, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(TLTheme.ColorToken.surface2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    saved = true
                }
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 1_200_000_000)
                    withAnimation(.easeInOut(duration: 0.15)) {
                        saved = false
                    }
                }
            } label: {
                Label(saved ? "Saved" : "Save dispatch note", systemImage: saved ? "checkmark.circle.fill" : "paperplane.fill")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(saved ? TLTheme.ColorToken.green : TLTheme.ColorToken.red)
            .disabled(followupOutcome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(followupOutcome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.75 : 1)

            if saved {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(TLTheme.ColorToken.green)
                    Text("Success state: dispatch follow-up stored (mock).")
                        .font(.subheadline)
                        .foregroundStyle(TLTheme.ColorToken.textSecondary)
                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(TLTheme.ColorToken.surface2)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(TLTheme.ColorToken.stroke, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }
}

// MARK: - Types + mock helpers

private struct TLIncidentSelection: Identifiable, Hashable {
    let incidentId: UUID
    var id: UUID { incidentId }
}

private enum TLTrainingReviewFilter: String, CaseIterable, Identifiable {
    case all
    case recording
    case trainingTagged
    case criticalOnly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All"
        case .recording: return "Recording"
        case .trainingTagged: return "Training"
        case .criticalOnly: return "Critical"
        }
    }
}

private enum TLTrainingReviewMock {
    static func placeholderIncident() -> TLIncident {
        let id = UUID()
        let date = Date()

        var vitals: [TLVitalsSample] = []
        vitals.reserveCapacity(30)
        for i in 0..<30 {
            let t = Double(i)
            let hr = Double(95 + (i % 5))
            let rr = Double(18 + (i % 3))
            vitals.append(TLVitalsSample(t: t, hr: hr, rr: rr))
        }

        return TLIncident(
            id: id,
            date: date,
            location: "—",
            severity: .urgent,
            outcome: "Pending",
            recordingAvailable: true,
            summary: "Loading incident summary…",
            vitalsHistory: vitals,
            responderNotes: "",
            useForTraining: false
        )
    }

    static func timeline(for incident: TLIncident) -> [TLReviewEvent] {
        let base = incident.date

        var events: [TLReviewEvent] = []
        events.reserveCapacity(4)

        func add(_ offset: TimeInterval, _ title: String, _ detail: String, _ tint: Color) {
            let t = base.addingTimeInterval(offset)
            events.append(
                TLReviewEvent(
                    id: UUID(),
                    time: t,
                    timeLabel: timeString(t),
                    title: title,
                    detail: detail,
                    tint: tint
                )
            )
        }

        add(0, "Dispatch", "Call received • incident opened", TLTheme.ColorToken.blue)
        add(60, "On scene", "Initial assessment started", TLTheme.ColorToken.green)
        let interventions = (incident.severity == .critical)
            ? "Airway + rapid escalation initiated"
            : "Monitoring + supportive care"
        add(150, "Interventions", interventions, TLTheme.ColorToken.amber)
        add(300, "Outcome", incident.outcome, TLTheme.ColorToken.textSecondary)

        return events
    }

    static func patients(for seed: UUID, severity: TLTriageStatus) -> [TLPatient] {
        var g = SimpleSeededGenerator(seed: stableSeed(from: seed))
        let count = 3
        var out: [TLPatient] = []
        out.reserveCapacity(count)

        let prefix = String(seed.uuidString.prefix(4))

        for idx in 0..<count {
            let triage: TLTriageStatus
            switch severity {
            case .critical:
                triage = (idx == 0) ? .critical : ((idx == 1) ? .urgent : .stable)
            case .urgent:
                triage = (idx == 0) ? .urgent : ((idx == 1) ? .stable : .urgent)
            case .stable:
                triage = .stable
            }

            let hrBase: Int
            let rrBase: Int
            switch triage {
            case .critical:
                hrBase = 148
                rrBase = 30
            case .urgent:
                hrBase = 112
                rrBase = 22
            case .stable:
                hrBase = 84
                rrBase = 16
            }

            let hr = hrBase + Int.random(in: -8...10, using: &g)
            let rr = rrBase + Int.random(in: -3...4, using: &g)
            let conf = Double.random(in: 0.50...0.92, using: &g)

            out.append(
                TLPatient(
                    id: "TR-\(prefix)-\(idx)",
                    displayName: "Patient \(idx + 1)",
                    triage: triage,
                    heartRate: max(45, min(180, hr)),
                    respRate: max(8, min(40, rr)),
                    confidence: conf,
                    notes: "",
                    quickFlags: []
                )
            )
        }

        return out
    }

    static func tickVitals(samples: [TLVitalsSample], seed: UUID) -> [TLVitalsSample] {
        guard let last = samples.last else { return samples }
        var g = SimpleSeededGenerator(seed: stableSeed(from: seed) &+ UInt64((last.t * 10).rounded()))

        let hr = max(45, min(180, last.hr + Double.random(in: -4...4, using: &g)))
        let rr = max(8, min(40, last.rr + Double.random(in: -2...2, using: &g)))
        let next = TLVitalsSample(t: last.t + 1, hr: hr, rr: rr)
        var out = samples
        out.append(next)
        if out.count > 30 { out.removeFirst(out.count - 30) }
        return out
    }

    private static func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: date)
    }

    private static func stableSeed(from uuid: UUID) -> UInt64 {
        let bytes = withUnsafeBytes(of: uuid.uuid) { Array($0) }
        var h: UInt64 = 1469598103934665603
        for b in bytes {
            h ^= UInt64(b)
            h &*= 1099511628211
        }
        return h
    }
}

private struct SimpleSeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x12345678 : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

