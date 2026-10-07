import AppKit
import ApplicationServices
import Carbon
import ServiceManagement

private let defaultTimestampFormat = "yyyy-MM-dd-HHmm"

private enum FormatType: String, Equatable {
    case seconds
    case milliseconds
    case compactLocal
    case rfc3339Local
    case rfc3339LocalMilliseconds
    case iso8601
    case europeanShort
    case european
    case germanLong
    case us
    case usShort
    case british
    case rfc2822
    case unixReadable
    case custom
}

private struct FormatDefinition {
    let type: FormatType
    let label: String

    static let compactLocal = FormatDefinition(type: .compactLocal, label: "Compact local")
    static let unixTimestamp = FormatDefinition(type: .seconds, label: "Unix timestamp")
    static let milliseconds = FormatDefinition(type: .milliseconds, label: "Unix milliseconds")
    static let rfc3339Local = FormatDefinition(type: .rfc3339Local, label: "RFC 3339 local")
    static let rfc3339UTC = FormatDefinition(type: .iso8601, label: "RFC 3339 UTC (ISO 8601)")
    static let rfc3339LocalMilliseconds = FormatDefinition(type: .rfc3339LocalMilliseconds, label: "RFC 3339 local ms")
    static let emailDate = FormatDefinition(type: .rfc2822, label: "Email date (RFC 2822)")
    static let european = FormatDefinition(type: .european, label: "European")
    static let europeanShort = FormatDefinition(type: .europeanShort, label: "European date")
    static let germanLong = FormatDefinition(type: .germanLong, label: "German (long)")
    static let us = FormatDefinition(type: .us, label: "US")
    static let usShort = FormatDefinition(type: .usShort, label: "US date")
    static let british = FormatDefinition(type: .british, label: "UK")
    static let unixReadable = FormatDefinition(type: .unixReadable, label: "Unix readable")

    static let quickMenu: [FormatDefinition] = [
        compactLocal,
        british,
        us,
        unixTimestamp
    ]

    static let unix: [FormatDefinition] = [
        unixTimestamp,
        milliseconds
    ]

    static let interchange: [FormatDefinition] = [
        rfc3339Local,
        rfc3339UTC,
        rfc3339LocalMilliseconds,
        emailDate
    ]

    static let readable: [FormatDefinition] = [
        compactLocal,
        european,
        europeanShort,
        germanLong,
        us,
        usShort,
        british,
        unixReadable
    ]

    static let all: [FormatDefinition] = [
        compactLocal,
        rfc3339Local,
        rfc3339UTC,
        rfc3339LocalMilliseconds,
        emailDate,
        unixTimestamp,
        milliseconds,
        british,
        us,
        usShort,
        european,
        europeanShort,
        germanLong,
        unixReadable
    ]
}

private func fourCharacterCode(_ string: String) -> OSType {
    var result: OSType = 0
    for character in string.utf8.prefix(4) {
        result = (result << 8) + OSType(character)
    }
    return result
}

private struct HotKey: Equatable {
    let keyCode: UInt32
    let modifiers: UInt32

    static let defaultValue = HotKey(
        keyCode: UInt32(kVK_ANSI_T),
        modifiers: UInt32(controlKey | optionKey | cmdKey)
    )

    var displayString: String {
        var parts: [String] = []

        if modifiers & UInt32(controlKey) != 0 {
            parts.append("Control")
        }
        if modifiers & UInt32(optionKey) != 0 {
            parts.append("Option")
        }
        if modifiers & UInt32(shiftKey) != 0 {
            parts.append("Shift")
        }
        if modifiers & UInt32(cmdKey) != 0 {
            parts.append("Command")
        }

        parts.append(Self.keyName(for: keyCode))
        return parts.joined(separator: "-")
    }

    var glyphString: String {
        var glyphs = ""
        if modifiers & UInt32(controlKey) != 0 {
            glyphs += "⌃"
        }
        if modifiers & UInt32(optionKey) != 0 {
            glyphs += "⌥"
        }
        if modifiers & UInt32(shiftKey) != 0 {
            glyphs += "⇧"
        }
        if modifiers & UInt32(cmdKey) != 0 {
            glyphs += "⌘"
        }
        glyphs += Self.keyGlyph(for: keyCode)
        return glyphs
    }

    static func modifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0

        if flags.contains(.control) {
            result |= UInt32(controlKey)
        }
        if flags.contains(.option) {
            result |= UInt32(optionKey)
        }
        if flags.contains(.shift) {
            result |= UInt32(shiftKey)
        }
        if flags.contains(.command) {
            result |= UInt32(cmdKey)
        }

