import SwiftUI
import SmartSpectraSwiftSDK
import AVFoundation

struct TLLiveAssessmentView: View {
    @EnvironmentObject private var store: TLStore
    @Environment(\.horizontalSizeClass) private var hSize

    @State private var showingAddNote: Bool = false
    @FocusState private var notesFocused: Bool
    @State private var spectraKeyLabel: String = ""
    @State private var spectraKeyLoaded: Bool = false
    @State private var usingSmartSpectra: Bool = false
    @State private var cameraPosition: AVCaptureDevice.Position = .front
    @State private var isSwitchingCamera: Bool = false
    @State private var isStartingSmartSpectra: Bool = false
    @State private var cameraPermissionDenied: Bool = false

    @ObservedObject private var spectraSDK = SmartSpectraSwiftSDK.shared
    @ObservedObject private var vitalsProcessor = SmartSpectraVitalsProcessor.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TLTheme.Spacing.lg) {
                headerRow

                if isWideLayout {
                    HStack(alignment: .top, spacing: TLTheme.Spacing.lg) {
                        cameraCard
                            .frame(maxWidth: 560)
                        assessmentPanel
                            .frame(maxWidth: 520)
                        Spacer(minLength: 0)
                    }
                } else {
                    VStack(alignment: .leading, spacing: TLTheme.Spacing.lg) {
                        cameraCard
                        assessmentPanel
                    }
                }

                TLDisclaimerFooter()
                    .padding(.horizontal, -TLTheme.Spacing.lg)
                    .padding(.bottom, -TLTheme.Spacing.lg)
            }
            .padding(TLTheme.Spacing.lg)
        }
        .onAppear { ensureCameraAccessAndStart() }
        .onDisappear { stopAssessment() }
    }

    private var isWideLayout: Bool {
        hSize == .regular
    }

    private var headerRow: some View {
        HStack(alignment: .top, spacing: TLTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: 6) {
                Text(store.activePatient.displayName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(TLTheme.ColorToken.text)

                HStack(spacing: 10) {
                    Label(isRunning ? "Live" : "Standby", systemImage: isRunning ? "dot.radiowaves.left.and.right" : "pause.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isRunning ? TLTheme.ColorToken.green : TLTheme.ColorToken.textSecondary)

                    Text("Confidence \(Int(displayConfidence * 100))%")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TLTheme.ColorToken.textSecondary)
                }
            }

            Spacer(minLength: 0)

            TLTriageBadge(status: store.activePatient.triage, isLarge: true)
        }
    }

    private var cameraCard: some View {
        VStack(alignment: .leading, spacing: TLTheme.Spacing.md) {
            HStack {
                TLSectionHeader(title: "Camera assessment", subtitle: "Decision support overlay")
                Spacer(minLength: 0)
                cameraToggle
                statusTag
            }

            cameraPreview
                .frame(height: isWideLayout ? 420 : 320)
                .overlay(alignment: .topLeading) { overlayMetrics }
                .overlay(alignment: .topTrailing) { overlayTriage }
                .overlay(alignment: .bottomLeading) { overlayConfidence }
                .clipShape(RoundedRectangle(cornerRadius: TLTheme.cornerRadius))

            HStack(spacing: TLTheme.Spacing.md) {
                TLMetricCard(title: "Estimated HR", value: "\(displayHR) bpm", footnote: usingSmartSpectra ? "SmartSpectra" : "mock", tint: TLTheme.ColorToken.red, icon: "heart.fill")
                TLMetricCard(title: "Estimated RR", value: "\(displayRR) rpm", footnote: usingSmartSpectra ? "SmartSpectra" : "mock", tint: TLTheme.ColorToken.blue, icon: "lungs.fill")
            }

            if !spectraKeyLabel.isEmpty {
                Text(spectraKeyLabel)
                    .font(.caption2)
                    .foregroundStyle(spectraKeyLoaded ? TLTheme.ColorToken.textTertiary : TLTheme.ColorToken.amber)
            }
        }
        .tlCard()
    }

    private var cameraToggle: some View {
        Button {
            switchCamera()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "camera.rotate")
                    .font(.caption.weight(.semibold))
                Text(cameraPosition == .front ? "Front" : "Back")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(TLTheme.ColorToken.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(TLTheme.ColorToken.surface2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(isSwitchingCamera)
        .opacity(isSwitchingCamera ? 0.6 : 1)
        .accessibilityLabel("Switch camera")
    }

    private var cameraPreview: some View {
        ZStack {
            if usingSmartSpectra, let image = vitalsProcessor.imageOutput {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                TLMockCameraPreview(isActive: isRunning)
            }

            if cameraPermissionDenied {
                VStack(spacing: 8) {
                    Text("Camera permission needed")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(TLTheme.ColorToken.text)
                    Text("Enable Camera access in Settings to use live preview.")
                        .font(.footnote)
                        .foregroundStyle(TLTheme.ColorToken.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .padding(14)
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding()
            } else if usingSmartSpectra, vitalsProcessor.imageOutput == nil, isRunning {
                VStack(spacing: 8) {
                    Text("Starting SmartSpectra…")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(TLTheme.ColorToken.text)
                    Text(vitalsProcessor.statusHint.isEmpty ? "Waiting for camera frames." : vitalsProcessor.statusHint)
                        .font(.footnote)
                        .foregroundStyle(TLTheme.ColorToken.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .padding(14)
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding()
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: TLTheme.cornerRadius)
                .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
        )
    }

    private var overlayMetrics: some View {
        VStack(alignment: .leading, spacing: 8) {
            TLOverlayPill(title: "HR", value: "\(displayHR) bpm", tint: TLTheme.ColorToken.red)
            TLOverlayPill(title: "RR", value: "\(displayRR) rpm", tint: TLTheme.ColorToken.blue)
        }
        .padding(12)
    }

    private var overlayTriage: some View {
        VStack(alignment: .trailing, spacing: 8) {
            TLTriageBadge(status: store.activePatient.triage)
            if isRecording {
                TLOverlaySmallTag(text: "REC", tint: TLTheme.ColorToken.red)
            }
            TLOverlaySmallTag(text: cameraPosition == .front ? "FRONT" : "BACK", tint: TLTheme.ColorToken.blue)
        }
        .padding(12)
    }

    private var overlayConfidence: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Confidence")
                .font(.caption.weight(.semibold))
                .foregroundStyle(TLTheme.ColorToken.textSecondary)
            TLConfidenceBar(value: displayConfidence)
            Text("\(Int(displayConfidence * 100))%")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(TLTheme.ColorToken.textSecondary)
        }
        .padding(12)
    }

    private var assessmentPanel: some View {
        VStack(alignment: .leading, spacing: TLTheme.Spacing.lg) {
            TLSectionHeader(title: "Assessment summary", subtitle: "Fast triage + escalation workflow")

            VStack(alignment: .leading, spacing: TLTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Triage status")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TLTheme.ColorToken.textSecondary)
                        TLTriageBadge(status: store.activePatient.triage, isLarge: true)
                    }
                    Spacer(minLength: 0)
                }

                triagePicker
            }
            .tlCard()

            VStack(alignment: .leading, spacing: TLTheme.Spacing.md) {
                Text("Quick notes")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLTheme.ColorToken.textSecondary)

                FlowLayout(spacing: 10) {
                    ForEach(TLQuickNote.allCases) { note in
                        TLChip(text: note.rawValue, isSelected: store.activePatient.quickFlags.contains(note)) {
                            toggleQuickNote(note)
                        }
                    }
                }

                Text("Manual notes")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TLTheme.ColorToken.textSecondary)

                TextEditor(text: $store.activePatient.notes)
                    .focused($notesFocused)
                    .scrollContentBackground(.hidden)
                    .font(.body)
                    .foregroundStyle(TLTheme.ColorToken.text)
                    .padding(12)
                    .frame(minHeight: 120)
                    .background(TLTheme.ColorToken.surface2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .tlCard()

            HStack(spacing: TLTheme.Spacing.md) {
                Button {
                    store.escalateToDispatch()
                } label: {
                    Label("Escalate to Dispatch", systemImage: "dot.radiowaves.left.and.right")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(TLTheme.ColorToken.red)

                Button {
                    toggleRecording()
                } label: {
                    Label(isRecording ? "Stop Recording" : "Start Recording", systemImage: isRecording ? "stop.fill" : "record.circle")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .tint(TLTheme.ColorToken.surface2)
            }

            Button {
                notesFocused = true
            } label: {
                Label("Add manual notes", systemImage: "square.and.pencil")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)
            .tint(TLTheme.ColorToken.surface2)
        }
        .tlCard()
    }

    private var triagePicker: some View {
        HStack(spacing: 10) {
            ForEach(TLTriageStatus.allCases) { status in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        store.activePatient.triage = status
                    }
                } label: {
                    Text(status.rawValue)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(store.activePatient.triage == status ? TLTheme.ColorToken.text : TLTheme.ColorToken.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(store.activePatient.triage == status ? tint(for: status).opacity(0.20) : TLTheme.ColorToken.surface2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(store.activePatient.triage == status ? tint(for: status).opacity(0.65) : TLTheme.ColorToken.stroke, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toggleQuickNote(_ note: TLQuickNote) {
        if store.activePatient.quickFlags.contains(note) {
            store.activePatient.quickFlags.remove(note)
        } else {
            store.activePatient.quickFlags.insert(note)
        }
    }

    private func tint(for status: TLTriageStatus) -> Color {
        switch status {
        case .stable: return TLTheme.ColorToken.green
        case .urgent: return TLTheme.ColorToken.amber
        case .critical: return TLTheme.ColorToken.red
        }
    }

    private var statusTag: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isRunning ? TLTheme.ColorToken.green : TLTheme.ColorToken.textTertiary)
                .frame(width: 8, height: 8)
            Text(isRunning ? "LIVE" : "STANDBY")
                .font(.caption2.weight(.bold))
                .tracking(1.0)
                .foregroundStyle(isRunning ? TLTheme.ColorToken.green : TLTheme.ColorToken.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(TLTheme.ColorToken.surface2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityHint(cameraPosition == .front ? "Front camera" : "Back camera")
    }
}

// MARK: - Building blocks

private struct TLOverlayPill: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(tint.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TLTheme.ColorToken.text)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct TLOverlaySmallTag: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .tracking(1.2)
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.16))
            .overlay(
                RoundedRectangle(cornerRadius: 999)
                    .stroke(tint.opacity(0.55), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 999))
    }
}

private struct TLConfidenceBar: View {
    let value: Double // 0...1

    private var tint: Color {
        if value >= 0.8 { return TLTheme.ColorToken.green }
        if value >= 0.6 { return TLTheme.ColorToken.amber }
        return TLTheme.ColorToken.red
    }

    var body: some View {
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
                    .frame(width: max(8, geo.size.width * value))
                    .animation(.easeInOut(duration: 0.35), value: value)
            }
        }
        .frame(height: 12)
        .accessibilityLabel("Confidence \(Int(value * 100)) percent")
    }
}

private struct TLMockCameraPreview: View {
    let isActive: Bool
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    TLTheme.ColorToken.surface2,
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle grid + vignette for a "mission" feel.
            TLGridOverlay()
                .opacity(0.35)
                .blendMode(.overlay)

            TLVignette()
                .opacity(0.7)

            if isActive {
                TLScanline(phase: phase)
                    .transition(.opacity)
            }

            VStack(spacing: 10) {
                Image(systemName: isActive ? "camera.fill" : "camera.viewfinder")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(isActive ? TLTheme.ColorToken.green : TLTheme.ColorToken.textSecondary)
                Text(isActive ? "Assessing…" : "Camera preview")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(TLTheme.ColorToken.text)
                Text(isActive ? "Stabilize device • maintain lighting • keep subject still" : "Tap Start to begin live assessment")
                    .font(.footnote)
                    .foregroundStyle(TLTheme.ColorToken.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(18)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .overlay(
            RoundedRectangle(cornerRadius: TLTheme.cornerRadius)
                .stroke(TLTheme.ColorToken.stroke, lineWidth: 1)
        )
        .onAppear {
            withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

private struct TLScanline: View {
    let phase: CGFloat // 0...1
    var body: some View {
        GeometryReader { geo in
            let y = geo.size.height * phase
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, TLTheme.ColorToken.green.opacity(0.35), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 90)
                .position(x: geo.size.width / 2, y: y)
                .blendMode(.screen)
        }
    }
}

private struct TLGridOverlay: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let step: CGFloat = 28
                for x in stride(from: 0, through: geo.size.width, by: step) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                }
                for y in stride(from: 0, through: geo.size.height, by: step) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
            }
            .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
    }
}

private struct TLVignette: View {
    var body: some View {
        RadialGradient(
            colors: [Color.clear, Color.black.opacity(0.85)],
            center: .center,
            startRadius: 80,
            endRadius: 520
        )
    }
}

// Simple flow layout for chips (wraps lines).
private struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: Content

    init(spacing: CGFloat, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        _FlowLayout(spacing: spacing) {
            content
        }
    }
}

