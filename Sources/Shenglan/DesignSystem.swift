import AppKit
import SwiftUI

enum ShenglanTypography {
    // One compact type scale for the controller. Keeping every textual role on
    // 16 / 14 / 12 points prevents SwiftUI semantic styles from silently
    // producing unrelated sizes across the mixer, device and settings pages.
    static let navigation = Font.system(size: 16, weight: .medium)
    static let navigationSelected = Font.system(size: 16, weight: .semibold)
    static let pageTitle = Font.system(size: 16, weight: .semibold)
    static let sectionTitle = Font.system(size: 16, weight: .semibold)
    static let control = Font.system(size: 14, weight: .medium)
    static let body = Font.system(size: 14, weight: .regular)
    static let bodyStrong = Font.system(size: 14, weight: .semibold)
    static let caption = Font.system(size: 12, weight: .regular)
    static let captionStrong = Font.system(size: 12, weight: .semibold)
}

enum ShenglanMotion {
    /// Immediate control feedback without the abrupt 75 ms snap used before.
    static let press = Animation.timingCurve(0.20, 0.82, 0.20, 1, duration: 0.12)
    /// Shared state transition for tabs, disclosure and compact controls.
    static let quick = Animation.timingCurve(0.20, 0.82, 0.20, 1, duration: 0.18)
    /// A non-bouncy settle for larger coordinated value changes such as presets.
    static let standard = Animation.timingCurve(0.16, 0.84, 0.24, 1, duration: 0.22)
    static let settle = Animation.spring(response: 0.25, dampingFraction: 0.92, blendDuration: 0.04)
}

/// A compact, literal EQ-off mark. The letters keep the feature recognizable
/// without relying on a generic power symbol, while the slash communicates
/// bypass/disable in the same visual language as mute controls.
struct EqualizerOffMark: View {
    var size: CGFloat = 18

    var body: some View {
        ZStack {
            Text("EQ")
                .font(.system(size: size * 0.54, weight: .bold, design: .rounded))
                .tracking(-0.35)

            Capsule(style: .continuous)
                .fill(Color.orange)
                .frame(width: size * 1.08, height: max(1.4, size * 0.09))
                .rotationEffect(.degrees(-43))
        }
        .frame(width: size * 1.15, height: size)
        .accessibilityHidden(true)
    }
}

private struct LiquidGlassEnabledKey: EnvironmentKey {
    static let defaultValue = true
}

private struct GlassPanelOpacityKey: EnvironmentKey {
    static let defaultValue = 0.78
}

extension EnvironmentValues {
    var liquidGlassEnabled: Bool {
        get { self[LiquidGlassEnabledKey.self] }
        set { self[LiquidGlassEnabledKey.self] = newValue }
    }

    var glassPanelOpacity: Double {
        get { self[GlassPanelOpacityKey.self] }
        set { self[GlassPanelOpacityKey.self] = min(max(newValue, 0.18), 1) }
    }
}

private enum ShenglanAsset {
    static let icon: NSImage? = {
        if let url = Bundle.main.url(forResource: "ShenglanIcon", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            return image
        }
        if let image = NSImage(named: NSImage.applicationIconName) {
            return image
        }
        if let url = Bundle.module.url(forResource: "ShenglanIcon", withExtension: "png") {
            return NSImage(contentsOf: url)
        }
        return nil
    }()
}

