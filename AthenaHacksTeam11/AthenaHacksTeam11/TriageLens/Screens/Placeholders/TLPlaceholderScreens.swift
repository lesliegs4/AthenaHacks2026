import SwiftUI

struct TLMassCasualtyView: View {
    var body: some View {
        MassCasualityModeView()
    }
}

struct TLIncidentLogsView: View {
    var body: some View {
        Text("Incident Logs (building next)")
            .foregroundStyle(TLTheme.ColorToken.textSecondary)
            .padding(TLTheme.Spacing.lg)
            .tlCard()
            .padding(TLTheme.Spacing.lg)
    }
}

struct TLDispatchView: View {
    var body: some View {
        Text("Dispatch (building next)")
            .foregroundStyle(TLTheme.ColorToken.textSecondary)
            .padding(TLTheme.Spacing.lg)
            .tlCard()
            .padding(TLTheme.Spacing.lg)
    }
}

struct TLTrainingReviewView: View {
    var body: some View {
        Text("Training Review (building next)")
            .foregroundStyle(TLTheme.ColorToken.textSecondary)
            .padding(TLTheme.Spacing.lg)
            .tlCard()
            .padding(TLTheme.Spacing.lg)
    }
}