        return result
    }

    static func keyName(for keyCode: UInt32) -> String {
        switch Int(keyCode) {
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        case kVK_Space: return "Space"
        case kVK_Return: return "Return"
        case kVK_Tab: return "Tab"
        case kVK_Escape: return "Escape"
        case kVK_Delete: return "Delete"
        case kVK_ForwardDelete: return "Forward Delete"
        case kVK_LeftArrow: return "Left Arrow"
        case kVK_RightArrow: return "Right Arrow"
        case kVK_UpArrow: return "Up Arrow"
        case kVK_DownArrow: return "Down Arrow"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        case kVK_ANSI_Minus: return "-"
        case kVK_ANSI_Equal: return "="
        case kVK_ANSI_LeftBracket: return "["
        case kVK_ANSI_RightBracket: return "]"
        case kVK_ANSI_Backslash: return "\\"
        case kVK_ANSI_Semicolon: return ";"
        case kVK_ANSI_Quote: return "'"
        case kVK_ANSI_Comma: return ","
        case kVK_ANSI_Period: return "."
        case kVK_ANSI_Slash: return "/"
        case kVK_ANSI_Grave: return "`"
        default: return "Key \(keyCode)"
        }
    }

    static func keyGlyph(for keyCode: UInt32) -> String {
        switch Int(keyCode) {
        case kVK_Space: return "␣"
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Escape: return "⎋"
        case kVK_Delete: return "⌫"
        case kVK_ForwardDelete: return "⌦"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        default: return keyName(for: keyCode)
        }
    }
}

private enum SettingsStore {
    private static let formatTypeKey = "timestampFormatType"
    private static let formatKey = "timestampFormat"
    private static let useUTCTimeKey = "useUTCTime"
    private static let hotKeyCodeKey = "hotKeyCode"
    private static let hotKeyModifiersKey = "hotKeyModifiers"

    static var activeFormatType: FormatType {
        get {
            if let saved = UserDefaults.standard.string(forKey: formatTypeKey), let type = FormatType(rawValue: saved) {
                return type
            }
            // Migrate: If there's an existing format string that isn't the default, they probably want Custom.
            if let existingFormat = UserDefaults.standard.string(forKey: formatKey), existingFormat != defaultTimestampFormat {
                return .custom
            }
            return .compactLocal
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: formatTypeKey)
        }
    }

    static var customFormat: String {
        get {
            let saved = UserDefaults.standard.string(forKey: formatKey) ?? defaultTimestampFormat
            let trimmed = saved.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? defaultTimestampFormat : trimmed
        }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            UserDefaults.standard.set(trimmed.isEmpty ? defaultTimestampFormat : trimmed, forKey: formatKey)
        }
    }

    static var useUTCTime: Bool {
        get {
            UserDefaults.standard.bool(forKey: useUTCTimeKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: useUTCTimeKey)
        }
    }

    static var hotKey: HotKey {
        get {
            guard UserDefaults.standard.object(forKey: hotKeyCodeKey) != nil,
                  UserDefaults.standard.object(forKey: hotKeyModifiersKey) != nil else {
                return .defaultValue
            }

            let keyCode = UInt32(UserDefaults.standard.integer(forKey: hotKeyCodeKey))
            let modifiers = UInt32(UserDefaults.standard.integer(forKey: hotKeyModifiersKey))

            if modifiers == 0 {
                return .defaultValue
            }

            return HotKey(keyCode: keyCode, modifiers: modifiers)
        }
        set {
            UserDefaults.standard.set(Int(newValue.keyCode), forKey: hotKeyCodeKey)
            UserDefaults.standard.set(Int(newValue.modifiers), forKey: hotKeyModifiersKey)
        }
    }

    static func reset() {
        customFormat = defaultTimestampFormat
        activeFormatType = .compactLocal
        useUTCTime = false
        hotKey = .defaultValue
    }
}

private final class TimestampFormatter {
    private func formatter(format: String, locale: Locale = Locale(identifier: "en_US_POSIX"), useUTC: Bool) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        if useUTC {
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
        }
        formatter.dateFormat = format
        return formatter
    }

    func string(from date: Date = Date(), type: FormatType = SettingsStore.activeFormatType, useUTC: Bool = SettingsStore.useUTCTime, customFormat: String? = nil) -> String {
        switch type {
        case .seconds:
            return String(Int(date.timeIntervalSince1970))
        case .milliseconds:
            return String(Int(date.timeIntervalSince1970 * 1000))
        case .compactLocal:
            return formatter(format: defaultTimestampFormat, useUTC: useUTC).string(from: date)
        case .rfc3339Local:
            return formatter(format: "yyyy-MM-dd'T'HH:mm:ssXXX", useUTC: useUTC).string(from: date)
        case .rfc3339LocalMilliseconds:
            return formatter(format: "yyyy-MM-dd'T'HH:mm:ss.SSSXXX", useUTC: useUTC).string(from: date)
        case .iso8601:
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            return formatter.string(from: date)
        case .europeanShort:
            return formatter(format: "dd.MM.yyyy", useUTC: useUTC).string(from: date)
        case .european:
            return formatter(format: "dd.MM.yyyy HH:mm:ss", useUTC: useUTC).string(from: date)
        case .germanLong:
            return formatter(format: "d. MMMM yyyy, HH:mm 'Uhr'", locale: Locale(identifier: "de_DE"), useUTC: useUTC).string(from: date)
        case .us:
            return formatter(format: "MM/dd/yyyy hh:mm:ss a", locale: Locale(identifier: "en_US"), useUTC: useUTC).string(from: date)
        case .usShort:
            return formatter(format: "M/d/yyyy", locale: Locale(identifier: "en_US"), useUTC: useUTC).string(from: date)
        case .british:
            return formatter(format: "dd/MM/yyyy HH:mm:ss", locale: Locale(identifier: "en_GB"), useUTC: useUTC).string(from: date)
        case .rfc2822:
            return formatter(format: "EEE, dd MMM yyyy HH:mm:ss Z", useUTC: useUTC).string(from: date)
        case .unixReadable:
            return formatter(format: "EEE MMM dd HH:mm:ss zzz yyyy", useUTC: useUTC).string(from: date)
        case .custom:
            return formatter(format: customFormat ?? SettingsStore.customFormat, useUTC: useUTC).string(from: date)
        }
    }
}