struct ShenglanIcon: View {
    var size: CGFloat = 38
    var body: some View {
        Group {
            if let image = ShenglanAsset.icon {
                Image(nsImage: image).resizable().interpolation(.high)
            } else {
                Image(systemName: "waveform.path.ecg").resizable().scaledToFit().padding(size * 0.2)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
        .shadow(color: .black.opacity(0.28), radius: 10, y: 5)
    }
}

/// One shared backdrop for the controller window and menu-bar popover. The
/// uploaded image stays below every glass surface, so native material samples
/// the same pixels in both presentation modes instead of behaving like a
/// decorative image pasted into one page.
struct ThemeBackdrop: View {
    @EnvironmentObject private var audio: AudioController
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ThemeBackdropContent(
            image: audio.customThemeBackgroundImage,
            imageIdentity: audio.customThemeBackgroundName,
            isEnabled: audio.customThemeBackgroundEnabled,
            opacity: audio.customThemeBackgroundOpacity,
            blur: audio.customThemeBackgroundBlur,
            isDark: colorScheme == .dark
        )
        .equatable()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Keep the expensive, full-window image and blur renderer independent from
/// `AudioController`'s high-frequency volume publications. Without this
/// boundary, every application-volume event asked SwiftUI to rebuild the
/// backdrop and made otherwise-native sliders feel sticky.
private struct ThemeBackdropContent: View, Equatable {
    let image: NSImage?
    let imageIdentity: String?
    let isEnabled: Bool
    let opacity: Double
    let blur: Double
    let isDark: Bool

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.image === rhs.image
            && lhs.imageIdentity == rhs.imageIdentity
            && lhs.isEnabled == rhs.isEnabled
            && abs(lhs.opacity - rhs.opacity) < 0.0001
            && abs(lhs.blur - rhs.blur) < 0.0001
            && lhs.isDark == rhs.isDark
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                baseColor
                    .allowsHitTesting(false)

                if isEnabled, let image {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .saturation(isDark ? 0.78 : 0.7)
                        .contrast(isDark ? 0.92 : 0.88)
                        .blur(radius: blur, opaque: true)
                        .opacity(opacity)
                        .clipped()
                        // This is a full-window visual layer. Keep the rule on
                        // the image itself (not only on its parent) because the
                        // blur renderer may bridge through a separate AppKit
                        // surface when an uploaded image is present.
                        .allowsHitTesting(false)

                    LinearGradient(
                        colors: overlayColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .allowsHitTesting(false)

                    Color(isDark ? .black : .white)
                        .opacity(backgroundVeilOpacity)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
            .allowsHitTesting(false)
        }
        .allowsHitTesting(false)
    }

    private var baseColor: Color {
        isDark ? Color(white: 0.045) : Color(white: 0.985)
    }

    private var overlayColors: [Color] {
        if isDark {
            return [Color.black.opacity(0.22), Color.clear, Color.black.opacity(0.38)]
        }
        return [Color.white.opacity(0.28), Color.clear, Color.white.opacity(0.48)]
    }

    private var backgroundVeilOpacity: Double {
        let base = isDark ? 0.20 : 0.28
        return min(base + (1 - opacity) * 0.32, 0.62)
    }
}

struct AppIconView: View {
    var image: NSImage?
    var fallback: String = "app.fill"
    var size: CGFloat = 32
    var body: some View {
        Group {
            if let image { Image(nsImage: image).resizable().interpolation(.high) }
            else { Image(systemName: fallback).resizable().scaledToFit().padding(size * 0.22).foregroundStyle(.primary) }
        }
        .frame(width: size, height: size)
        .background(Color.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: size * 0.25, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: size * 0.25, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: size * 0.25, style: .continuous).stroke(.white.opacity(0.18), lineWidth: 1))
        .shadow(color: .black.opacity(0.18), radius: 5, y: 2)
    }
}

struct GlassCardModifier: ViewModifier {
    @Environment(\.liquidGlassEnabled) private var liquidGlassEnabled
    @Environment(\.glassPanelOpacity) private var glassPanelOpacity
    @Environment(\.colorScheme) private var colorScheme
    var radius: CGFloat
    var tint: Color?
    var interactive: Bool

    func body(content: Content) -> some View {
        // Keep `content` outside the material branches.  Switching material
        // now swaps only a decorative background instead of replacing the
        // card (and, for the settings detail card, its entire ScrollView).
        content
            .background { materialBackground }
            .overlay { materialBorder }
            .shadow(color: materialShadowColor, radius: 5, y: 2)
        // Keep the view identity stable, but do not disable the transaction of
        // the complete subtree. Doing so also disabled press, selection and
        // row animations for every control placed inside a glass card.
    }

    @ViewBuilder
    private var materialBackground: some View {
        if !liquidGlassEnabled {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(solidSurfaceColor)
                .allowsHitTesting(false)
        } else if #available(macOS 26.0, *) {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Color.clear)
                .glassEffect(
                    .regular.tint(tint).interactive(interactive),
                    in: RoundedRectangle(cornerRadius: radius, style: .continuous)
                )
                .opacity(glassPanelOpacity)
                .allowsHitTesting(false)
        } else {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(.thinMaterial)
                .opacity(glassPanelOpacity)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var materialBorder: some View {
        if !liquidGlassEnabled {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(Color.primary.opacity(0.055 + glassPanelOpacity * 0.055), lineWidth: 1)
                .allowsHitTesting(false)
        } else if #available(macOS 26.0, *) {
            EmptyView()
        } else {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(Color.primary.opacity(0.04 + glassPanelOpacity * 0.06), lineWidth: 1)
                .allowsHitTesting(false)
        }
    }

    private var materialShadowColor: Color {
        guard liquidGlassEnabled else { return .clear }
        if #available(macOS 26.0, *) { return .clear }
        return .black.opacity(0.025 + glassPanelOpacity * 0.04)
    }

    private var solidSurfaceColor: Color {
        let opacity = 0.28 + glassPanelOpacity * 0.64
        return colorScheme == .dark
            ? Color.black.opacity(opacity)
            : Color.white.opacity(opacity)
    }
}

extension View {
    func liquidGlass(radius: CGFloat = 18, tint: Color? = nil, interactive: Bool = false) -> some View {
        modifier(GlassCardModifier(radius: radius, tint: tint, interactive: interactive))
    }

    func glassControl(radius: CGFloat = 11, tint: Color? = nil) -> some View {
        modifier(GlassControlModifier(radius: radius, tint: tint))
    }
}

private struct GlassControlModifier: ViewModifier {
    @Environment(\.glassPanelOpacity) private var glassPanelOpacity
    let radius: CGFloat
    let tint: Color?

    func body(content: Content) -> some View {
        content
            .background(
                Color.white.opacity(0.035 * glassPanelOpacity),
                in: RoundedRectangle(cornerRadius: radius, style: .continuous)
            )
            .liquidGlass(radius: radius, tint: tint, interactive: true)
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.12 + 0.26 * glassPanelOpacity),
                                .white.opacity(0.03 + 0.05 * glassPanelOpacity),
                                .black.opacity(0.03 + 0.05 * glassPanelOpacity)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
                    .allowsHitTesting(false)
            )
            .shadow(color: .black.opacity(0.02 + 0.035 * glassPanelOpacity), radius: 4, y: 2)
    }
}

