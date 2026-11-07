# Hands-on test plan

Run before each release, with real AirPods. Each line says what to do and what should happen. Tick it only if it does.

## AirPods

- [ ] **No AirPods connected.** Menu bar shows "Waiting for AirPods". Nothing moves, nothing clicks.
- [ ] **Both buds in.** The pointer follows your head within a second of putting them in.
- [ ] **One bud in.** The pointer still follows your head.
- [ ] **Take one bud out while tracking.** No click happens. The pointer doesn't jump.
- [ ] **Take both buds out and put them in the case.** No click, no scroll, no gesture. The pointer stops where it was.
- [ ] **Turn the buds over in your hand, or drop one on the desk.** The pointer doesn't fly across the screen.
- [ ] **Close the case.** Menu bar shows "Waiting for AirPods". Activity Monitor shows AirPodsCursor near 0% CPU.
- [ ] **Hold or wave the closed case near the Mac.** Nothing happens.
- [ ] **AirPods playing on your iPhone.** The app says they're on another device. **Use Here** switches them to the Mac.
- [ ] **Choose your Mac's speakers by hand with AirPods connected but out of your ears.** The output stays on the speakers.
- [ ] **AirPods (2nd generation) or other Bluetooth headphones.** Setup says they can't track your head.

## Head

- [ ] **Shake.** Tracking turns off with a sound. Shake again: it turns on with a different sound.
- [ ] **Shake during setup.** Nothing toggles.
- [ ] **Nod on a button.** It clicks where the pointer was before the nod.
- [ ] **Look around a room, glance left then right.** No shake fires.
- [ ] **Walk around, or sit in a moving car.** The pointer may drift. Shake off works.

## Clicking and scrolling

- [ ] **Rest on a button.** A ring fills, then it clicks once. Resting longer doesn't click again.
- [ ] **Rest on plain text.** Nothing happens.
- [ ] **Press the stem once.** It clicks after a short beat. Twice: right-click. Three times: scroll mode.
- [ ] **Rest near the bottom of a long article.** It scrolls down, faster closer to the edge. Move to the middle: it stops.
- [ ] **Rest near the top.** It scrolls up.
- [ ] **Rest on a browser tab near the top.** It clicks the tab instead of scrolling.
- [ ] **Rest over the Dock.** No scrolling.
- [ ] **Type in a text field.** No hover clicks or scrolling while you type.
- [ ] **Start a drag (⌃⌥D), then take the AirPods out.** The drag is released.

## Mac

- [ ] **Move the trackpad while tracking.** The pointer goes where you put it, then follows your head from there.
- [ ] **Two displays.** The pointer crosses between them. Reading scroll works on both.
- [ ] **Sleep and wake.** Tracking resumes on its own. No button is left held down.
- [ ] **Turn off Accessibility for AirPodsCursor.** Tracking stops. Setup reopens.