private final class TimestampInserter {
    private let formatter = TimestampFormatter()

    func insertTimestamp() {
        guard AccessibilityPermission.isTrusted(prompt: true) else {
            NSSound.beep()
            return
        }

        let timestamp = formatter.string()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.typeText(timestamp)
        }
    }

    private func typeText(_ text: String) {
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            NSSound.beep()
            return
        }

        for scalar in text.utf16 {
            var character = scalar

            guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else {
                NSSound.beep()
                return
            }

            keyDown.flags = []
            keyUp.flags = []
            keyDown.keyboardSetUnicodeString(stringLength: 1, unicodeString: &character)
            keyUp.keyboardSetUnicodeString(stringLength: 1, unicodeString: &character)
            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
        }
    }
}

private enum AccessibilityPermission {
    static func isTrusted(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func openSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

private final class HotKeyController {
    private let callback: () -> Void
    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?

    init(callback: @escaping () -> Void) {
        self.callback = callback
        installEventHandler()
    }

    @discardableResult
    func register(_ hotKey: HotKey) -> Bool {
        unregisterHotKey()

        let hotKeyID = EventHotKeyID(signature: fourCharacterCode("TmSt"), id: 1)
        let status = RegisterEventHotKey(
            hotKey.keyCode,
            hotKey.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            NSAlert.show(
                message: "Could not register hotkey",
                details: "\(hotKey.displayString) may already be used by another app."
            )
            return false
        }

        return true
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else {
                    return noErr
                }

                let controller = Unmanaged<HotKeyController>.fromOpaque(userData).takeUnretainedValue()
                controller.callback()
                return noErr
            },
            1,
            &eventType,
            userData,
            &eventHandler
        )
    }

    private func unregisterHotKey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    deinit {
        unregisterHotKey()

        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
}

private final class HotKeyRecorderView: NSView {
    var hotKey: HotKey {
        didSet {
            needsDisplay = true
            onChange?(hotKey)
        }
    }

    var onChange: ((HotKey) -> Void)?
    private var isRecording = false

    init(hotKey: HotKey) {
        self.hotKey = hotKey
        super.init(frame: .zero)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        self.hotKey = .defaultValue
        super.init(coder: coder)
        wantsLayer = true
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        isRecording = true
        window?.makeFirstResponder(self)
        needsDisplay = true
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        needsDisplay = true
        return true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == UInt16(kVK_Escape) {
            isRecording = false
            window?.makeFirstResponder(nil)
            needsDisplay = true
            return
        }

        let modifiers = HotKey.modifiers(from: event.modifierFlags)
        guard modifiers != 0 else {
            NSSound.beep()
            return
        }

        hotKey = HotKey(keyCode: UInt32(event.keyCode), modifiers: modifiers)
        isRecording = false
        window?.makeFirstResponder(nil)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let bounds = self.bounds.insetBy(dx: 1, dy: 1)
        let path = NSBezierPath(roundedRect: bounds, xRadius: 8, yRadius: 8)
        let isFocused = isRecording || window?.firstResponder === self

        (isFocused ? NSColor.controlAccentColor.withAlphaComponent(0.12) : NSColor.controlBackgroundColor).setFill()
        path.fill()

        (isFocused ? NSColor.controlAccentColor : NSColor.separatorColor).setStroke()
        path.lineWidth = isFocused ? 2 : 1
        path.stroke()

        let text = isRecording ? "Press keys…" : hotKey.glyphString
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: isRecording ? NSColor.secondaryLabelColor : NSColor.labelColor,
            .paragraphStyle: paragraph
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let textRect = NSRect(x: 8, y: (bounds.height - attributed.size().height) / 2, width: bounds.width - 16, height: attributed.size().height)
        attributed.draw(in: textRect)
    }
}

private final class AppIconSquircleView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let squirclePath = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 13, yRadius: 13)

        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let bgColor = isDark
            ? NSColor(white: 0.22, alpha: 1.0)
            : NSColor(white: 0.94, alpha: 1.0)
        let borderColor = isDark
            ? NSColor(white: 0.38, alpha: 0.6)
            : NSColor(white: 0.8, alpha: 0.8)

        bgColor.setFill()
        squirclePath.fill()

        borderColor.setStroke()
        squirclePath.lineWidth = 1
        squirclePath.stroke()

        let iconRect = bounds.insetBy(dx: 11, dy: 11)
        if let icon = Bundle.main.image(forResource: "MenuBarIcon") ?? NSImage(named: "MenuBarIcon") {
            let tinted = icon.copy() as! NSImage
            tinted.isTemplate = true
            tinted.draw(in: iconRect)
        } else if let icon = NSImage(named: "AppIcon") {
            icon.draw(in: iconRect)
        }
    }
}