struct GlassButtonStyle: ButtonStyle {
    var tint: Color? = nil
    var minHeight: CGFloat = 34
    var horizontalPadding: CGFloat = 12
    var radius: CGFloat = 11

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, horizontalPadding)
            .frame(minHeight: minHeight)
            .foregroundStyle(.primary)
            // Interactive native glass already owns the pointer-down response.
            // Rebuilding its tint and adding another scale animation on every
            // press caused a visibly delayed, double-settling click.
            .glassControl(radius: radius, tint: tint?.opacity(0.12))
            .brightness(configuration.isPressed ? -0.025 : 0)
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(ShenglanMotion.press, value: configuration.isPressed)
    }
}

struct GlassIconButtonStyle: ButtonStyle {
    var size: CGFloat = 34
    var radius: CGFloat = 10
    var tint: Color? = nil

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .glassControl(radius: radius, tint: tint?.opacity(0.1))
            .brightness(configuration.isPressed ? -0.03 : 0)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(ShenglanMotion.press, value: configuration.isPressed)
    }
}

struct GlassSegmentButtonStyle: ButtonStyle {
    let selected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .background(
                selected ? Color.primary.opacity(0.065) : Color.clear,
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .glassControl(
                radius: 10,
                tint: selected ? Color.primary.opacity(0.035) : Color.clear
            )
            .opacity(selected ? 1 : 0.82)
            .brightness(configuration.isPressed ? -0.025 : 0)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(ShenglanMotion.press, value: configuration.isPressed)
    }
}

