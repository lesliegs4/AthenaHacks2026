import SwiftUI

struct TLSectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(TLTheme.ColorToken.text)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(TLTheme.ColorToken.textSecondary)
            }
        }
    }
}

struct TLMetricCard: View {
    let title: String
    let value: String
    var footnote: String? = nil
    var tint: Color = TLTheme.ColorToken.blue
    var icon: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: TLTheme.Spacing.sm) {
            RoundedRectangle(cornerRadius: 12)
                .fill(tint.opacity(0.20))
                .overlay(
                    Image(systemName: icon ?? "waveform.path.ecg")
                        .foregroundStyle(tint)
                        .font(.title3.weight(.semibold))
                )
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLTheme.ColorToken.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .allowsTightening(true)
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(TLTheme.ColorToken.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)
                    .monospacedDigit()
                    .layoutPriority(2)
                if let footnote {
                    Text(footnote)
                        .font(.caption)
                        .foregroundStyle(TLTheme.ColorToken.textTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .allowsTightening(true)
                }
            }
            .layoutPriority(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tlCard()
    }
}

struct TLTriageBadge: View {
    let status: TLTriageStatus
    var isLarge: Bool = false

    private var tint: Color {
        switch status {
        case .stable: return TLTheme.ColorToken.green
        case .urgent: return TLTheme.ColorToken.amber
        case .critical: return TLTheme.ColorToken.red
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(tint)
                .frame(width: isLarge ? 12 : 10, height: isLarge ? 12 : 10)
            Text(status.rawValue.uppercased())
                .font(isLarge ? .headline.weight(.bold) : .caption.weight(.bold))
                .tracking(0.8)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, isLarge ? 14 : 10)
        .padding(.vertical, isLarge ? 10 : 8)
        .background(tint.opacity(0.14))
        .overlay(
            RoundedRectangle(cornerRadius: 999)
                .stroke(tint.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 999))
        .accessibilityLabel("Triage status \(status.rawValue)")
    }
}

struct TLChip: View {
    let text: String
    var isSelected: Bool
    var tint: Color = TLTheme.ColorToken.surface2
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(isSelected ? TLTheme.ColorToken.text : TLTheme.ColorToken.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(isSelected ? TLTheme.ColorToken.blue.opacity(0.25) : tint)
                .overlay(
                    RoundedRectangle(cornerRadius: 999)
                        .stroke(isSelected ? TLTheme.ColorToken.blue.opacity(0.65) : TLTheme.ColorToken.stroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 999))
        }
        .buttonStyle(.plain)
    }
}

struct TLDisclaimerFooter: View {
    var body: some View {
        Text("Decision support only. Does not replace clinical judgment.")
            .font(.caption)
            .foregroundStyle(TLTheme.ColorToken.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, TLTheme.Spacing.lg)
            .padding(.vertical, TLTheme.Spacing.md)
    }
}

