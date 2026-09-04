# AudioFlow 1.2.1

Release date: 2026-09-05

AudioFlow 1.2.1 makes small volume changes precise without making the mixer larger. Compact menu-bar, per-app, and device rows now combine the existing slider with an editable percentage and 1% controls; other system-volume surfaces gain matching 1% keyboard or accessibility adjustment while preserving native macOS behavior.

## Iteration goal

Short sliders are convenient for fast changes but are difficult to place on an exact value such as 8% or 12%. The first precision-control exploration used the native number-field stepper, which occupied too much visual space and made the rows look inconsistent. This iteration replaces it with a compact control designed specifically for AudioFlow and fixes the alignment difference between one-, two-, and three-digit percentages.

## What changed

### Exact volume control

- Percentage labels are now editable fields accepting integer values from `0` through `100`.
- Values outside the range are clamped safely to the nearest boundary.
- The integrated up and down buttons adjust by exactly 1% per click and disable at 100% or 0% respectively.
- Focused volume sliders respond to Arrow keys in 1% steps and Shift + Arrow in 5% steps.
- Direct entry, step buttons, keyboard control, accessibility actions, displayed values, and Core Audio writes share the same rounded percentage conversion.

### Compact visual refinement

- Replaced the native stepper with a custom 14 pt-wide two-button strip inside the percentage control.
- Added quiet default, hover, pressed, focused, and disabled-boundary states without increasing row height.
- Centered the complete `number + %` group in a fixed 36 pt value area. Single-digit `8%`, double-digit `12%`, and triple-digit `100%` now align to the same center.
- Made the whole value area clickable so a one-digit number remains easy to focus, while the step buttons keep independent hit targets.

### Coverage across AudioFlow

Precision controls are applied consistently to:

- Minimal menu-bar overall volume and per-app rows.
- Full menu-bar system volume and per-app rows.
- Mixer active-application rows; the System Output slider gains 1% keyboard stepping and the circular control gains 1% accessibility adjustment.
- Device workspace output and input volume rows.

### Live-state safety

- Opening an AppKit popover can automatically focus its first text field. Focus alone no longer marks the percentage as user-edited, so a live value such as 40.79% is displayed as 41% without silently writing 41% back to the device.
- Losing focus, pressing Return, or closing the transient popover uses one commit path to avoid duplicate Core Audio writes.
- Percentage updates use a strict shared comparison tolerance, allowing intentional 1% changes to reach the engine while suppressing duplicate writes.

### Localization and accessibility

- Added precision-control copy for Simplified Chinese, English, Japanese, French, German, and Korean.
- Added distinct accessibility names and values for sliders, editable percentages, increment actions, and decrement actions.
- Removed row-level accessibility grouping that previously hid the individual controls.
- Hid the visual percent sign from accessibility so it is not announced as a duplicate element.

## Validation

- All 8 Swift tests passed in a fresh scratch directory with compiler warnings treated as errors.
- A fresh Release build passed with compiler warnings treated as errors.
- Source whitespace validation passed with `git diff --check`.
- Conversion tests cover rounding, clamping, and reversible percentage-to-scalar commits.
- Localization tests cover all six supported languages.
- Real menu-bar popover inspection covered `8%`, `12%`, and `100%` centering; clicks across the complete value area; double-click selection of `100`; direct entry; Return commit; 1% increment/decrement; and editing a draft value before stepping.
- Accessibility inspection found exactly one percentage text field and two independent step buttons, with no duplicate percent-sign element.
- The installed application was exercised against live system and QQ Music volume controls, then the test values were restored.
- Independently extracted ZIP and DMG-mounted applications both reported version 1.2.1 (build 13) and passed strict deep code-signature verification.

## Compatibility and packaging

- macOS 14.2 or later.
- Apple Silicon community build.
- Existing AudioFlow settings continue to load.
- Audio remains processed locally in memory and is never recorded, saved, or uploaded.
- Community artifacts are ad-hoc signed and are not Apple-notarized.

## Known limitations

- Per-app volume follows the current Core Audio process session. During validation, restarting AudioFlow recreated the QQ Music row at 100%; 1.2.1 does not yet persist per-app volume across an AudioFlow restart.
- Exact percentage control does not change the physical step resolution exposed by a particular audio device. AudioFlow submits the requested value, while some hardware may report the nearest value it supports.

## Downloads

- `AudioFlow.dmg` — drag-to-install disk image.
- `AudioFlow-macOS.zip` — portable application archive.

### SHA-256

```text
ea784d87b7210a62fa537e0a160d9d543c64581a54c530b3dab98c1c821f4f67  AudioFlow.dmg
0a8e0277d808920d25d0a3837278eab14d8f4a319a1b2643160c65bc929dc74f  AudioFlow-macOS.zip
```