/// Keeps pointer tracking on AppKit's native control so expensive SwiftUI glass
/// hierarchies are not rebuilt for every mouse event. Audio updates are sampled
/// at 30 Hz while dragging and the exact final value is always committed. The
/// native thumb still tracks every pointer event at the display refresh rate.
struct FluidSlider: NSViewRepresentable {
    @Environment(\.appLanguage) private var language

    let value: Double
    var range: ClosedRange<Double> = 0...1
    var step: Double? = nil
    var accessibilityName: String? = nil
    var onEditingChanged: (Bool) -> Void = { _ in }
    let onChange: (Double) -> Void

    init(
        value: Double,
        in range: ClosedRange<Double> = 0...1,
        step: Double? = nil,
        accessibilityName: String? = nil,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        onChange: @escaping (Double) -> Void
    ) {
        self.value = value
        self.range = range
        self.step = step
        self.accessibilityName = accessibilityName
        self.onEditingChanged = onEditingChanged
        self.onChange = onChange
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            range: range,
            step: step,
            onEditingChanged: onEditingChanged,
            onChange: onChange
        )
    }

    func makeNSView(context: Context) -> TrackingSlider {
        let slider = TrackingSlider()
        slider.minValue = range.lowerBound
        slider.maxValue = range.upperBound
        slider.doubleValue = clamped(value)
        slider.precisionStep = step
        slider.altIncrementValue = step ?? 0
        configureAccessibility(slider)
        slider.isContinuous = true
        slider.controlSize = .regular
        slider.focusRingType = .default
        slider.isEnabled = true
        slider.target = context.coordinator
        slider.action = #selector(Coordinator.valueChanged(_:))
        slider.onTrackingChanged = { [weak coordinator = context.coordinator] editing in
            coordinator?.trackingChanged(editing)
        }
        slider.onCommit = { [weak coordinator = context.coordinator] finalValue in
            coordinator?.commit(finalValue)
        }
        return slider
    }

    func updateNSView(_ slider: TrackingSlider, context: Context) {
        context.coordinator.onEditingChanged = onEditingChanged
        context.coordinator.onChange = onChange
        context.coordinator.range = range
        context.coordinator.step = step
        slider.minValue = range.lowerBound
        slider.maxValue = range.upperBound
        slider.precisionStep = step
        slider.altIncrementValue = step ?? 0
        if !context.coordinator.isTracking {
            let nextValue = clamped(value)
            if abs(slider.doubleValue - nextValue) > 0.0005 {
                slider.doubleValue = nextValue
            }
        }
        configureAccessibility(slider)
    }

    private func clamped(_ value: Double) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }

    private func configureAccessibility(_ slider: TrackingSlider) {
        slider.setAccessibilityLabel(accessibilityName)
        let usesPercentageScale = step == VolumeLevel.scalarStep
            && abs(range.lowerBound) < 0.000_001
            && abs(range.upperBound - 1) < 0.000_001
        slider.setAccessibilityValueDescription(
            usesPercentageScale
                ? L10n.tr("\(VolumeLevel.percentage(from: slider.doubleValue))%", language: language)
                : nil
        )
    }

    final class Coordinator: NSObject {
        var range: ClosedRange<Double>
        var step: Double?
        var onEditingChanged: (Bool) -> Void
        var onChange: (Double) -> Void
        private let limiter = VolumeEventLimiter(updatesPerSecond: 60)
        private(set) var isTracking = false

        init(
            range: ClosedRange<Double>,
            step: Double?,
            onEditingChanged: @escaping (Bool) -> Void,
            onChange: @escaping (Double) -> Void
        ) {
            self.range = range
            self.step = step
            self.onEditingChanged = onEditingChanged
            self.onChange = onChange
        }

        @objc func valueChanged(_ sender: NSSlider) {
            let value = normalized(sender.doubleValue)
            if abs(sender.doubleValue - value) > 0.000_001 {
                sender.doubleValue = value
            }
            if isTracking {
                limiter.emit(value, action: onChange)
            } else {
                // Keyboard and accessibility changes are discrete, so they do
                // not need drag throttling.
                limiter.commit(value, action: onChange)
            }
        }

        func trackingChanged(_ editing: Bool) {
            isTracking = editing
            onEditingChanged(editing)
        }

        func commit(_ value: Double) {
            limiter.commit(normalized(value), action: onChange)
        }

        private func normalized(_ value: Double) -> Double {
            let clamped = min(max(value, range.lowerBound), range.upperBound)
            guard let step, step > 0 else { return clamped }
            let offset = clamped - range.lowerBound
            let stepped = range.lowerBound + (offset / step).rounded() * step
            return min(max(stepped, range.lowerBound), range.upperBound)
        }
    }

    final class TrackingSlider: NSSlider {
        var onTrackingChanged: ((Bool) -> Void)?
        var onCommit: ((Double) -> Void)?
        var precisionStep: Double?
        private var isPointerTracking = false

        override var mouseDownCanMoveWindow: Bool { false }

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

        override func keyDown(with event: NSEvent) {
            guard let precisionStep, precisionStep > 0 else {
                super.keyDown(with: event)
                return
            }

            let direction: Double
            switch event.keyCode {
            case 123, 125: direction = -1 // left / down
            case 124, 126: direction = 1  // right / up
            default:
                super.keyDown(with: event)
                return
            }

            let multiplier = event.modifierFlags.contains(.shift) ? 5.0 : 1.0
            let nextValue = min(max(doubleValue + direction * precisionStep * multiplier, minValue), maxValue)
            doubleValue = nextValue
            sendAction(action, to: target)
        }

        override func mouseDown(with event: NSEvent) {
            guard isEnabled else { return }
            window?.makeFirstResponder(self)
            isPointerTracking = true
            onTrackingChanged?(true)

            // Let NSSlider own its native tracking session. Manually handling
            // mouseDown/Dragged/Up without calling super left the control out
            // of AppKit's tracking loop: clicks could be ignored and drags
            // could be delivered to a neighbouring representable. The action
            // is already throttled by Coordinator, so native tracking remains
            // smooth without rebuilding SwiftUI on every mouse event.
            super.mouseDown(with: event)
            finishPointerTracking()
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            // SwiftUI can rebuild the surrounding material while the pointer
            // is down. Never leave the shared interaction counter latched if
            // the native control is detached during that rebuild.
            if window == nil, isPointerTracking {
                finishPointerTracking()
            }
        }

        private func finishPointerTracking() {
            onCommit?(doubleValue)
            onTrackingChanged?(false)
            isPointerTracking = false
        }

    }
}

