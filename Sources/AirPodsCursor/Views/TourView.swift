import AppKit
import SwiftUI
import AirPodsCursorCore

// MARK: - Steps

/// Three steps, nothing more: allow, put AirPods in, go. Everything else lives in Settings.
enum TourStep: Int, CaseIterable, Identifiable {
    case allow, connect, done

    var id: Int { rawValue }

    var eyebrow: String {
        switch self {
        case .allow: "Step 1 of 3"
        case .connect: "Step 2 of 3"
        case .done: "Step 3 of 3"
        }
    }
}

// MARK: - Tour

/// First-run setup. Progress is persisted in AppController, so leaving for System
/// Settings and coming back resumes on the same step. Steps advance on their own as
/// soon as they're satisfied, and Continue never blocks.
struct TourView: View {
    @EnvironmentObject private var controller: AppController
    @EnvironmentObject private var pairing: PairingService
    @Environment(\.dismissWindow) private var dismissWindow

    private var step: TourStep { TourStep(rawValue: controller.tourStep) ?? .allow }

    var body: some View {
        HStack(spacing: 0) {
            TourStage(step: step)
                .frame(width: 300)

            VStack(alignment: .leading, spacing: 0) {
                ProgressDots(current: step)
                    .padding(.bottom, 22)

                Group { content }
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                footer
            }
            .padding(.horizontal, 36)
            .padding(.top, 34)
            .padding(.bottom, 26)
        }
        .frame(width: 820, height: 540)
        .background(Color(nsColor: .windowBackgroundColor).ignoresSafeArea())
        .onAppear {
            NSApp.activate()
            controller.windowVisibilityChanged()
            Diagnostics.log.notice("Setup shown (step \(controller.tourStep, privacy: .public))")
        }
        .onDisappear { controller.windowVisibilityChanged() }
        .onReceive(NotificationCenter.default.publisher(for: .tourShowStep)) { note in
            if let raw = note.object as? Int { controller.tourStep = raw }
        }
        // Both permissions granted → move on by itself.
        .onChange(of: permissionsGranted) { _, granted in
            advance(from: .allow, when: granted)
        }
        // Head motion arriving → AirPods are working → move on by itself.
        .onChange(of: controller.motionStreaming) { _, streaming in
            advance(from: .connect, when: streaming)
        }
    }

    private var permissionsGranted: Bool {
        controller.accessibilityTrusted && controller.motionAuthorization == .authorized
    }

    @ViewBuilder private var content: some View {
        switch step {
        case .allow: AllowStep()
        case .connect: ConnectStep()
        case .done: DoneStep()
        }
    }

    private var footer: some View {
        HStack {
            if step != .allow {
                Button("Back") { go(-1) }
                    .buttonStyle(.borderless)
            }
            Spacer()
            Button(step == .done ? "Get Started" : "Continue") {
                step == .done ? finish() : go(1)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.top, 16)
    }

    private func advance(from expected: TourStep, when ready: Bool) {
        guard ready, step == expected else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            if step == expected { go(1) }
        }
    }

    private func go(_ delta: Int) {
        guard let next = TourStep(rawValue: step.rawValue + delta) else { return }
        withAnimation(.smooth(duration: 0.35)) { controller.tourStep = next.rawValue }
    }

    private func finish() {
        controller.completeOnboarding()
        dismissWindow(id: WindowID.tour)
    }
}

// MARK: - Stage (left column)

private struct TourStage: View {
    @EnvironmentObject private var controller: AppController
    let step: TourStep

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.07, blue: 0.12), Color(red: 0.16, green: 0.13, blue: 0.30)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            RadialGradient(colors: [Color.accentColor.opacity(0.28), .clear], center: .center, startRadius: 10, endRadius: 240)
                .ignoresSafeArea()

            Earbuds3DView(state: stageState, live: controller.live)
                .padding(.bottom, 60)

            VStack(spacing: 10) {
                statusPill
                Text("AirPodsCursor")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(.bottom, 26)
        }
        .environment(\.colorScheme, .dark)
    }

    private var stageState: EarbudsState {
        if controller.motionStreaming { return .live }
        return step == .connect ? .searching : .idle
    }

    private var statusPill: some View {
        let (text, color): (String, Color) = {
            if controller.motionStreaming {
                if !controller.trackingEnabled { return ("Paused", .orange) }
                return (controller.mode == .scroll ? "Scroll mode" : "Following your head", .green)
            }
            if controller.connectedHeadphones != nil { return ("Connected · waiting for motion", .yellow) }
            return ("AirPods not connected", .gray)
        }()
        return HStack(spacing: 7) {
            Circle().fill(color).frame(width: 7, height: 7)
                .shadow(color: color, radius: 4)
            Text(text).font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(.white.opacity(0.08), in: Capsule())
        .foregroundStyle(.white.opacity(0.9))
        .animation(.default, value: text)
    }
}

private struct ProgressDots: View {
    let current: TourStep

    var body: some View {
        HStack(spacing: 10) {
            Text(current.eyebrow.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(.secondary)
            Spacer()
            HStack(spacing: 5) {
                ForEach(TourStep.allCases) { s in
                    Capsule()
                        .fill(s.rawValue <= current.rawValue ? Color.accentColor : Color.secondary.opacity(0.25))
                        .frame(width: s == current ? 18 : 6, height: 6)
                }
            }
            .animation(.smooth, value: current)
        }
    }
}

// MARK: - Shared pieces

private struct StepHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 30, weight: .bold))
            Text(subtitle)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 24)
    }
}

private struct SuccessBadge: View {
    let text: String

