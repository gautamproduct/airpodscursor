import SwiftUI
import AirPodsCursorCore

/// Settings, laid out like System Settings: a sidebar of colored icons and grouped forms.
enum Pane: String, CaseIterable, Identifiable {
    case general, pointer, clicking, scrolling, gestures, airpods

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "General"
        case .pointer: "Pointer"
        case .clicking: "Clicking"
        case .scrolling: "Scrolling"
        case .gestures: "Head Gestures"
        case .airpods: "AirPods"
        }
    }

    var symbol: String {
        switch self {
        case .general: "gearshape.fill"
        case .pointer: "cursorarrow.motionlines"
        case .clicking: "cursorarrow.click"
        case .scrolling: "book.fill"
        case .gestures: "rotate.3d"
        case .airpods: "airpodspro"
        }
    }

    var color: Color {
        switch self {
        case .general: .gray
        case .pointer: .blue
        case .clicking: .orange
        case .scrolling: .green
        case .gestures: .purple
        case .airpods: .indigo
        }
    }
}

struct MainWindowView: View {
    @EnvironmentObject private var controller: AppController
    @State private var pane: Pane? = .general

    var body: some View {
        NavigationSplitView {
            List(Pane.allCases, selection: $pane) { p in
                Label {
                    Text(p.title)
                } icon: {
                    IconTile(symbol: p.symbol, color: p.color, size: 20)
                }
                .tag(p)
            }
            .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 240)
        } detail: {
            Group {
                switch pane ?? .general {
                case .general: GeneralView()
                case .pointer: PointerSettingsView()
                case .clicking: ClickingSettingsView()
                case .scrolling: ScrollingSettingsView()
                case .gestures: GestureSettingsView()
                case .airpods: DevicesView()
                }
            }
            .navigationTitle((pane ?? .general).title)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .onAppear { controller.windowVisibilityChanged() }
        .onDisappear { controller.windowVisibilityChanged() }
        .alert("AirPodsCursor", isPresented: Binding(get: { controller.lastError != nil }, set: { if !$0 { controller.clearError() } })) {
            Button("OK") { controller.clearError() }
        } message: {
            Text(controller.lastError ?? "")
        }
    }
}

// MARK: - General

struct GeneralView: View {
    @EnvironmentObject private var controller: AppController
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Form {
            Section {
                Toggle(isOn: Binding(get: { controller.trackingEnabled }, set: { controller.setTracking($0) })) {
                    Text("Head tracking")
                    Text("Shake your head or press \(HotKey.toggleTracking.display) to turn it on or off.")
                }
            }

            Section("Status") {
                StatusRow(title: "Accessibility", ok: controller.accessibilityTrusted,
                          value: controller.accessibilityTrusted ? "Allowed" : "Not allowed") {
                    Button("Allow…") { controller.requestAccessibility() }
                }
                StatusRow(title: "Motion", ok: controller.motionAuthorization == .authorized,
                          value: controller.motionAuthorization == .authorized ? "Allowed"
                               : controller.motionAuthorization == .denied ? "Turned off" : "Not allowed") {
                    Button("Allow…") {
                        if controller.motionAuthorization == .denied,
                           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") {
                            NSWorkspace.shared.open(url)
                        } else {
                            controller.requestMotionAccess()
                        }
                    }
                }
                StatusRow(title: "AirPods", ok: controller.motionStreaming,
                          value: controller.motionStreaming ? (controller.connectedHeadphones?.name ?? "Active")
                               : controller.needsAudioHandoff ? "Playing on another device"
                               : controller.connectedHeadphones != nil ? "Waiting for motion" : "Not connected") {
                    if controller.needsAudioHandoff {
                        Button("Use Here") {
                            if !controller.routeAudioToHeadphonesIfNeeded(force: true) { AppController.openSoundSettings() }
                        }
                    }
                }
                LabeledContent("Setup") {
                    Button("Set Up Again…") {
                        openWindow(id: WindowID.tour)
                        NSApp.activate()
                    }
                }
            }

            Section {
                Toggle("Open at login", isOn: Binding(get: { controller.launchAtLogin }, set: { controller.setLaunchAtLogin($0) }))
                Toggle(isOn: $controller.settings.routeAudioToHeadphones) {
                    Text("Use AirPods for Mac sound automatically")
                    Text("AirPods only send head movement to the device they’re playing on.")
                }
                Toggle("Show status messages", isOn: $controller.settings.showHUD)
                Toggle("Show where clicks land", isOn: $controller.settings.showClickPulse)
            }