/// Replaces passive percentage text beside a volume slider with an editable
/// percentage field. It keeps the existing compact row width, while direct
/// 0...100 entry handles values that are difficult to land on with a short
/// pointer track.
struct VolumePercentageField: View {
    private static let digitAdvance: CGFloat = {
        let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        return ("0" as NSString).size(withAttributes: [.font: font]).width
    }()

    @Environment(\.appLanguage) private var language
    @FocusState private var percentageFieldFocused: Bool
    @State private var draftPercentage: String
    @State private var editingReported = false
    @State private var draftWasEdited = false

    let value: Double
    var labelWidth: CGFloat = 52
    var accessibilityName: String? = nil
    var onEditingChanged: (Bool) -> Void = { _ in }
    let onChange: (Double) -> Void

    init(
        value: Double,
        labelWidth: CGFloat = 52,
        accessibilityName: String? = nil,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        onChange: @escaping (Double) -> Void
    ) {
        self.value = value
        self.labelWidth = labelWidth
        self.accessibilityName = accessibilityName
        self.onEditingChanged = onEditingChanged
        self.onChange = onChange
        _draftPercentage = State(initialValue: String(VolumeLevel.percentage(from: value)))
    }

    private var percentage: Int {
        VolumeLevel.percentage(from: value)
    }

    private var editableDraft: Binding<String> {
        Binding(
            get: { draftPercentage },
            set: { newValue in
                let changed = newValue != draftPercentage
                draftPercentage = newValue
                guard percentageFieldFocused, changed else { return }
                beginUserEditing()
            }
        )
    }

    private var effectivePercentage: Int {
        guard draftWasEdited,
              let entered = Int(draftPercentage.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return percentage
        }
        return min(max(entered, VolumeLevel.percentageRange.lowerBound), VolumeLevel.percentageRange.upperBound)
    }

