# Changelog

All notable changes to AudioFlow are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.1] - 2026-09-05

### Added

- Editable `0...100` percentage fields beside volume sliders for exact total, per-app, output-device, and input-device volume entry.
- Compact integrated up/down controls that adjust volume by exactly 1% without expanding the existing mixer rows.
- One-percent keyboard stepping for volume sliders, with Shift + Arrow adjusting by 5%.
- Localized labels, help text, and accessibility descriptions for the precision controls in Simplified Chinese, English, Japanese, French, German, and Korean.

### Changed

- Centered the complete number-and-percent group for one-, two-, and three-digit values so `8%`, `12%`, and `100%` share the same visual center.
- Replaced native number-field stepper chrome with a custom 14 pt control strip that matches AudioFlow's compact macOS visual language and includes hover, pressed, boundary-disabled, and focus states.
- Made the complete 36 pt percentage value area clickable while keeping the stepper buttons independent, improving hit targets without adding row width.
- Unified displayed percentages, direct entry, stepper commits, slider steps, circular-control accessibility actions, and Core Audio comparisons around one shared rounded conversion boundary.
- Kept percentage fields synchronized with live hardware values until the user actually edits them, preventing automatic popover focus from rounding the device volume.
- Moved application-row accessibility context onto the app name so the slider, percentage field, and increment/decrement actions remain individually discoverable.

### Fixed

- Fixed short sliders being unable to reliably land on a specific percentage.
- Fixed one- and two-digit percentage values appearing off-center compared with three-digit values.
- Fixed direct entry or popover focus potentially turning a fractional hardware value into an unintended integer write.
- Fixed application volume controls remaining visually or interactively active while the system master was muted or the app control was unavailable on some mixer surfaces.

### Verified

- `swift test -Xswiftc -warnings-as-errors` passed all 8 tests in a fresh scratch directory.
- `swift build -c release -Xswiftc -warnings-as-errors` passed in the same fresh scratch directory.
- `git diff --check` passed.
- Real menu-bar popover checks covered centered `8%`, `12%`, and `100%` states; full-value-area focus; direct entry; 1% increment/decrement; draft entry followed by stepping; Return commit; and restoration to the original test volume.
- Accessibility inspection confirmed one percentage text field and two distinct step actions without a duplicate `%` element.
- Independently extracted ZIP and DMG-mounted applications both reported version 1.2.1 (build 13) and passed strict deep code-signature verification.

### Known limitations

- Per-app volume is bound to the current Core Audio process session and may return to 100% after AudioFlow itself restarts; this release does not add cross-restart per-app volume persistence.
- Community artifacts are ad-hoc signed and are not Apple-notarized.

## [1.2.0] - 2026-08-14

### Added

- A real-time ten-band graphic equalizer with independent total and per-app stages, preamp headroom, soft peak protection, local persistence, and named presets.
- Mixer-only entry points: total EQ in the System Output card and per-app EQ in each application row's More menu.
- Real-time algorithmic room processing after each EQ stage, with room size, damping, pre-delay, stereo width, adjustable wet mix, and six acoustic-space presets: Small Room, Studio, Home Theater, Theater, Concert Hall, and Cathedral.
- Independent per-preset memory for the total equalizer and every application equalizer, covering bands, preamp, room intensity, and stereo balance.
- Real stereo-balance DSP at both equalizer stages. Moving toward one channel only attenuates the opposite channel and never adds gain.
- A conditional Turn Off All EQ control in both the Mixer header and menu-bar popover. It appears whenever Total EQ is enabled, or when an EQ belonging to an app in the current list is enabled; EQ memory from exited apps does not expose the action. Disabling preserves every preset value.

### Changed

