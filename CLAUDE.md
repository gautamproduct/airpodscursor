# AirPodsCursor — project guide

AirPodsCursor is a free, open-source macOS menu bar app that turns AirPods head tracking into a
mouse pointer. Turn your head to point. Rest on a button to click (smart hover click), or nod,
or press the stem. It is hands-free, private (no network, no analytics), and simple.

## Architecture

- `Sources/AirPodsCursorCore/`: pure, unit-tested Swift. Pointer mapping and smoothing
  (`Pointer.swift`), gesture and dwell detection (`Gestures.swift`), trigger/action bindings
  (`Actions.swift`), reading scroll (`ReadingScroll.swift`), and settings with lenient decoding and versioned migration (`Settings.swift`).
- `Sources/AirPodsCursor/`: the macOS app. `AppController.swift` wires CoreMotion → pointer/gestures
  → actions. `Services/` holds the CoreMotion, CGEvent, IOBluetooth, MediaPlayer, CoreAudio and
  Accessibility integrations. `Views/` is SwiftUI (menu bar, settings, guided tour, 3D earbuds).
- `Tests/AirPodsCursorCoreTests/`: XCTest for the core. Run with `swift test`.
- Swift 5 language mode, macOS 15+, no third-party dependencies.

## What AirPodsCursor must stay (the product contract)

1. **Hands-free first.** The pointer follows the head via relative (velocity) mapping. Smart
   hover click is the default tap. It only clicks things that are clickable (Accessibility
   roles, compact pressable elements, pointing-hand cursor), never text being read. Nod and stem
   press remain alternatives. Hands-free reading scroll is a headline feature: resting the
   pointer in the bottom/top band of the usable screen scrolls the page, faster deeper in,
   and never steals a hover click from a clickable element. Shaking the head turns tracking off, and shaking again turns
   it back on, with a sound so it works without looking.
2. **Effortless first run.** Setup is three steps (allow permissions, put AirPods in,
   four things to know). Steps advance on their own once satisfied. It opens automatically whenever setup is incomplete, resumes where it left
   off, and Continue never blocks. Tracking is on by default and starts as soon as
   Accessibility is granted. Head gestures can't pause tracking during setup.
3. **Private by design.** No network requests, analytics, telemetry, crash reporters, remote
   config, update pings, or third-party SDKs. Motion data stays in memory. Nothing about the
   user's screen, apps or input is logged beyond the minimal diagnostics already present.
4. **Minimal permissions.** Only Accessibility, Motion and Bluetooth. No new entitlements,
   usage descriptions, sandbox changes, or privileged helpers.
5. **Safe input synthesis.** Never leave a mouse button held. A drag is released on pause,
   disconnect, stalled motion and sleep. A gesture must never fire twice for one movement.
6. **Settings never break.** New fields decode leniently with defaults. When defaults must
   change for existing users, bump `AppSettings.currentVersion` and add a migration step with a
   test.
7. **Original assets only.** No Apple artwork, 3D models, or SF Symbols in the app icon. Keep
   the trademark disclaimer in the README.
8. **Tested core.** Logic changes in `AirPodsCursorCore` come with tests. Tests are never deleted
   or weakened just to make a change pass.
