//
//  SpectraView.swift
//  AthenaHacksTeam11
//
//  Created by Leslie Garcia on 3/28/26.
//

import SwiftUI
import SmartSpectraSwiftSDK
import AVFoundation


struct SpectraView: View {
    @ObservedObject private var sdk = SmartSpectraSwiftSDK.shared
    @ObservedObject private var vitalsProcessor = SmartSpectraVitalsProcessor.shared
    @State private var apiKeyLoaded: Bool = false
    @State private var apiKeySourceLabel: String = ""
    @State private var didConfigureSDK: Bool = false

    init() {
        // Intentionally empty.
        // SwiftUI may recreate Views frequently; avoid SDK side effects in init()
        // (it can make controls like camera switching appear "stuck").
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 16) {
                // Default SDK entry point (tap Checkup to open the full screening flow).
                SmartSpectraView()
                    .padding(.top, 70)

                // Lightweight "proof" panel: shows camera frames + live metrics when available.
                ZStack {
                    if let image = vitalsProcessor.imageOutput {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, minHeight: 320, maxHeight: 420)
                            .clipped()
                    } else {
                        VStack(spacing: 8) {
                            Text("Camera preview will appear here")
                                .font(.headline)
                            Text(vitalsProcessor.statusHint.isEmpty ? "Tap Start to begin processing." : vitalsProcessor.statusHint)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 320, maxHeight: 420)
                        .background(Color.secondary.opacity(0.12))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal)

                HStack(spacing: 12) {
                    Button {
                        vitalsProcessor.startProcessing()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            vitalsProcessor.startRecording()
                        }
                    } label: {
                        Text(vitalsProcessor.isRecording ? "Recording…" : "Start")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vitalsProcessor.isRecording)

                    Button {
                        vitalsProcessor.stopRecording()
                        vitalsProcessor.stopProcessing()
                    } label: {
                        Text("Stop")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Live metrics")
                        .font(.headline)

                    let pulse = sdk.metricsBuffer?.pulse.strict.value ?? 0
                    let breathing = sdk.metricsBuffer?.breathing.strict.value ?? 0
                    Text("Pulse: \(pulse == 0 ? "N/A" : "\(Int(round(pulse)))") BPM")
                        .font(.footnote)
                    Text("Breathing: \(breathing == 0 ? "N/A" : "\(Int(round(breathing)))") RPM")
                        .font(.footnote)

                    if let edge = sdk.edgeMetrics {
                        Text("Face detected: \(edge.hasFace ? "Yes" : "No")")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                Spacer(minLength: 16)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("SmartSpectra")
                    .font(.headline)
                Text(apiKeyLoaded ? "API key loaded" : "Missing API key")
                    .font(.footnote)
                    .foregroundStyle(apiKeyLoaded ? Color.secondary : Color.red)
                Text(apiKeySourceLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding()
        }
        .onAppear {
            guard !didConfigureSDK else { return }
            didConfigureSDK = true

            let loaded = TLSmartSpectraKey.load()
            apiKeyLoaded = loaded.value != nil
            apiKeySourceLabel = loaded.sourceLabel

            if let apiKey = loaded.value {
                sdk.setApiKey(apiKey)
            }

            #if targetEnvironment(simulator)
            // Avoid noisy simulator camera failures (-11814 "Cannot Record").
            #else
            sdk.setSmartSpectraMode(.continuous)
            sdk.showControlsInScreeningView(true)
            // Do NOT force camera position here; let the SDK UI/user choice control it.
            #endif
        }
        .onDisappear {
            vitalsProcessor.stopRecording()
            vitalsProcessor.stopProcessing()
        }
    }

    // API key loading shared via `TLSmartSpectraKey`.
}
