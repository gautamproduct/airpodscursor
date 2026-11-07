# Contributing to AirPodsCursor

Thanks for helping! Bug reports, gesture-tuning data, and pull requests are all welcome.

## Getting set up

```bash
git clone https://github.com/gautamproduct/airpodscursor.git
cd airpodscursor
make test   # run the core unit tests
make run    # build build/AirPodsCursor.app (arm64) and launch it
```

Requirements: macOS 15+, Xcode 16+, and AirPods with head tracking for anything motion-related.

macOS ties Accessibility permission to the app's code signature. `scripts/build-app.sh` signs with your first *Apple Development* or *Developer ID* identity if one exists. Without one it falls back to ad-hoc signing, and then you have to re-grant Accessibility after every rebuild.

## Where things live

| Path | What |
|---|---|
| `Sources/AirPodsCursorCore` | Pure, unit-tested logic: pointer mapping, smoothing, gesture and dwell detection, settings |
| `Sources/AirPodsCursor/Services` | macOS integrations: CoreMotion, CGEvent, IOBluetooth, MediaPlayer, CoreAudio, hot keys |
| `Sources/AirPodsCursor/AppController.swift` | Wires motion → pointer/gestures → actions |
| `Sources/AirPodsCursor/Views` | SwiftUI: menu bar, settings, guided tour, 3D earbuds |
| `scripts/` | App bundling, icon, release |

## Guidelines

- Put logic in `AirPodsCursorCore` wherever possible, with tests. Gesture changes should come with a test that feeds synthetic motion (see `GestureTests`).
- Keep the app private by design: no network calls, no analytics.
- Run `make test` before opening a PR. CI runs the same tests.
- To capture every setup step as PNG, run `open build/AirPodsCursor.app --env AIRPODSCURSOR_SNAPSHOT_DIR=/tmp/shots`.

## How releases work

- CI runs the tests and builds the app on every push and PR.
- **Releases are automatic.** Every push to `main` that changes the app publishes the next patch version. Add the `release:minor` or `release:major` label to the merged PR for a bigger bump, or `skip-release` to hold it back. Documentation-only changes never release.

## Reporting bugs

Please include the output of **Settings › General › Diagnostics › Copy Diagnostics**. It shows exactly which link in the chain (permissions, Bluetooth, audio route, motion) is failing.