private final class PreferencesWindowController: NSWindowController, NSTextFieldDelegate {
    private let presetPopup = NSPopUpButton()
    private let useUTCButton = NSButton(checkboxWithTitle: "Use UTC timezone", target: nil, action: nil)
    private let formatField = NSTextField()
    private let livePreviewText = NSTextField(labelWithString: "")
    private let hotKeyRecorder = HotKeyRecorderView(hotKey: SettingsStore.hotKey)
    private var launchAtLoginButton: NSButton?
    private let accessibilityStatusDot = NSView()
    private let accessibilityStatusLabel = NSTextField(labelWithString: "")
    private let accessibilityButton = NSButton(title: "System Settings…", target: nil, action: nil)
    private let onChange: () -> Void

    init(onChange: @escaping () -> Void) {
        self.onChange = onChange

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 530),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Timestamp Inserter Settings"
        window.center()

        super.init(window: window)
        buildUI()
        loadSettings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        loadSettings()
        updateAccessibilityStatus()
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func createCardBox() -> NSBox {
        let box = NSBox()
        box.boxType = .custom
        box.cornerRadius = 10
        box.borderWidth = 1
        box.borderColor = NSColor.separatorColor.withAlphaComponent(0.6)
        box.fillColor = NSColor.controlBackgroundColor.withAlphaComponent(0.4)
        box.translatesAutoresizingMaskIntoConstraints = false
        return box
    }

