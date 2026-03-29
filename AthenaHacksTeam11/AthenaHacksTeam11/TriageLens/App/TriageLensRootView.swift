import SwiftUI

struct TriageLensRootView: View {
    @StateObject private var store = TLStore()
    @Environment(\.horizontalSizeClass) private var hSize

    var body: some View {
        Group {
            if isCompact {
                NavigationStack {
                    sidebar(isCompact: true)
                }
            } else {
                NavigationSplitView {
                    sidebar(isCompact: false)
                        .navigationSplitViewColumnWidth(min: 250, ideal: TLTheme.sidebarWidth, max: 360)
                } detail: {
                    screen(for: store.selectedRoute)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(TLTheme.ColorToken.bg)
                }
            }
        }
        .tint(TLTheme.ColorToken.red)
        .preferredColorScheme(.dark)
    }

    private var isCompact: Bool {
        (hSize ?? .compact) == .compact
    }

    private func sidebar(isCompact: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(TLTheme.ColorToken.red.opacity(0.18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(TLTheme.ColorToken.red.opacity(0.35), lineWidth: 1)
                        )
                    Image(systemName: "cross.case.fill")
                        .foregroundStyle(TLTheme.ColorToken.red)
                        .font(.title3.weight(.bold))
                }
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 2) {
                    Text("TriageLens")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(TLTheme.ColorToken.text)
                    Text("First responder dashboard")
                        .font(.caption)
                        .foregroundStyle(TLTheme.ColorToken.textSecondary)
                }

                Spacer(minLength: 0)
            }
            .padding(TLTheme.Spacing.lg)
            .background(TLTheme.ColorToken.surface)
            .overlay(Rectangle().fill(TLTheme.ColorToken.stroke).frame(height: 1), alignment: .bottom)

            List {
                Section("Operations") {
                    navItem(.dashboard, icon: "square.grid.2x2.fill", isCompact: isCompact)
                    navItem(.liveAssessment, icon: "camera.viewfinder", isCompact: isCompact)
                    navItem(.massCasualty, icon: "person.3.fill", isCompact: isCompact)
                    navItem(.incidentLogs, icon: "clock.fill", isCompact: isCompact)
                    navItem(.dispatch, icon: "dot.radiowaves.left.and.right", isCompact: isCompact)
                }

                Section("Quality") {
                    navItem(.trainingReview, icon: "checklist.checked", isCompact: isCompact)
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(TLTheme.ColorToken.bg)

            TLDisclaimerFooter()
                .background(TLTheme.ColorToken.bg)
        }
        .background(TLTheme.ColorToken.bg)
    }

    @ViewBuilder
    private func navItem(_ route: TLRoute, icon: String, isCompact: Bool) -> some View {
        let row = HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .frame(width: 22)
            Text(route.rawValue)
                .font(.subheadline.weight(.semibold))
            Spacer(minLength: 0)
        }
        .foregroundStyle(TLTheme.ColorToken.text)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .contentShape(Rectangle())

        Group {
            if isCompact {
                NavigationLink {
                    screen(for: route)
                        .onAppear { store.selectedRoute = route }
                } label: {
                    row
                }
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        store.selectedRoute = route
                    }
                } label: {
                    row
                }
                .buttonStyle(.plain)
            }
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
        .listRowBackground(
            RoundedRectangle(cornerRadius: 12)
                .fill(store.selectedRoute == route ? TLTheme.ColorToken.surface2 : Color.clear)
        )
    }

    @ViewBuilder
    private func screen(for route: TLRoute) -> some View {
        TLScreenContainer(title: route.rawValue) {
            switch route {
            case .dashboard:
                TLDashboardView()
            case .liveAssessment:
                TLLiveAssessmentView()
            case .massCasualty:
                TLMassCasualtyView()
            case .incidentLogs:
                TLIncidentLogsView()
            case .dispatch:
                TLDispatchView()
            case .trainingReview:
                TLTrainingReviewView()
            }
        }
        .environmentObject(store)
    }
}

struct TLScreenContainer<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(TLTheme.ColorToken.text)

                Spacer(minLength: 0)

                HStack(spacing: 10) {
                    Label("Secure", systemImage: "lock.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TLTheme.ColorToken.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(TLTheme.ColorToken.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, TLTheme.Spacing.lg)
            .padding(.vertical, TLTheme.Spacing.md)
            .background(TLTheme.ColorToken.bg)
            .overlay(Rectangle().fill(TLTheme.ColorToken.stroke).frame(height: 1), alignment: .bottom)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(TLTheme.ColorToken.bg)
        }
    }
}

