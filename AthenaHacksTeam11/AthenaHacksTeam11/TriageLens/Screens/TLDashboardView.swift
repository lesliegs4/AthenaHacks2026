import SwiftUI

struct TLDashboardView: View {
    @EnvironmentObject private var store: TLStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TLTheme.Spacing.lg) {
                TLSectionHeader(
                    title: "Quick actions",
                    subtitle: "Field-ready shortcuts for pre-triage and escalation."
                )

                let cols = [GridItem(.adaptive(minimum: 260), spacing: TLTheme.Spacing.md)]
                LazyVGrid(columns: cols, spacing: TLTheme.Spacing.md) {
                    actionCard(
                        title: "Live Assessment",
                        subtitle: "Camera-based vitals + triage badge",
                        icon: "camera.viewfinder",
                        tint: TLTheme.ColorToken.blue
                    ) { store.selectedRoute = .liveAssessment }

                    actionCard(
                        title: "Mass Casualty Mode",
                        subtitle: "Sort and tag multiple patients quickly",
                        icon: "person.3.fill",
                        tint: TLTheme.ColorToken.amber
                    ) { store.selectedRoute = .massCasualty }

                    actionCard(
                        title: "Escalate to Dispatch",
                        subtitle: "One-tap handoff with vitals snapshot",
                        icon: "dot.radiowaves.left.and.right",
                        tint: TLTheme.ColorToken.red
                    ) { store.escalateToDispatch() }
                }

                TLSectionHeader(title: "Recent incidents")

                if store.incidents.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: TLTheme.Spacing.sm) {
                        ForEach(store.incidents.prefix(4)) { incident in
                            incidentRow(incident)
                        }
                    }
                }
            }
            .padding(TLTheme.Spacing.lg)
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No incidents yet")
                .font(.headline.weight(.semibold))
                .foregroundStyle(TLTheme.ColorToken.text)
            Text("Incidents captured during training or field use will appear here.")
                .font(.subheadline)
                .foregroundStyle(TLTheme.ColorToken.textSecondary)
        }
        .tlCard()
    }

    private func actionCard(title: String, subtitle: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: TLTheme.Spacing.md) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(tint.opacity(0.20))
                    .overlay(
                        Image(systemName: icon)
                            .foregroundStyle(tint)
                            .font(.title3.weight(.bold))
                    )
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(TLTheme.ColorToken.text)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(TLTheme.ColorToken.textSecondary)
                }

                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .foregroundStyle(TLTheme.ColorToken.textTertiary)
                    .font(.body.weight(.semibold))
            }
            .tlCard()
        }
        .buttonStyle(.plain)
    }

    private func incidentRow(_ incident: TLIncident) -> some View {
        Button {
            store.selectIncident(incident)
            store.selectedRoute = .incidentLogs
        } label: {
            HStack(spacing: TLTheme.Spacing.md) {
                TLTriageBadge(status: incident.severity)

                VStack(alignment: .leading, spacing: 4) {
                    Text(incident.location)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(TLTheme.ColorToken.text)
                    Text(incident.summary)
                        .font(.subheadline)
                        .foregroundStyle(TLTheme.ColorToken.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(incident.date, style: .time)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TLTheme.ColorToken.textSecondary)
                    Text(incident.recordingAvailable ? "Recording" : "No recording")
                        .font(.caption)
                        .foregroundStyle(incident.recordingAvailable ? TLTheme.ColorToken.green : TLTheme.ColorToken.textTertiary)
                }
            }
            .padding(.horizontal, TLTheme.Spacing.md)
            .padding(.vertical, TLTheme.Spacing.sm)
            .background(TLTheme.ColorToken.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