            Section("Keyboard Shortcuts") {
                ForEach(HotKey.all, id: \.id) { key in
                    LabeledContent(key.description) {
                        Text(key.display).font(.body.monospaced()).foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                DisclosureGroup("Diagnostics") {
                    DiagnosticsRows()
                }
            } footer: {
                HStack {
                    Text("AirPodsCursor \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")")
                    Spacer()
                    Button("Reset All Settings…", role: .destructive) { confirmReset = true }
                        .buttonStyle(.link)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .confirmationDialog("Reset all settings?", isPresented: $confirmReset) {
            Button("Reset", role: .destructive) { controller.resetSettings() }
        } message: {
            Text("Speed, clicking, scrolling and gesture settings go back to their defaults.")
        }
    }

    @State private var confirmReset = false
}

private struct StatusRow<Fix: View>: View {
    let title: String
    let ok: Bool
    let value: String
    @ViewBuilder var fix: Fix

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: 8) {
                Text(value).foregroundStyle(.secondary)
                if ok {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                } else {
                    fix
                }
            }
        }
    }
}

// MARK: - Pointer

struct PointerSettingsView: View {
    @EnvironmentObject private var controller: AppController

    var body: some View {
        Form {
            Section {
                LabeledSlider(title: "Speed", value: $controller.settings.pointer.sensitivity, range: 0.2...4,
                              format: { String(format: "%.1f×", $0) })
                LabeledSlider(title: "Acceleration", value: $controller.settings.pointer.acceleration, range: 0...2,
                              format: { String(format: "%.1f", $0) },
                              help: "Quick turns travel farther. Slow turns stay precise.")
                LabeledSlider(title: "Steadiness", value: $controller.settings.pointer.deadzone, range: 0...20,
                              format: { String(format: "%.0f", $0) },
                              help: "Ignores tiny movements so the pointer holds still.")
                LabeledSlider(title: "Smoothing", value: $controller.settings.pointer.smoothing, range: 0...0.9,
                              format: { String(format: "%.0f%%", $0 * 100) })
            }

            Section {
                Toggle("Reverse left and right", isOn: $controller.settings.pointer.invertHorizontal)
                Toggle("Reverse up and down", isOn: $controller.settings.pointer.invertVertical)
            }

            Section {
                HeadVisualizer(live: controller.live, tiltThreshold: controller.settings.gestures.tiltAngle)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } header: {
                Text("Live Preview")
            } footer: {
                if !controller.motionStreaming {
                    Text("Put your AirPods in to see your head movement here.")
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Clicking

struct ClickingSettingsView: View {
    @EnvironmentObject private var controller: AppController

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $controller.settings.dwell.enabled) {
                    Text("Hover click")
                    Text("Rest the pointer on something and it clicks.")
                }
                if controller.settings.dwell.enabled {
                    Toggle("Only buttons, links and other controls", isOn: $controller.settings.dwell.smart)
                    LabeledSlider(title: "Rest time", value: $controller.settings.dwell.duration, range: 0.3...3,
                                  format: { String(format: "%.1f s", $0) })
                    ActionPicker(trigger: .dwell, action: binding(.dwell))
                }
            } footer: {
                Text("Paused while you type. Move the pointer to click again.")
            }

            Section {
                Toggle(isOn: $controller.settings.stemControlsEnabled) {
                    Text("Click with stem presses")
                    Text("Off: your AirPods buttons play, pause and skip music as usual.")
                }
                if controller.settings.stemControlsEnabled {
                    ForEach([Trigger.stemSingle, .stemDouble, .stemTriple]) { trigger in
                        ActionPicker(trigger: trigger, action: binding(trigger))
                    }
                }
            } header: {
                Text("Stem")
            } footer: {
                Text(controller.settings.stemControlsEnabled
                     ? "While head tracking is on, stem presses click instead of controlling music, and so do the play/pause keys. Use \(HotKey.playPause.display), \(HotKey.nextTrack.display) and \(HotKey.previousTrack.display) for music."
                     : "Music shortcuts: \(HotKey.playPause.display) play/pause, \(HotKey.nextTrack.display) next, \(HotKey.previousTrack.display) previous. You can also set a head tilt to skip tracks in Head Gestures.")
            }
        }
        .formStyle(.grouped)
    }

    private func binding(_ trigger: Trigger) -> Binding<PointerAction> {
        Binding(get: { controller.settings.actions[trigger] }, set: { controller.settings.actions[trigger] = $0 })
    }
}

// MARK: - Scrolling

struct ScrollingSettingsView: View {
    @EnvironmentObject private var controller: AppController

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $controller.settings.readingScroll.enabled) {
                    Text("Reading scroll")
                    Text("Rest the pointer near the bottom of the screen to scroll down, near the top to scroll up. Closer to the edge scrolls faster.")
                }
                if controller.settings.readingScroll.enabled {
                    LabeledSlider(title: "Speed", value: $controller.settings.readingScroll.speed, range: 0.2...3,
                                  format: { String(format: "%.1f×", $0) })
                    LabeledSlider(title: "Edge size", value: $controller.settings.readingScroll.zoneFraction, range: 0.08...0.3,
                                  format: { String(format: "%.0f%%", $0 * 100) })
                }
            }

            Section {
                LabeledSlider(title: "Speed", value: $controller.settings.pointer.scrollSpeed, range: 0.2...4,
                              format: { String(format: "%.1f×", $0) })
            } header: {
                Text("Scroll Mode")
            } footer: {
                Text("Press the stem three times or \(HotKey.scrollMode.display), then look in any direction to scroll.")
            }

            Section {
                Toggle("Reverse scroll direction", isOn: $controller.settings.pointer.invertScroll)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Head Gestures

struct GestureSettingsView: View {
    @EnvironmentObject private var controller: AppController

    var body: some View {
        Form {
            Section {
                ForEach([Trigger.nod, .shake, .tiltLeft, .tiltRight]) { trigger in
                    ActionPicker(trigger: trigger, action: binding(trigger))
                }
            } footer: {
                Text("A nod clicks where the pointer was before you nodded.")
            }

            Section("Sensitivity") {
                LabeledSlider(title: "Nod size", value: $controller.settings.gestures.nodAmplitude, range: 3...20, step: 0.5,
                              format: { String(format: "%.1f°", $0) },
                              help: controller.lastNodDepth.map { String(format: "Your last nod: %.1f°", $0) })
                LabeledSlider(title: "Shake size", value: $controller.settings.gestures.shakeAmplitude, range: 4...25, step: 0.5,
                              format: { String(format: "%.1f°", $0) })
                LabeledSlider(title: "Tilt angle", value: $controller.settings.gestures.tiltAngle, range: 10...40,
                              format: { String(format: "%.0f°", $0) })
                Toggle("Swap tilt left and right", isOn: $controller.settings.gestures.swapTiltDirection)
            }
        }
        .formStyle(.grouped)
    }

    private func binding(_ trigger: Trigger) -> Binding<PointerAction> {
        Binding(get: { controller.settings.actions[trigger] }, set: { controller.settings.actions[trigger] = $0 })
    }
}

// MARK: - AirPods

struct DevicesView: View {
    @EnvironmentObject private var controller: AppController
    @EnvironmentObject private var pairing: PairingService

    var body: some View {
        Form {
            Section {
                if controller.pairedHeadphones.isEmpty {
                    Text("No AirPods paired with this Mac.").foregroundStyle(.secondary)
                }
                ForEach(controller.pairedHeadphones) { device in
                    HStack(spacing: 12) {
                        Image(systemName: device.symbol)
                            .font(.title3)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(device.name)
                            Text(subtitle(for: device)).font(.callout).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if controller.busyDeviceID == device.id {
                            ProgressView().controlSize(.small)
                        } else if device.isConnected {
                            Button("Disconnect") { controller.disconnect(device) }
                        } else {
                            Button("Connect") { controller.connect(device) }
                        }
                    }
                }
            } footer: {
                Text("Works with AirPods Pro, AirPods Max, AirPods (3rd generation and later) and Beats Fit Pro.")
            }

            Section {
                HStack {
                    Button(pairing.isSearching ? "Stop" : "Pair New AirPods…") {
                        pairing.isSearching ? pairing.stopSearch() : pairing.startSearch()
                    }
                    if pairing.isSearching { ProgressView().controlSize(.small) }
                    pairingStatus
                    Spacer()
                    Button("Bluetooth Settings…") { BluetoothService.openSystemBluetoothSettings() }
                }
                ForEach(pairing.discovered.filter { !$0.isPaired }) { device in
                    HStack {
                        Image(systemName: device.symbol).frame(width: 28)
                        Text(device.name)
                        Spacer()
                        Button("Pair") { pairing.pair(device.id) }
                            .disabled(isPairing)
                    }
                }
            } footer: {
                if pairing.isSearching {
                    Text("Open the case near your Mac and hold the button on the back until the light flashes white.")
                }
            }
        }
        .formStyle(.grouped)
        .task {
            while !Task.isCancelled {
                controller.refreshDevices(allowPrompt: true)
                try? await Task.sleep(for: .seconds(3))
            }
        }
        .onDisappear { pairing.stopSearch() }
    }

    private var isPairing: Bool {
        if case .pairing = pairing.state { return true }
        return false
    }

    @ViewBuilder private var pairingStatus: some View {
        switch pairing.state {
        case .idle, .searching: EmptyView()
        case .pairing(let name): Text("Pairing with \(name)…").foregroundStyle(.secondary)
        case .paired(let name): Label("\(name) paired", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
        case .failed(let message): Text(message).foregroundStyle(.secondary).lineLimit(2)
        }
    }

    private func subtitle(for device: HeadphoneDevice) -> String {
        if device.isConnected, controller.motionStreaming { return "Head tracking active" }
        if !device.likelySupportsMotion { return device.isConnected ? "Connected · No head tracking" : "No head tracking" }
        return device.isConnected ? "Connected" : "Not connected"
    }
}