    /// Size the editable number to its visible 1...3 digits, then center the
    /// complete `number + %` group in the value area. A flexible, trailing
    /// TextField pins `%` to the right edge and makes 8%, 12%, and 100% appear
    /// to have different centers even though the outer control is unchanged.
    private var numberFieldWidth: CGFloat {
        let trimmed = draftPercentage.trimmingCharacters(in: .whitespacesAndNewlines)
        let visibleCharacterCount = min(max(trimmed.count, 1), 3)
        return ceil(Self.digitAdvance * CGFloat(visibleCharacterCount))
    }

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: language == .french || language == .german ? 1 : 0) {
                TextField("", text: editableDraft)
                    .textFieldStyle(.plain)
                    .font(ShenglanTypography.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(width: numberFieldWidth)
                    .focused($percentageFieldFocused)
                    .onSubmit {
                        // Return is an explicit commit even when the user retyped
                        // the same displayed integer over a fractional device value.
                        beginUserEditing()
                        // Ending focus funnels Return and click-away through the
                        // same single commit path below, avoiding duplicate Core
                        // Audio writes for the system master volume.
                        percentageFieldFocused = false
                    }
                    .onKeyPress(phases: .down) { press in
                        let characters = press.characters
                        if characters.contains(where: \Character.isNumber)
                            || characters == "\u{8}"
                            || characters == "\u{7f}" {
                            beginUserEditing()
                        }
                        return .ignored
                    }
                    .accessibilityLabel(accessibilityName ?? L10n.tr("音量", language: language))
                    .accessibilityValue(L10n.tr("\(draftPercentage)%", language: language))
                    .accessibilityHint(L10n.tr("输入精确音量百分比", language: language))

                Text(verbatim: "%")
                    .font(ShenglanTypography.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    percentageFieldFocused = true
                }
            )

            CompactVolumeStepperButtons(
                percentage: effectivePercentage,
                accessibilityName: accessibilityName ?? L10n.tr("音量", language: language),
                language: language,
                onAdjust: { applyPercentage(effectivePercentage + $0) }
            )
        }
        .padding(.leading, 1)
        .padding(.trailing, 1)
        .frame(width: labelWidth, height: 20)
        .background(
            Color.primary.opacity(percentageFieldFocused ? 0.055 : 0.035),
            in: RoundedRectangle(cornerRadius: 5, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(Color.accentColor.opacity(percentageFieldFocused ? 0.34 : 0), lineWidth: 1)
        }
        .help(L10n.tr("输入 0 到 100；选中滑杆后方向键每次调整 1%", language: language))
        .onChange(of: value) { _, newValue in
            // A newly opened NSPopover can focus this field automatically.
            // Keep following hardware/runtime changes until the user actually
            // types, rather than treating focus alone as an editing session.
            guard !draftWasEdited else { return }
            draftPercentage = String(VolumeLevel.percentage(from: newValue))
        }
        .onChange(of: percentageFieldFocused) { _, focused in
            if focused {
                draftWasEdited = false
            } else {
                let hadUserEdit = draftWasEdited
                commitDraftPercentage()
                if !hadUserEdit {
                    draftPercentage = String(percentage)
                }
                if editingReported {
                    editingReported = false
                    onEditingChanged(false)
                }
            }
        }
        .onDisappear {
            // A transient menu-bar popover can close while the field is still
            // first responder. Commit before balancing the interaction guard
            // so the typed value is neither lost nor allowed to freeze polling.
            commitDraftPercentage()
            if editingReported {
                editingReported = false
                onEditingChanged(false)
            }
        }
    }

    private func beginUserEditing() {
        draftWasEdited = true
        if !editingReported {
            editingReported = true
            onEditingChanged(true)
        }
    }

    private func applyPercentage(_ requestedPercentage: Int) {
        let clamped = min(
            max(requestedPercentage, VolumeLevel.percentageRange.lowerBound),
            VolumeLevel.percentageRange.upperBound
        )
        draftWasEdited = false
        draftPercentage = String(clamped)
        percentageFieldFocused = false
        if editingReported {
            editingReported = false
            onEditingChanged(false)
        }
        let targetValue = VolumeLevel.scalar(fromPercentage: clamped)
        guard abs(targetValue - VolumeLevel.clampedScalar(value)) > VolumeLevel.scalarComparisonTolerance else { return }
        onChange(targetValue)
    }

    private func commitDraftPercentage() {
        // NSPopover makes the first text field first responder when it opens.
        // Losing that automatic focus must not quantize a hardware value the
        // user never edited (for example 40.79% becoming 41%).
        guard draftWasEdited else { return }
        draftWasEdited = false
        let trimmed = draftPercentage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let entered = Int(trimmed) else {
            draftPercentage = String(percentage)
            return
        }
        let clamped = min(max(entered, VolumeLevel.percentageRange.lowerBound), VolumeLevel.percentageRange.upperBound)
        draftPercentage = String(clamped)
        let targetValue = VolumeLevel.scalar(fromPercentage: clamped)
        guard abs(targetValue - VolumeLevel.clampedScalar(value)) > VolumeLevel.scalarComparisonTolerance else { return }
        onChange(targetValue)
    }
}