- Moved the total-EQ entry into the System Output header and combined per-app EQ with More as one segmented action group, removing the default-window dock overflow and reducing row-level control clutter.
- Expanded all EQ presets into one visible strip, moved live-DSP status to the upper-right header, removed the footer signal chain, replaced the response polyline with an animated smooth curve, and decoupled pointer updates from 30 Hz DSP commits for fluid slider tracking.
- Added native EQ interface and feedback copy for Japanese, French, German, and Korean instead of falling back to English.
- Strengthened tone presets to roughly ±6–9 dB, increased scene wet mix, broadened adjacent EQ bands, and lowered preset preamps to keep clear peak headroom.
- Split presets into fully visible Tone and Spaces rows, with a dedicated Space Intensity control for tuning room and theater ambience without changing output volume.
- Reset now restores only the currently selected preset to its factory curve while retaining every other preset's remembered adjustments.
- Reworked the preset area as two icon-based preset galleries with explicit option surfaces and no oversized row containers.
- Emphasized low and medium curve movement with a nonlinear visual scale and subtle zero-line fill; this changes only visualization, not DSP values.
- Made total and per-app equalizers mutually exclusive: enabling total EQ disables all app EQs, while enabling any app EQ disables total EQ.
- Added a one-time conflict migration for older saved settings; when both layers were active, the visible total-EQ choice is retained and app EQs are disabled.
- Preset galleries now show one checkmark only on the currently selected preset; remembered preset edits remain saved without extra selection markers.
- Replaced the ambiguous power symbol on EQ shutdown actions with a literal slashed-EQ mark, and added a visible localized “Turn Off EQ” label in the menu-bar popover.
- Moved periodic device volume, mute, topology, latency, capability, and login-item reads off the main thread and coalesced overlapping refresh requests.
- Replaced synchronous Core Audio calls inside the device-page render path with cached background snapshots and made device writes optimistic and asynchronous.
- Cached per-process exposure metadata so recurring application scans no longer repeat bundle-path traversal for every audio process.
- Unified navigation, button, popover, disclosure, preset, and reorder motion; page changes no longer animate the complete glass workspace, and EQ controls no longer stack nested spring animations.
- Replaced the three remaining SwiftUI EQ sliders with the native throttled slider bridge and capped ten-band drag publications at the display-friendly 60 Hz rate while preserving exact final values.
- Hid scroll indicators in every controller, device, settings, application-list, and menu-bar scroll region while retaining scrolling.
- Forced the Mixer “Turn Off All EQ” action onto one line at every supported window width.

### Verified

- `swift build -Xswiftc -warnings-as-errors`
- Local main-window inspection of the total-EQ entry, ten adjustable bands, preset switching, bypass state, and persisted passthrough reset.
- Installed-app visual inspection at the default window size with a zero-sample QuickTime source; master and app EQ remained bypassed at 0 dB and system volume remained at 0%.
- Installed build 3 inspection confirmed the expanded preset strip, upper-right DSP status, removed footer signal chain, smooth response curve, and restored passthrough state while system volume remained at 0%.
- Runtime switching confirmed native equalizer copy in Japanese, French, German, and Korean, followed by restoration to Simplified Chinese.
- Strict compilation verified the scene reverb DSP, backward-compatible persisted settings, expanded preset layout, and all six localization tables.
- Swift tests verify per-preset recall, current-preset-only reset, stereo-balance persistence, and legacy settings migration.
- A five-second installed-build sample identified the previous main-thread HAL polling path; strict compilation after the refactor confirms all device queries now originate from dedicated read/write queues.

## [1.1.0] - 2026-08-14

### Added

- Minimal and Full menu-bar popover styles, switchable from General settings and persisted locally.
- A compact global app order for Minimal mode with drag-to-reorder and restart-safe persistence.
- A dedicated 1.1.0 release note that records the iteration scope and validation evidence.

### Changed

- Reduced the Minimal popover width from 420 pt to 336 pt and app-row height from 48 pt to 44 pt.
- Minimal mode now shows only overall volume, app icons and names, mute controls, volume sliders, percentages, and a 16 pt reorder handle.
- Full mode keeps the existing device selectors, categories, favorites, grouped ordering, output routing, refresh, controller, and quit actions.
- Popover content and preferred size refresh immediately when the selected style changes.

### Verified

- `swift build -Xswiftc -warnings-as-errors`
- Release app bundle build and strict ad-hoc signature verification.
- Settings UI inspection for the two style choices and persisted preference.

## [1.0.0] - 2026-08-13

### Added

- Native macOS menu bar controller and full audio console.
- Real Core Audio master-volume, mute, and device controls.
- Per-app volume, mute, boost, and output routing.
- Live audio-process discovery with favorites, categories, collapsing, and reordering.
- Light, dark, and system-following themes with Liquid Glass support.
- Custom background image, panel opacity, image opacity, and blur controls.
- Login launch, localized menu bar display styles, and permission management.
- Simplified Chinese, English, Japanese, French, German, and Korean interfaces.
- Drag-to-install DMG and ZIP distribution artifacts.

[Unreleased]: https://github.com/starry-sky-chan/audioflow-macos/compare/v1.2.1...HEAD
[1.2.1]: https://github.com/starry-sky-chan/audioflow-macos/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/starry-sky-chan/audioflow-macos/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/starry-sky-chan/audioflow-macos/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/starry-sky-chan/audioflow-macos/releases/tag/v1.0.0
