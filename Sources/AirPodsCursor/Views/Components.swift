import SwiftUI
import AirPodsCursorCore

/// A slider row in the System Settings style: title (and optional hint) on the left,
/// slider and value on the right.
struct LabeledSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double? = nil
    var format: (Double) -> String = { String(format: "%.2f", $0) }
    var help: String? = nil

    var body: some View {
        LabeledContent {
            HStack(spacing: 10) {
                Group {
                    if let step {
                        Slider(value: $value, in: range, step: step)
                    } else {
                        Slider(value: $value, in: range)
                    }
                }
                .labelsHidden()
                .frame(width: 200)
                Text(format(value))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 44, alignment: .trailing)
            }
        } label: {
            Text(title)
            if let help { Text(help) }
        }
    }
}

struct ActionPicker: View {
    let trigger: Trigger
    @Binding var action: PointerAction

    var body: some View {
        Picker(trigger.displayName, selection: $action) {
            ForEach(PointerAction.groups, id: \.title) { group in
                if group.title.isEmpty {
                    ForEach(group.actions) { a in Text(a.displayName).tag(a) }
                } else {
                    Section(group.title) {
                        ForEach(group.actions) { a in Text(a.displayName).tag(a) }
                    }
                }
            }
        }
    }
}

/// Live head movement: the dot follows how fast you turn, the readouts show the angles.
struct HeadVisualizer: View {
    let live: LiveReadout
    let tiltThreshold: Double

    var body: some View {
        HStack(spacing: 28) {
            ZStack {
                Circle().fill(.quaternary.opacity(0.5))
                Circle().strokeBorder(.quaternary, lineWidth: 1).padding(30)
                Circle()
                    .fill(live.hasData ? Color.accentColor : Color.secondary.opacity(0.5))
                    .frame(width: 14, height: 14)
                    .shadow(color: live.hasData ? Color.accentColor.opacity(0.5) : .clear, radius: 6)
                    .offset(x: clamp(-live.yawRate / 3), y: clamp(-live.pitchRate / 3))
                    .animation(.easeOut(duration: 0.1), value: live)
            }
            .frame(width: 140, height: 140)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                row("Turn", live.yaw)
                row("Nod", live.pitch)
                row("Tilt", live.relativeRoll)
            }
            .font(.callout)
        }
    }

    private func clamp(_ v: Double) -> Double { min(max(v, -60), 60) }

    private func row(_ title: String, _ value: Double) -> some View {
        GridRow {
            Text(title).foregroundStyle(.secondary)
            Text(live.hasData ? String(format: "%+.0f°", value) : "—").monospacedDigit()
        }
    }
}

/// Every link in the chain, for troubleshooting and bug reports.
struct DiagnosticsRows: View {
    @EnvironmentObject private var controller: AppController

    var body: some View {
        ForEach(controller.diagnostics.rows, id: \.label) { row in
            LabeledContent {
                HStack(spacing: 6) {
                    Text(row.value).foregroundStyle(.secondary).textSelection(.enabled)
                    Image(systemName: row.ok ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(row.ok ? .green : .orange)
                }
            } label: {
                Text(row.label)
            }
            .font(.callout)
        }
        HStack {
            Spacer()
            Button("Copy Diagnostics") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(controller.diagnostics.text, forType: .string)
            }
        }
    }
}