    private func buildUI() {
        guard let contentView = window?.contentView else { return }

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 14
        root.translatesAutoresizingMaskIntoConstraints = false
        root.edgeInsets = NSEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)
        contentView.addSubview(root)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            root.topAnchor.constraint(equalTo: contentView.topAnchor),
            root.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        // 1. Header with Dark-Mode Compatible Squircle Tile
        let headerStack = NSStackView()
        headerStack.orientation = .horizontal
        headerStack.alignment = .centerY
        headerStack.spacing = 14
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        let squircleIcon = AppIconSquircleView()
        squircleIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            squircleIcon.widthAnchor.constraint(equalToConstant: 48),
            squircleIcon.heightAnchor.constraint(equalToConstant: 48)
        ])

        let titleStack = NSStackView()
        titleStack.orientation = .vertical
        titleStack.alignment = .leading
        titleStack.spacing = 2

        let titleRow = NSStackView()
        titleRow.orientation = .horizontal
        titleRow.alignment = .centerY
        titleRow.spacing = 6

        let appTitleLabel = NSTextField(labelWithString: "Timestamp Inserter")
        appTitleLabel.font = .systemFont(ofSize: 16, weight: .bold)

        let versionLabel = NSTextField(labelWithString: "v1.0")
        versionLabel.font = .monospacedSystemFont(ofSize: 10, weight: .medium)
        versionLabel.textColor = .secondaryLabelColor

        titleRow.addArrangedSubview(appTitleLabel)
        titleRow.addArrangedSubview(versionLabel)

        let descriptionLabel = NSTextField(labelWithString: "Inserts formatted timestamps directly into any focused text field.")
        descriptionLabel.font = .systemFont(ofSize: 11)
        descriptionLabel.textColor = .secondaryLabelColor

        titleStack.addArrangedSubview(titleRow)
        titleStack.addArrangedSubview(descriptionLabel)

        headerStack.addArrangedSubview(squircleIcon)
        headerStack.addArrangedSubview(titleStack)
        root.addArrangedSubview(headerStack)

        // 2. Card 1: Active Format & Live Preview
        let formatCard = createCardBox()
        let formatCardStack = NSStackView()
        formatCardStack.orientation = .vertical
        formatCardStack.alignment = .leading
        formatCardStack.spacing = 10
        formatCardStack.translatesAutoresizingMaskIntoConstraints = false
        formatCardStack.edgeInsets = NSEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
        formatCard.contentView = formatCardStack

        let formatHeaderLabel = NSTextField(labelWithString: "ACTIVE FORMAT")
        formatHeaderLabel.font = .systemFont(ofSize: 10, weight: .bold)
        formatHeaderLabel.textColor = .secondaryLabelColor

        let presetLabel = NSTextField(labelWithString: "Preset")
        presetLabel.font = .systemFont(ofSize: 12, weight: .medium)

        presetPopup.translatesAutoresizingMaskIntoConstraints = false
        presetPopup.target = self
        presetPopup.action = #selector(presetChanged)
        configurePresetPopup()

        useUTCButton.target = self
        useUTCButton.action = #selector(useUTCChanged)
        useUTCButton.font = .systemFont(ofSize: 12)

        let customFormatLabel = NSTextField(labelWithString: "Custom Pattern")
        customFormatLabel.font = .systemFont(ofSize: 12, weight: .medium)

        formatField.delegate = self
        formatField.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        formatField.placeholderString = defaultTimestampFormat
        formatField.translatesAutoresizingMaskIntoConstraints = false
        formatField.target = self
        formatField.action = #selector(formatFieldChanged)

        let formatHelpLabel = NSTextField(labelWithString: "Tokens: yyyy (year), MM (month), dd (day), HHmm (24h time), SSS (ms)")
        formatHelpLabel.font = .systemFont(ofSize: 10)
        formatHelpLabel.textColor = .secondaryLabelColor

        // Live Output Preview Callout
        let previewCallout = NSBox()
        previewCallout.boxType = .custom
        previewCallout.cornerRadius = 6
        previewCallout.borderWidth = 1
        previewCallout.borderColor = NSColor.separatorColor.withAlphaComponent(0.4)
        previewCallout.fillColor = NSColor.windowBackgroundColor.withAlphaComponent(0.6)
        previewCallout.translatesAutoresizingMaskIntoConstraints = false

        let previewStack = NSStackView()
        previewStack.orientation = .horizontal
        previewStack.alignment = .centerY
        previewStack.distribution = .fill
        previewStack.translatesAutoresizingMaskIntoConstraints = false
        previewStack.edgeInsets = NSEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        previewCallout.contentView = previewStack

        let previewTextStack = NSStackView()
        previewTextStack.orientation = .vertical
        previewTextStack.alignment = .leading
        previewTextStack.spacing = 2

        let previewTitle = NSTextField(labelWithString: "LIVE OUTPUT PREVIEW")
        previewTitle.font = .systemFont(ofSize: 9, weight: .bold)
        previewTitle.textColor = .secondaryLabelColor

        livePreviewText.font = .monospacedSystemFont(ofSize: 13, weight: .semibold)
        livePreviewText.textColor = .controlAccentColor

        previewTextStack.addArrangedSubview(previewTitle)
        previewTextStack.addArrangedSubview(livePreviewText)

        let badgeLabel = NSTextField(labelWithString: "Types this text")
        badgeLabel.font = .systemFont(ofSize: 10)
        badgeLabel.textColor = .tertiaryLabelColor

        previewStack.addArrangedSubview(previewTextStack)
        previewStack.addArrangedSubview(badgeLabel)

        formatCardStack.addArrangedSubview(formatHeaderLabel)
        formatCardStack.addArrangedSubview(presetLabel)
        formatCardStack.addArrangedSubview(presetPopup)
        formatCardStack.addArrangedSubview(useUTCButton)
        formatCardStack.addArrangedSubview(customFormatLabel)
        formatCardStack.addArrangedSubview(formatField)
        formatCardStack.addArrangedSubview(formatHelpLabel)
        formatCardStack.addArrangedSubview(previewCallout)

        root.addArrangedSubview(formatCard)

        // 3. Card 2: Shortcut & Launch
        let shortcutCard = createCardBox()
        let shortcutCardStack = NSStackView()
        shortcutCardStack.orientation = .vertical
        shortcutCardStack.alignment = .leading
        shortcutCardStack.spacing = 10
        shortcutCardStack.translatesAutoresizingMaskIntoConstraints = false
        shortcutCardStack.edgeInsets = NSEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
        shortcutCard.contentView = shortcutCardStack

        let shortcutHeaderLabel = NSTextField(labelWithString: "SHORTCUT & LAUNCH")
        shortcutHeaderLabel.font = .systemFont(ofSize: 10, weight: .bold)
        shortcutHeaderLabel.textColor = .secondaryLabelColor

        let shortcutRow = NSStackView()
        shortcutRow.orientation = .horizontal
        shortcutRow.alignment = .centerY
        shortcutRow.spacing = 10
        shortcutRow.translatesAutoresizingMaskIntoConstraints = false

        let shortcutTextStack = NSStackView()
        shortcutTextStack.orientation = .vertical
        shortcutTextStack.alignment = .leading
        shortcutTextStack.spacing = 2

        let shortcutTitle = NSTextField(labelWithString: "Global Shortcut")
        shortcutTitle.font = .systemFont(ofSize: 12, weight: .medium)
        let shortcutDesc = NSTextField(labelWithString: "Works globally in any application.")
        shortcutDesc.font = .systemFont(ofSize: 10)
        shortcutDesc.textColor = .secondaryLabelColor

        shortcutTextStack.addArrangedSubview(shortcutTitle)
        shortcutTextStack.addArrangedSubview(shortcutDesc)

        hotKeyRecorder.translatesAutoresizingMaskIntoConstraints = false
        hotKeyRecorder.onChange = { [weak self] _ in
            self?.hotKeyChanged()
        }

        shortcutRow.addArrangedSubview(shortcutTextStack)
        shortcutRow.addArrangedSubview(hotKeyRecorder)

        shortcutCardStack.addArrangedSubview(shortcutHeaderLabel)
        shortcutCardStack.addArrangedSubview(shortcutRow)

        if #available(macOS 13.0, *) {
            let launchButton = NSButton(checkboxWithTitle: "Launch at login", target: self, action: #selector(toggleLaunchAtLogin))
            launchButton.state = SMAppService.mainApp.status == .enabled ? .on : .off
            launchButton.font = .systemFont(ofSize: 12)
            self.launchAtLoginButton = launchButton
            shortcutCardStack.addArrangedSubview(launchButton)
        }

        root.addArrangedSubview(shortcutCard)

        // 4. Card 3: Permissions
        let permCard = createCardBox()
        let permCardStack = NSStackView()
        permCardStack.orientation = .horizontal
        permCardStack.alignment = .centerY
        permCardStack.distribution = .fill
        permCardStack.translatesAutoresizingMaskIntoConstraints = false
        permCardStack.edgeInsets = NSEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        permCard.contentView = permCardStack

        let permLeftStack = NSStackView()
        permLeftStack.orientation = .horizontal
        permLeftStack.alignment = .centerY
        permLeftStack.spacing = 8

        accessibilityStatusDot.wantsLayer = true
        accessibilityStatusDot.layer?.cornerRadius = 4
        accessibilityStatusDot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            accessibilityStatusDot.widthAnchor.constraint(equalToConstant: 8),
            accessibilityStatusDot.heightAnchor.constraint(equalToConstant: 8)
        ])

        accessibilityStatusLabel.font = .systemFont(ofSize: 11, weight: .medium)
        permLeftStack.addArrangedSubview(accessibilityStatusDot)
        permLeftStack.addArrangedSubview(accessibilityStatusLabel)

        accessibilityButton.bezelStyle = .inline
        accessibilityButton.font = .systemFont(ofSize: 11)
        accessibilityButton.target = self
        accessibilityButton.action = #selector(openSystemSettings)

        permCardStack.addArrangedSubview(permLeftStack)
        permCardStack.addArrangedSubview(accessibilityButton)

        root.addArrangedSubview(permCard)

        // 5. Footer (Auto-save notice + Reset)
        let footerRow = NSStackView()
        footerRow.orientation = .horizontal
        footerRow.alignment = .centerY
        footerRow.distribution = .fill
        footerRow.translatesAutoresizingMaskIntoConstraints = false

        let autoSaveLabel = NSTextField(labelWithString: "Changes are applied automatically.")
        autoSaveLabel.font = .systemFont(ofSize: 11)
        autoSaveLabel.textColor = .tertiaryLabelColor

        let resetButton = NSButton(title: "Reset to Defaults", target: self, action: #selector(resetSettings))
        resetButton.bezelStyle = .rounded
        resetButton.font = .systemFont(ofSize: 11)

        footerRow.addArrangedSubview(autoSaveLabel)
        footerRow.addArrangedSubview(resetButton)

        root.addArrangedSubview(footerRow)

        // Constraints
        NSLayoutConstraint.activate([
            headerStack.widthAnchor.constraint(equalTo: root.widthAnchor),
            formatCard.widthAnchor.constraint(equalTo: root.widthAnchor),
            formatCardStack.widthAnchor.constraint(equalTo: formatCard.widthAnchor),
            presetPopup.widthAnchor.constraint(equalTo: formatCardStack.widthAnchor, constant: -28),
            formatField.widthAnchor.constraint(equalTo: formatCardStack.widthAnchor, constant: -28),
            previewCallout.widthAnchor.constraint(equalTo: formatCardStack.widthAnchor, constant: -28),
            previewStack.widthAnchor.constraint(equalTo: previewCallout.widthAnchor),
            shortcutCard.widthAnchor.constraint(equalTo: root.widthAnchor),
            shortcutCardStack.widthAnchor.constraint(equalTo: shortcutCard.widthAnchor),
            shortcutRow.widthAnchor.constraint(equalTo: shortcutCardStack.widthAnchor, constant: -28),
            hotKeyRecorder.widthAnchor.constraint(equalToConstant: 130),
            hotKeyRecorder.heightAnchor.constraint(equalToConstant: 30),
            permCard.widthAnchor.constraint(equalTo: root.widthAnchor),
            permCardStack.widthAnchor.constraint(equalTo: permCard.widthAnchor),
            footerRow.widthAnchor.constraint(equalTo: root.widthAnchor)
        ])
    }

    private func configurePresetPopup() {
        presetPopup.removeAllItems()
        for def in FormatDefinition.all {
            presetPopup.addItem(withTitle: def.label)
            presetPopup.lastItem?.representedObject = def.type.rawValue
        }
        presetPopup.menu?.addItem(.separator())
        presetPopup.addItem(withTitle: "Custom Format…")
        presetPopup.lastItem?.representedObject = FormatType.custom.rawValue
    }

    @available(macOS 13.0, *)
    @objc private func toggleLaunchAtLogin(_ sender: NSButton) {
        do {
            if sender.state == .on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to toggle launch at login: \(error)")
            sender.state = sender.state == .on ? .off : .on
        }
    }

    private func loadSettings() {
        selectPreset(SettingsStore.activeFormatType)
        useUTCButton.state = SettingsStore.useUTCTime ? .on : .off
        formatField.stringValue = SettingsStore.customFormat
        hotKeyRecorder.hotKey = SettingsStore.hotKey
        updateFormatFieldState()
        updateSample()
    }

    private func updateFormatFieldState() {
        let isCustom = selectedPreset() == .custom
        formatField.isEnabled = isCustom
    }

    private func updateSample() {
        let type = selectedPreset()
        let useUTC = useUTCButton.state == .on

        if type == .custom {
            livePreviewText.stringValue = TimestampFormatter().string(type: .custom, useUTC: useUTC, customFormat: cleanedFormat())
            return
        }

        livePreviewText.stringValue = TimestampFormatter().string(type: type, useUTC: useUTC)
    }

    private func updateAccessibilityStatus() {
        let isTrusted = AccessibilityPermission.isTrusted(prompt: false)
        accessibilityStatusDot.layer?.backgroundColor = isTrusted
            ? NSColor.systemGreen.cgColor
            : NSColor.systemOrange.cgColor
        accessibilityStatusLabel.stringValue = isTrusted
            ? "Accessibility Permission: Granted"
            : "Accessibility Permission: Required"
        accessibilityButton.title = isTrusted ? "System Settings…" : "Grant Access…"
    }

    @objc private func openSystemSettings() {
        AccessibilityPermission.openSettings()
    }

    private func cleanedFormat() -> String {
        let trimmed = formatField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultTimestampFormat : trimmed
    }

    private func selectedPreset() -> FormatType {
        guard let rawValue = presetPopup.selectedItem?.representedObject as? String,
              let type = FormatType(rawValue: rawValue) else {
            return .compactLocal
        }
        return type
    }

    private func selectPreset(_ type: FormatType) {
        if let item = presetPopup.itemArray.first(where: { $0.representedObject as? String == type.rawValue }) {
            presetPopup.select(item)
        }
    }

    func controlTextDidChange(_ notification: Notification) {
        selectPreset(.custom)
        SettingsStore.activeFormatType = .custom
        SettingsStore.customFormat = cleanedFormat()
        updateFormatFieldState()
        updateSample()
        onChange()
    }

    @objc private func formatFieldChanged() {
        SettingsStore.customFormat = cleanedFormat()
        updateSample()
        onChange()
    }

    @objc private func presetChanged() {
        let type = selectedPreset()
        SettingsStore.activeFormatType = type
        updateFormatFieldState()
        updateSample()
        onChange()
    }

    @objc private func useUTCChanged() {
        SettingsStore.useUTCTime = useUTCButton.state == .on
        updateSample()
        onChange()
    }

    private func hotKeyChanged() {
        SettingsStore.hotKey = hotKeyRecorder.hotKey
        onChange()
    }

    @objc private func resetSettings() {
        SettingsStore.reset()
        loadSettings()
        onChange()
    }
}