    var body: some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.green)
            .transition(.scale.combined(with: .opacity))
    }
}

private struct Card<Content: View>: View {
    var tint: Color = .secondary
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14).fill(tint.opacity(tint == .secondary ? 0.07 : 0.1)))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - 1. Allow

private struct AllowStep: View {
    @EnvironmentObject private var controller: AppController

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StepHeader(
                title: "Your AirPods are now a mouse",
                subtitle: "Turn your head to point. Rest on a button to click. First, allow two things."
            )
            VStack(spacing: 12) {
                row(
                    symbol: "cursorarrow.click.2",
                    title: "Accessibility",
                    detail: "Lets AirPodsCursor move the pointer and click. Turn it on in the list that opens.",
                    granted: controller.accessibilityTrusted,
                    action: controller.requestAccessibility
                )
                row(
                    symbol: "gyroscope",
                    title: "Motion",
                    detail: "Lets AirPodsCursor read your head movement. It never leaves your Mac.",
                    granted: controller.motionAuthorization == .authorized,
                    denied: controller.motionAuthorization == .denied,
                    action: controller.requestMotionAccess
                )
            }
            Spacer()
        }
    }

    private func row(symbol: String, title: String, detail: String, granted: Bool, denied: Bool = false, action: @escaping () -> Void) -> some View {
        Card {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 20))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 15, weight: .semibold))
                    Text(denied ? "Turned off. Switch it on in System Settings › Privacy & Security › Motion & Fitness." : detail)
                        .font(.system(size: 13))
                        .foregroundStyle(denied ? .orange : .secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 16)
                if granted {
                    SuccessBadge(text: "Allowed")
                } else {
                    Button(denied ? "Open Settings" : "Allow") {
                        if denied, let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") {
                            NSWorkspace.shared.open(url)
                        } else {
                            action()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        }
        .animation(.spring(duration: 0.3), value: granted)
    }
}

// MARK: - 2. Connect

private struct ConnectStep: View {
    @EnvironmentObject private var controller: AppController

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StepHeader(
                title: "Put your AirPods in",
                subtitle: "When the earbuds on the left move with your head, you’re ready."
            )

            if controller.motionStreaming {
                Card(tint: .green) {
                    VStack(alignment: .leading, spacing: 6) {
                        SuccessBadge(text: "Connected")
                        Text("Look around. The pointer follows your head.").foregroundStyle(.secondary)
                    }
                }
            } else if !controller.trackingEnabled, !controller.accessibilityTrusted {
                Card(tint: .orange) {
                    HStack {
                        Text("Allow Accessibility first (step 1).").foregroundStyle(.orange)
                        Spacer()
                        Button("Allow") { controller.requestAccessibility() }
                    }
                }
            } else if let device = controller.connectedHeadphones, !device.likelySupportsMotion {
                Card(tint: .orange) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(device.name) can’t track your head").font(.system(size: 14, weight: .semibold))
                        Text("Use AirPods Pro, AirPods Max, AirPods (3rd generation or later) or Beats Fit Pro.")
                            .foregroundStyle(.secondary)
                    }
                }
            } else if controller.needsAudioHandoff {
                Card(tint: .orange) {
                    HStack(spacing: 12) {
                        Text("Your AirPods are playing on another device. Pick them in Control Center › Sound.")
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Button("Use on this Mac") {
                            if !controller.routeAudioToHeadphonesIfNeeded(force: true) { AppController.openSoundSettings() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else if let device = controller.pairedHeadphones.first(where: { !$0.isConnected && $0.likelySupportsMotion }),
                      controller.connectedHeadphones == nil {
                Card {
                    HStack {
                        Image(systemName: device.symbol).frame(width: 26)
                        Text(device.name).font(.system(size: 14, weight: .medium))
                        Spacer()
                        if controller.busyDeviceID == device.id {
                            ProgressView().controlSize(.small)
                        } else {
                            Button("Connect") { controller.connect(device) }
                                .buttonStyle(.borderedProminent)
                        }
                    }
                }
            } else if controller.pairedHeadphones.isEmpty {
                Card {
                    HStack {
                        Text("No AirPods paired with this Mac yet.").foregroundStyle(.secondary)
                        Spacer()
                        Button("Open Bluetooth Settings") { BluetoothService.openSystemBluetoothSettings() }
                    }
                }
            } else {
                Card {
                    HStack(spacing: 10) {
                        ProgressView().controlSize(.small)
                        Text("Waiting for your AirPods. Make sure both are in your ears.")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
            Text("Works with AirPods Pro, AirPods Max, AirPods (3rd gen or later) and Beats Fit Pro.")
                .font(.caption).foregroundStyle(.tertiary)
        }
        .task {
            while !Task.isCancelled {
                controller.refreshDevices(allowPrompt: true)
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }
}

// MARK: - 3. Done

private struct DoneStep: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StepHeader(
                title: "You’re all set",
                subtitle: "AirPodsCursor lives in the menu bar. Here’s all you need to know."
            )
            VStack(alignment: .leading, spacing: 20) {
                feature("cursorarrow.motionlines", "Point", "Turn your head. The pointer follows.")
                feature("cursorarrow.click", "Click", "Rest on a button. A ring fills, then it clicks.")
                feature("book", "Read", "Rest near the bottom of the screen to scroll down, near the top to scroll up.")
                feature("arrow.left.and.right", "Turn on or off", "Shake your head. You’ll hear a sound.")
            }
            Spacer()
        }
    }

    private func feature(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(Color.accentColor)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .semibold))
                Text(detail).font(.system(size: 13)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
