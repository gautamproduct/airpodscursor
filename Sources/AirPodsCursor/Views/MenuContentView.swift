import SwiftUI
import AirPodsCursorCore

/// The menu bar window, laid out like a Control Center module: one switch, the
/// headphones, a couple of quick controls, then menu-style rows.
struct MenuContentView: View {
    @EnvironmentObject private var controller: AppController
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 12)

            if let notice {
                NoticeRow(notice: notice)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
            }

            MenuDivider()

            VStack(alignment: .leading, spacing: 4) {
                SectionLabel("Headphones")
                deviceRow
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            MenuDivider()

            VStack(alignment: .leading, spacing: 10) {
                Picker("Mode", selection: Binding(get: { controller.mode }, set: { controller.setMode($0) })) {
                    Text("Pointer").tag(TrackingMode.pointer)
                    Text("Scroll").tag(TrackingMode.scroll)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .disabled(!controller.trackingEnabled)

                VStack(alignment: .leading, spacing: 4) {
                    SectionLabel("Pointer Speed")
                    Slider(value: $controller.settings.pointer.sensitivity, in: 0.2...4) {
                        Text("Pointer Speed")
                    } minimumValueLabel: {
                        Image(systemName: "tortoise.fill").foregroundStyle(.secondary)
                    } maximumValueLabel: {
                        Image(systemName: "hare.fill").foregroundStyle(.secondary)
                    }
                    .labelsHidden()
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            VStack(spacing: 0) {
                ToggleRow(title: "Hover Click", symbol: "cursorarrow.click", isOn: $controller.settings.dwell.enabled)
                ToggleRow(title: "Reading Scroll", symbol: "book", isOn: $controller.settings.readingScroll.enabled)
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 6)

            MenuDivider()

            VStack(spacing: 0) {
                MenuRow(title: "Settings…", shortcut: "⌘,") { open(WindowID.main) }
                MenuRow(title: "Set Up Again…") { open(WindowID.tour) }
            }
            .padding(6)

            MenuDivider()

            MenuRow(title: "Quit AirPodsCursor", shortcut: "⌘Q") { NSApp.terminate(nil) }
                .padding(6)
        }
        .frame(width: 300)
        .task { controller.refreshDevices() }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 12) {
            IconTile(symbol: "cursorarrow.motionlines", color: controller.trackingEnabled ? .accentColor : .gray, size: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text("AirPodsCursor").font(.system(size: 13, weight: .semibold))
                Text(controller.statusText)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Toggle("Head Tracking", isOn: Binding(get: { controller.trackingEnabled }, set: { controller.setTracking($0) }))
                .toggleStyle(.switch)
                .labelsHidden()
                .help("Head Tracking (\(HotKey.toggleTracking.display)). Or shake your head.")
        }
    }

    // MARK: Headphones

    @ViewBuilder private var deviceRow: some View {
        if let device = controller.connectedHeadphones {
            DeviceRow(symbol: device.symbol, title: device.name,
                      subtitle: controller.motionStreaming ? "Head tracking active" : "Connected",
                      active: controller.motionStreaming) { EmptyView() }
        } else if let device = controller.pairedHeadphones.first {
            DeviceRow(symbol: device.symbol, title: device.name, subtitle: "Not connected", active: false) {
                if controller.busyDeviceID == device.id {
                    ProgressView().controlSize(.small)
                } else {
                    Button("Connect") { controller.connect(device) }
                        .controlSize(.small)
                        .disabled(controller.busyDeviceID != nil)
                }
            }
        } else {
            DeviceRow(symbol: "airpodspro", title: "No AirPods", subtitle: "Pair them in Bluetooth Settings", active: false) {
                Button("Open") { BluetoothService.openSystemBluetoothSettings() }
                    .controlSize(.small)
            }
        }
    }

    // MARK: Notices

    private var notice: Notice? {
        if !controller.accessibilityTrusted {
            return Notice(text: "Allow Accessibility so AirPodsCursor can move the pointer.", button: "Allow") {
                controller.requestAccessibility()
            }
        }
        if controller.needsAudioHandoff {
            return Notice(text: "Your AirPods are playing on another device.", button: "Use Here") {
                if !controller.routeAudioToHeadphonesIfNeeded(force: true) { AppController.openSoundSettings() }
            }
        }
        return nil
    }

    private func open(_ id: String) {
        openWindow(id: id)
        NSApp.activate()
    }
}

// MARK: - Pieces

private struct Notice {
    let text: String
    let button: String
    let action: () -> Void
}

private struct NoticeRow: View {
    let notice: Notice

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(notice.text)
                .font(.system(size: 11))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            Button(notice.button, action: notice.action)
                .controlSize(.small)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.quaternary.opacity(0.6)))
    }
}

private struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }
}

private struct DeviceRow<Accessory: View>: View {
    let symbol: String
    let title: String
    let subtitle: String
    let active: Bool
    @ViewBuilder var accessory: Accessory

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(active ? .white : .primary)
                .frame(width: 26, height: 26)
                .background(Circle().fill(active ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary)))
            VStack(alignment: .leading, spacing: 0) {
                Text(title).font(.system(size: 13)).lineLimit(1)
                Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 8)
            accessory
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
}

private struct ToggleRow: View {
    let title: String
    let symbol: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Label(title, systemImage: symbol)
                .font(.system(size: 13))
        }
        .toggleStyle(.switch)
        .controlSize(.mini)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
    }
}

/// A full-width row that highlights on hover, like a menu item.
private struct MenuRow: View {
    let title: String
    var shortcut: String? = nil
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                if let shortcut {
                    Text(shortcut).foregroundStyle(hovering ? Color.white.opacity(0.8) : Color.secondary)
                }
            }
            .font(.system(size: 13))
            .foregroundStyle(hovering ? Color.white : Color.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(hovering ? Color.accentColor : .clear))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

private struct MenuDivider: View {
    var body: some View {
        Divider().padding(.horizontal, 14)
    }
}

/// A rounded-square icon with a white symbol, in the style of System Settings.
struct IconTile: View {
    let symbol: String
    let color: Color
    var size: CGFloat = 22

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.52, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                    .fill(color.gradient)
            )
    }
}