private extension NSAlert {
    static func show(message: String, details: String) {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.messageText = message
            alert.informativeText = details
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let inserter = TimestampInserter()
    private var hotKeyController: HotKeyController?
    private var preferencesWindowController: PreferencesWindowController?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !terminateIfAnotherInstanceIsRunning() else {
            return
        }

        NSApp.setActivationPolicy(.accessory)
        installMenuBarItem()
        installHotKey()
        _ = AccessibilityPermission.isTrusted(prompt: true)
    }

    private func terminateIfAnotherInstanceIsRunning() -> Bool {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            return false
        }

        let currentProcessIdentifier = ProcessInfo.processInfo.processIdentifier
        let otherInstances = NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleIdentifier)
            .filter { $0.processIdentifier != currentProcessIdentifier && !$0.isTerminated }

        if otherInstances.isEmpty {
            return false
        }

        NSApp.terminate(nil)
        return true
    }

    private func createMenuBarIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        if let image = Bundle.main.image(forResource: "MenuBarIcon") ?? NSImage(named: "MenuBarIcon") {
            image.size = size
            image.isTemplate = true
            return image
        }
        if let url1 = Bundle.main.url(forResource: "MenuBarIcon", withExtension: "png"),
           let rep1 = NSImageRep(contentsOf: url1) {
            let img = NSImage(size: size)
            img.addRepresentation(rep1)
            if let url2 = Bundle.main.url(forResource: "MenuBarIcon@2x", withExtension: "png"),
               let rep2 = NSImageRep(contentsOf: url2) {
                img.addRepresentation(rep2)
            }
            img.isTemplate = true
            return img
        }
        if let appIcon = NSImage(named: "AppIcon") {
            let image = NSImage(size: size)
            image.lockFocus()
            appIcon.draw(in: NSRect(origin: .zero, size: size))
            image.unlockFocus()
            image.isTemplate = true
            return image
        }
        let fallback = NSImage(systemSymbolName: "clock", accessibilityDescription: "Timestamp Inserter") ?? NSImage()
        fallback.isTemplate = true
        return fallback
    }

    private func installMenuBarItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let icon = createMenuBarIcon()
        item.button?.image = icon
        item.button?.imagePosition = .imageOnly
        item.button?.toolTip = "Timestamp Inserter"

        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        statusItem = item
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        // 1. Top action item: Insert Timestamp now
        let insertItem = NSMenuItem(
            title: "Insert Timestamp",
            action: #selector(insertTimestampNow),
            keyEquivalent: ""
        )
        insertItem.target = self
        insertItem.attributedTitle = createActionAttributedTitle(
            action: "Insert Timestamp",
            shortcut: SettingsStore.hotKey.glyphString
        )
        menu.addItem(insertItem)

        menu.addItem(.separator())

        // 2. Section: Quick Formats
        let formatHeader = NSMenuItem(title: "QUICK FORMATS", action: nil, keyEquivalent: "")
        formatHeader.isEnabled = false
        menu.addItem(formatHeader)

        let formatter = TimestampFormatter()
        for def in FormatDefinition.quickMenu {
            let item = NSMenuItem(
                title: def.label,
                action: #selector(selectFormat(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = def.type.rawValue
            item.state = (SettingsStore.activeFormatType == def.type) ? .on : .off
            let sample = formatter.string(type: def.type)
            item.toolTip = sample
            if #available(macOS 14.0, *) {
                item.subtitle = sample
            } else {
                item.attributedTitle = createMenuItemAttributedTitle(title: def.label, sample: sample)
            }
            menu.addItem(item)
        }

        // 3. Submenu: More Formats
        let moreMenu = NSMenu()

        // Standards & RFC
        let stdHeader = NSMenuItem(title: "STANDARDS & RFC", action: nil, keyEquivalent: "")
        stdHeader.isEnabled = false
        moreMenu.addItem(stdHeader)
        for def in FormatDefinition.interchange {
            moreMenu.addItem(createSubmenuItem(def: def, formatter: formatter))
        }

        moreMenu.addItem(.separator())

        // Human Readable
        let humanHeader = NSMenuItem(title: "HUMAN READABLE", action: nil, keyEquivalent: "")
        humanHeader.isEnabled = false
        moreMenu.addItem(humanHeader)
        for def in [FormatDefinition.european, FormatDefinition.europeanShort, FormatDefinition.germanLong, FormatDefinition.british, FormatDefinition.us, FormatDefinition.usShort, FormatDefinition.unixReadable] {
            moreMenu.addItem(createSubmenuItem(def: def, formatter: formatter))
        }

        moreMenu.addItem(.separator())

        // Unix Epoch
        let unixHeader = NSMenuItem(title: "UNIX EPOCH", action: nil, keyEquivalent: "")
        unixHeader.isEnabled = false
        moreMenu.addItem(unixHeader)
        for def in FormatDefinition.unix {
            moreMenu.addItem(createSubmenuItem(def: def, formatter: formatter))
        }

        moreMenu.addItem(.separator())

        // Custom Format
        let customItem = NSMenuItem(
            title: "Custom Format (\(SettingsStore.customFormat))",
            action: #selector(selectCustomFormat),
            keyEquivalent: ""
        )
        customItem.target = self
        customItem.state = (SettingsStore.activeFormatType == .custom) ? .on : .off
        customItem.toolTip = formatter.string(type: .custom)
        moreMenu.addItem(customItem)

        let moreItem = NSMenuItem(title: "More Formats", action: nil, keyEquivalent: "")
        moreItem.submenu = moreMenu
        menu.addItem(moreItem)

        menu.addItem(.separator())

        // 4. Use UTC time toggle
        let utcItem = NSMenuItem(
            title: "Use UTC time",
            action: #selector(toggleUseUTCTime),
            keyEquivalent: ""
        )
        utcItem.target = self
        utcItem.state = SettingsStore.useUTCTime ? .on : .off
        menu.addItem(utcItem)

        menu.addItem(.separator())

        // 5. Accessibility warning (only if NOT granted)
        if !AccessibilityPermission.isTrusted(prompt: false) {
            let warnItem = NSMenuItem(
                title: "⚠️ Grant Accessibility Permission…",
                action: #selector(openAccessibilitySettings),
                keyEquivalent: ""
            )
            warnItem.target = self
            menu.addItem(warnItem)
            menu.addItem(.separator())
        }

        // 6. Settings & standard items
        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        let aboutItem = NSMenuItem(
            title: "About Timestamp Inserter",
            action: #selector(openAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func createActionAttributedTitle(action: String, shortcut: String) -> NSAttributedString {
        let attr = NSMutableAttributedString()
        attr.append(NSAttributedString(
            string: action,
            attributes: [
                .font: NSFont.systemFont(ofSize: 13, weight: .medium),
                .foregroundColor: NSColor.labelColor
            ]
        ))
        attr.append(NSAttributedString(
            string: "    \(shortcut)",
            attributes: [
                .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        ))
        return attr
    }

    private func createMenuItemAttributedTitle(title: String, sample: String) -> NSAttributedString {
        let attr = NSMutableAttributedString()
        attr.append(NSAttributedString(
            string: title,
            attributes: [
                .font: NSFont.systemFont(ofSize: 13, weight: .regular),
                .foregroundColor: NSColor.labelColor
            ]
        ))
        attr.append(NSAttributedString(
            string: "  —  \(sample)",
            attributes: [
                .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        ))
        return attr
    }

    private func createSubmenuItem(def: FormatDefinition, formatter: TimestampFormatter) -> NSMenuItem {
        let item = NSMenuItem(
            title: def.label,
            action: #selector(selectFormat(_:)),
            keyEquivalent: ""
        )
        item.target = self
        item.representedObject = def.type.rawValue
        item.state = (SettingsStore.activeFormatType == def.type) ? .on : .off
        let sample = formatter.string(type: def.type)
        item.toolTip = sample
        if #available(macOS 14.0, *) {
            item.subtitle = sample
        } else {
            item.attributedTitle = createMenuItemAttributedTitle(title: def.label, sample: sample)
        }
        return item
    }

    @objc private func selectFormat(_ sender: NSMenuItem) {
        if let rawValue = sender.representedObject as? String, let type = FormatType(rawValue: rawValue) {
            SettingsStore.activeFormatType = type
        }
    }

    @objc private func selectCustomFormat() {
        SettingsStore.activeFormatType = .custom
    }

    @objc private func insertTimestampNow() {
        inserter.insertTimestamp()
    }

    @objc private func toggleUseUTCTime(_ sender: NSMenuItem) {
        SettingsStore.useUTCTime.toggle()
    }

    private func installHotKey() {
        let controller = hotKeyController ?? HotKeyController { [weak self] in
            self?.inserter.insertTimestamp()
        }
        controller.register(SettingsStore.hotKey)
        hotKeyController = controller
    }

    @objc private func insertTimestamp() {
        inserter.insertTimestamp()
    }

    @objc private func openSettings() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController { [weak self] in
                self?.installHotKey()
            }
        }

        preferencesWindowController?.show()
    }

    @objc private func openAccessibilitySettings() {
        AccessibilityPermission.openSettings()
    }

    @objc private func openAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

private let app = NSApplication.shared
private let delegate = AppDelegate()
app.delegate = delegate
app.run()