private struct _FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 320
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - SmartSpectra + fallback control

extension TLLiveAssessmentView {
    private var isSimulator: Bool {
#if targetEnvironment(simulator)
        return true
#else
        return false
#endif
    }

    private var isRunning: Bool {
        if usingSmartSpectra {
            switch vitalsProcessor.processingStatus {
            case .processing, .processed:
                return true
            case .idle, .error:
                return false
            }
        }
        return store.isProcessingVitals
    }

    private var displayHR: Int {
        let v = spectraSDK.metricsBuffer?.pulse.strict.value ?? 0
        let rounded = Int(round(v))
        return rounded > 0 ? rounded : store.activePatient.heartRate
    }

    private var displayRR: Int {
        let v = spectraSDK.metricsBuffer?.breathing.strict.value ?? 0
        let rounded = Int(round(v))
        return rounded > 0 ? rounded : store.activePatient.respRate
    }

    private var displayConfidence: Double {
        let c = store.activePatient.confidence
        return max(0, min(1, c))
    }

    private var isRecording: Bool {
        usingSmartSpectra ? vitalsProcessor.isRecording : store.isProcessingVitals
    }

    private func isRunningInPreviews() -> Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    private func ensureCameraAccessAndStart() {
        guard !isStartingSmartSpectra else { return }

        // If permission is denied/restricted, SmartSpectra won't be able to deliver frames.
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            cameraPermissionDenied = false
            startAssessment()
        case .notDetermined:
            isStartingSmartSpectra = true
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.isStartingSmartSpectra = false
                    self.cameraPermissionDenied = !granted
                    if granted {
                        self.startAssessment()
                    }
                }
            }
        default:
            cameraPermissionDenied = true
        }
    }

    private func startAssessment() {
        // Always keep confidence + UI dynamic
        store.startVitals()

        // Simulator frequently cannot provide a real camera feed (you'll see
        // FigCaptureSourceSimulator / -11814 "Cannot Record"). Fall back so the UI
        // remains usable and doesn't look "stuck".
        if isSimulator {
            usingSmartSpectra = false
            spectraKeyLoaded = false
            spectraKeyLabel = "Simulator: camera feed unavailable • using mock preview (run on a real iPhone for live camera)"
            return
        }

        guard !isRunningInPreviews() else {
            usingSmartSpectra = false
            spectraKeyLabel = "Previews: SmartSpectra disabled"
            return
        }

        let loaded = TLSmartSpectraKey.load()
        spectraKeyLabel = loaded.sourceLabel
        spectraKeyLoaded = loaded.value != nil

        guard let apiKey = loaded.value else {
            usingSmartSpectra = false
            return
        }

        spectraSDK.setApiKey(apiKey)
        spectraSDK.setSmartSpectraMode(.continuous)
        spectraSDK.showControlsInScreeningView(true)
        usingSmartSpectra = true
        spectraSDK.setCameraPosition(cameraPosition)
        vitalsProcessor.startProcessing()
    }

    private func stopAssessment() {
        store.stopVitals()

        vitalsProcessor.stopRecording()
        vitalsProcessor.stopProcessing()
        usingSmartSpectra = false
    }

    private func toggleRecording() {
        if usingSmartSpectra {
            if vitalsProcessor.isRecording {
                vitalsProcessor.stopRecording()
            } else {
                vitalsProcessor.startRecording()
            }
        } else {
            // Mock fallback: use the vitals timer as "recording" signal.
            store.isProcessingVitals ? store.stopVitals() : store.startVitals()
        }
    }

    private func switchCamera() {
        guard !isSwitchingCamera else { return }
        isSwitchingCamera = true

        let nextPosition: AVCaptureDevice.Position = (cameraPosition == .front) ? .back : .front
        cameraPosition = nextPosition

        guard usingSmartSpectra, !cameraPermissionDenied else {
            isSwitchingCamera = false
            return
        }

        // Clear the last frame immediately so we don't "freeze" on the prior camera image.
        vitalsProcessor.imageOutput = nil

        // Avoid conflicts: stop pipeline, set camera, restart (with delays to let capture fully tear down).
        let wasRecording = vitalsProcessor.isRecording
        if wasRecording { vitalsProcessor.stopRecording() }
        vitalsProcessor.stopProcessing()

        // Set desired camera position for the next pipeline start.
        spectraSDK.setCameraPosition(nextPosition)

        // Give SmartSpectra time to release the previous camera input before restarting.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            vitalsProcessor.startProcessing()
        }

        if wasRecording {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.55) {
                vitalsProcessor.startRecording()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
            isSwitchingCamera = false
        }
    }
}

