import SwiftUI

struct TLDispatchView: View {
    @EnvironmentObject private var store: TLStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TLTheme.Spacing.lg) {
                TLSectionHeader(title: "Dispatch screen", subtitle: "Send a clean snapshot to dispatch in seconds")

                dispatchFormCard

                sendButton

                if store.isDispatchSent {
                    confirmationCard
                }

                timelineCard

                TLDisclaimerFooter()
                    .padding(.horizontal, -TLTheme.Spacing.lg)
                    .padding(.bottom, -TLTheme.Spacing.lg)
            }
            .padding(TLTheme.Spacing.lg)
        }
        .onAppear {
            // Ensure the snapshot isn't stale even if vitals processing stopped on navigation.
            store.dispatchDraft.vitalsSnapshot = "HR \(store.activePatient.heartRate) • RR \(store.activePatient.respRate) • Conf \(Int(store.activePatient.confidence * 100))%"
            if store.dispatchDraft.location == "—" { store.dispatchDraft.location = "" }
        }
    }

    private var dispatchFormCard: some View {
        VStack(alignment: .leading, spacing: TLTheme.Spacing.lg) {
            TLSectionHeader(title: "Dispatch form", subtitle: "Fields required for radio + CAD entry")

            VStack(alignment: .leading, spacing: TLTheme.Spacing.md) {
                fieldLabel("Incident location")
                TextField("Street / landmark / GPS notes", text: $store.dispatchDraft.location)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(false)
                    .padding(12)
                    .background(TLTheme.ColorToken.surface2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            VStack(alignment: .leading, spacing: TLTheme.Spacing.md) {
                fieldLabel("Severity level")
                Picker("Severity", selection: $store.dispatchDraft.severity) {
                    ForEach(TLTriageStatus.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: TLTheme.Spacing.md) {
                fieldLabel("Unit requested")
                Picker("Unit requested", selection: $store.dispatchDraft.unitRequested) {
                    Text("ALS Unit").tag("ALS Unit")
                    Text("BLS Unit").tag("BLS Unit")
                    Text("Rescue / Extraction").tag("Rescue / Extraction")
                    Text("Air Medical").tag("Air Medical")
                    Text("Fire Support").tag("Fire Support")
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

            VStack(alignment: .leading, spacing: TLTheme.Spacing.md) {
                fieldLabel("Patient summary")
                TextEditor(text: $store.dispatchDraft.patientSummary)
                    .scrollContentBackground(.hidden)
                    .font(.body)
                    .foregroundStyle(TLTheme.ColorToken.text)
                    .padding(12)
                    .frame(minHeight: 110)
                    .background(TLTheme.ColorToken.surface2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            vitalsSnapshotCard
        }
        .tlCard()
    }

    private var vitalsSnapshotCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                fieldLabel("Auto-filled vitals snapshot")
                Spacer(minLength: 0)
                Label(store.isDispatchSent ? "Locked" : "Live", systemImage: store.isDispatchSent ? "lock.fill" : "waveform.path.ecg")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(store.isDispatchSent ? TLTheme.ColorToken.textTertiary : TLTheme.ColorToken.green)
            }

            Text(store.dispatchDraft.vitalsSnapshot)
                .font(.headline.weight(.semibold))
                .foregroundStyle(TLTheme.ColorToken.text)
                .monospacedDigit()

            Text("Source: \(store.activePatient.displayName)")
                .font(.caption)
                .foregroundStyle(TLTheme.ColorToken.textTertiary)
        }
        .padding(12)
        .background(TLTheme.ColorToken.surface2)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var sendButton: some View {
        Button {
            store.sendDispatch()
        } label: {
            Label(store.isDispatchSent ? "Sent to Dispatch" : "Send to Dispatch", systemImage: store.isDispatchSent ? "checkmark.circle.fill" : "paperplane.fill")
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(store.isDispatchSent ? TLTheme.ColorToken.green : TLTheme.ColorToken.red)
        .disabled(store.isDispatchSent || store.dispatchDraft.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity((store.isDispatchSent || store.dispatchDraft.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.75 : 1)
        .accessibilityHint("Sends the dispatch form with vitals snapshot")
    }

    private var confirmationCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2.weight(.bold))
                .foregroundStyle(TLTheme.ColorToken.green)

            VStack(alignment: .leading, spacing: 6) {
                Text("Confirmation")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(TLTheme.ColorToken.text)
                Text("Dispatch request submitted. Keep monitoring patient; timeline updates below.")
                    .font(.subheadline)
                    .foregroundStyle(TLTheme.ColorToken.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .tlCard()
    }

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: TLTheme.Spacing.md) {
            TLSectionHeader(title: "Dispatch timeline", subtitle: "Event trail for this request")

            if store.dispatchDraft.timeline.isEmpty {
                Text("No events yet.")
                    .font(.subheadline)
                    .foregroundStyle(TLTheme.ColorToken.textSecondary)
                    .padding(.top, 4)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    let events = store.dispatchDraft.timeline.sorted { $0.time < $1.time }
                    ForEach(Array(events.enumerated()), id: \.element.id) { idx, e in
                        TLDispatchTimelineRow(
                            time: TLDispatchView.timeString(e.time),
                            title: e.title,
                            detail: e.detail,
                            isFirst: idx == 0,
                            isLast: idx == events.count - 1
                        )
                    }
                }
                .padding(.top, 4)
            }
        }
        .tlCard()
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(TLTheme.ColorToken.textSecondary)
    }

    private static func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: date)
    }
}

private struct TLDispatchTimelineRow: View {
    let time: String
    let title: String
    let detail: String
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
                    .fill(TLTheme.ColorToken.blue.opacity(0.85))
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle().stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
                    )

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

