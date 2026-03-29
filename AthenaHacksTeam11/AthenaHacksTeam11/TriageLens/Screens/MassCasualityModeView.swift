import SwiftUI

struct MassCasualityModeView: View {
    @EnvironmentObject private var store: TLStore
    @Environment(\.horizontalSizeClass) private var hSize

    private var isWideLayout: Bool { hSize == .regular }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: isWideLayout ? 300 : 260), spacing: TLTheme.Spacing.md)]
    }

    private var patients: [TLPatient] {
        Array(store.sortedMassCasualty().prefix(6))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TLTheme.Spacing.lg) {
                banner

                TLSectionHeader(
                    title: "Patients",
                    subtitle: "Sorted by severity for rapid triage."
                )

                LazyVGrid(columns: columns, spacing: TLTheme.Spacing.md) {
                    ForEach(patients) { patient in
                        patientCard(patient)
                    }
                }

                TLDisclaimerFooter()
                    .padding(.horizontal, -TLTheme.Spacing.lg)
                    .padding(.bottom, -TLTheme.Spacing.lg)
            }
            .padding(TLTheme.Spacing.lg)
        }
    }

    private var banner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.callout.weight(.bold))
                .foregroundStyle(TLTheme.ColorToken.amber)

            Text("Mass Casualty Mode Active")
                .font(.headline.weight(.bold))
                .foregroundStyle(TLTheme.ColorToken.text)

            Spacer(minLength: 0)

            Text("\(patients.count) tracked")
                .font(.caption.weight(.semibold))
                .foregroundStyle(TLTheme.ColorToken.textSecondary)
        }
        .padding(.horizontal, TLTheme.Spacing.md)
        .padding(.vertical, 12)
        .background(TLTheme.ColorToken.surface2)
        .overlay(
            RoundedRectangle(cornerRadius: 999)
                .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 999))
    }

    private func patientCard(_ patient: TLPatient) -> some View {
        let tint = triageTint(patient.triage)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: TLTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(patient.id)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(TLTheme.ColorToken.text)
                    Text("Estimated vitals")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TLTheme.ColorToken.textTertiary)
                }

                Spacer(minLength: 0)

                TLTriageBadge(status: patient.triage)
            }

            HStack(spacing: TLTheme.Spacing.md) {
                vitalsPill(
                    icon: "heart.fill",
                    text: "\(patient.heartRate) bpm",
                    tint: TLTheme.ColorToken.red
                )
                vitalsPill(
                    icon: "lungs.fill",
                    text: "\(patient.respRate) rpm",
                    tint: TLTheme.ColorToken.blue
                )
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Confidence \(Int(patient.confidence * 100))%")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TLTheme.ColorToken.textSecondary)
                    Spacer(minLength: 0)
                }

                ProgressView(value: patient.confidence)
                    .tint(tint)
            }

            HStack(spacing: 10) {
                miniActionButton(icon: "viewfinder", tint: TLTheme.ColorToken.surface2) {
                    store.activePatient = patient
                    store.selectedRoute = .liveAssessment
                }

                miniActionButton(icon: "dot.radiowaves.left.and.right", tint: TLTheme.ColorToken.surface2) {
                    store.activePatient = patient
                    store.escalateToDispatch()
                }

                miniActionButton(icon: "arrow.triangle.2.circlepath", tint: TLTheme.ColorToken.surface2) {
                    store.updateTriage(for: patient.id, to: nextTriage(after: patient.triage))
                }

                Spacer(minLength: 0)
            }
        }
        .padding(TLTheme.cardPadding)
        .background(TLTheme.ColorToken.surface)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(tint)
                .frame(width: 5)
                .clipShape(RoundedRectangle(cornerRadius: TLTheme.cornerRadius))
                .padding(.leading, -TLTheme.cardPadding)
                .padding(.vertical, -TLTheme.cardPadding)
        }
        .overlay(
            RoundedRectangle(cornerRadius: TLTheme.cornerRadius)
                .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: TLTheme.cornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(patient.id), \(patient.triage.rawValue), heart rate \(patient.heartRate), respiratory rate \(patient.respRate), confidence \(Int(patient.confidence * 100)) percent")
    }

    private func vitalsPill(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .font(.caption.weight(.bold))
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TLTheme.ColorToken.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(TLTheme.ColorToken.surface2)
        .overlay(
            RoundedRectangle(cornerRadius: 999)
                .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 999))
    }

    private func miniActionButton(icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(TLTheme.ColorToken.textSecondary)
                .frame(width: 34, height: 34)
                .background(tint)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func triageTint(_ status: TLTriageStatus) -> Color {
        switch status {
        case .stable: return TLTheme.ColorToken.green
        case .urgent: return TLTheme.ColorToken.amber
        case .critical: return TLTheme.ColorToken.red
        }
    }

    private func nextTriage(after status: TLTriageStatus) -> TLTriageStatus {
        switch status {
        case .stable: return .urgent
        case .urgent: return .critical
        case .critical: return .stable
        }
    }
}