private struct CompactVolumeStepperButtons: View {
    enum Direction: Hashable {
        case increment
        case decrement

        var delta: Int { self == .increment ? 1 : -1 }
        var symbol: String { self == .increment ? "chevron.up" : "chevron.down" }
        var localizationKey: String { self == .increment ? "增加 1%" : "减少 1%" }
    }

    @State private var hoveredDirection: Direction?

    let percentage: Int
    let accessibilityName: String
    let language: AppLanguage
    let onAdjust: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            stepButton(.increment)

            Rectangle()
                .fill(Color.primary.opacity(0.07))
                .frame(height: 0.5)

            stepButton(.decrement)
        }
        .frame(width: 14, height: 20)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(width: 0.5, height: 16)
        }
    }

    private func stepButton(_ direction: Direction) -> some View {
        let available = direction == .increment ? percentage < 100 : percentage > 0
        let actionLabel = L10n.tr(direction.localizationKey, language: language)

        return Button {
            onAdjust(direction.delta)
        } label: {
            Image(systemName: direction.symbol)
                .font(.system(size: 5.8, weight: .semibold))
                .frame(width: 14, height: 9.75)
                .contentShape(Rectangle())
        }
        .buttonStyle(CompactVolumeStepButtonStyle(isHovered: hoveredDirection == direction))
        .disabled(!available)
        .onHover { hovering in
            if hovering {
                hoveredDirection = direction
            } else if hoveredDirection == direction {
                hoveredDirection = nil
            }
        }
        .help(actionLabel)
        .accessibilityLabel("\(accessibilityName) \(actionLabel)")
        .accessibilityValue(L10n.tr("\(percentage)%", language: language))
    }
}

private struct CompactVolumeStepButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    let isHovered: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(
                isEnabled
                    ? (configuration.isPressed ? Color.accentColor : Color.secondary.opacity(isHovered ? 0.86 : 0.46))
                    : Color.secondary.opacity(0.2)
            )
            .background(
                configuration.isPressed
                    ? Color.accentColor.opacity(0.11)
                    : Color.primary.opacity(isHovered ? 0.055 : 0),
                in: RoundedRectangle(cornerRadius: 2, style: .continuous)
            )
            .animation(ShenglanMotion.press, value: configuration.isPressed)
            .animation(ShenglanMotion.quick, value: isHovered)
    }
}

/// Small reference-type limiter shared by the linear and circular controls.
/// It intentionally has no published state: pointer rendering stays local to
/// the control while audio I/O receives a stable stream of useful updates.
final class VolumeEventLimiter {
    private let minimumInterval: CFTimeInterval
    private var lastEmission = -Double.infinity

    init(updatesPerSecond: Double) {
        minimumInterval = 1 / max(updatesPerSecond, 1)
    }

    func emit(_ value: Double, action: (Double) -> Void) {
        let now = CACurrentMediaTime()
        guard now - lastEmission >= minimumInterval else { return }
        lastEmission = now
        action(value)
    }

    func commit(_ value: Double, action: (Double) -> Void) {
        lastEmission = CACurrentMediaTime()
        action(value)
    }
}
