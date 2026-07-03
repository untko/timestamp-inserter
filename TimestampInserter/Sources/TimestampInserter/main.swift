import AppKit
import ApplicationServices
import Carbon
import ServiceManagement

private let defaultTimestampFormat = "yyyy-MM-dd-HHmm"

private enum FormatType: String, Equatable {
    case seconds
    case milliseconds
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
    let badgeText: String
    let badgeColor: NSColor

    static let unix: [FormatDefinition] = [
        FormatDefinition(type: .seconds, label: "Seconds", badgeText: "TS", badgeColor: NSColor(red: 0.12, green: 0.6, blue: 0.98, alpha: 1.0)),
        FormatDefinition(type: .milliseconds, label: "Milliseconds", badgeText: "TS", badgeColor: NSColor(red: 0.12, green: 0.6, blue: 0.98, alpha: 1.0))
    ]

    static let date: [FormatDefinition] = [
        FormatDefinition(type: .iso8601, label: "ISO 8601 UTC", badgeText: "ISO", badgeColor: NSColor(red: 0.85, green: 0.2, blue: 0.85, alpha: 1.0)),
        FormatDefinition(type: .europeanShort, label: "European (short)", badgeText: "EU", badgeColor: NSColor(red: 0.4, green: 0.5, blue: 1.0, alpha: 1.0)),
        FormatDefinition(type: .european, label: "European", badgeText: "EU", badgeColor: NSColor(red: 0.4, green: 0.5, blue: 1.0, alpha: 1.0)),
        FormatDefinition(type: .germanLong, label: "German (long)", badgeText: "DE", badgeColor: NSColor(red: 0.4, green: 0.5, blue: 1.0, alpha: 1.0)),
        FormatDefinition(type: .us, label: "US", badgeText: "US", badgeColor: NSColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)),
        FormatDefinition(type: .usShort, label: "US (short)", badgeText: "US", badgeColor: NSColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)),
        FormatDefinition(type: .british, label: "British", badgeText: "UK", badgeColor: NSColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)),
        FormatDefinition(type: .rfc2822, label: "RFC 2822", badgeText: "RFC", badgeColor: NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)),
        FormatDefinition(type: .unixReadable, label: "Unix readable", badgeText: "UNIX", badgeColor: NSColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0))
    ]

    static let all = unix + date
}

private func createBadgeImage(text: String, color: NSColor) -> NSImage {
    let size = NSSize(width: 32, height: 16)
    let image = NSImage(size: size)
    image.lockFocus()

    let path = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 4, yRadius: 4)
    color.setFill()
    path.fill()

    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 10, weight: .bold),
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraph
    ]
    let attrString = NSAttributedString(string: text, attributes: attributes)
    let rect = NSRect(x: 0, y: (size.height - attrString.size().height) / 2 - 0.5, width: size.width, height: attrString.size().height)
    attrString.draw(in: rect)

    image.unlockFocus()
    image.isTemplate = false
    return image
}

private final class InteractiveMenuItemView: NSView {
    private var isHighlighted = false

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if isHighlighted {
            NSColor.selectedMenuItemColor.setFill()
            bounds.fill()
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInActiveApp], owner: self, userInfo: nil)
        addTrackingArea(area)
    }

    override func mouseEntered(with event: NSEvent) {
        isHighlighted = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHighlighted = false
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        isHighlighted = false
        needsDisplay = true

        guard let item = enclosingMenuItem, let menu = item.menu else { return }
        menu.cancelTracking()

        if let target = item.target as? NSObject, let action = item.action {
            target.perform(action, with: item)
        }
    }
}

private func createSectionHeader(title: String) -> NSMenuItem {
    let view = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 22))

    let line1 = NSBox(frame: NSRect(x: 10, y: 11, width: 40, height: 1))
    line1.boxType = .custom
    line1.fillColor = NSColor.separatorColor
    line1.borderWidth = 0

    let label = NSTextField(labelWithString: title)
    label.font = .systemFont(ofSize: 10, weight: .bold)
    label.textColor = NSColor.secondaryLabelColor
    label.sizeToFit()
    label.frame.origin = NSPoint(x: line1.frame.maxX + 8, y: (view.frame.height - label.frame.height) / 2)

    let line2 = NSBox(frame: NSRect(x: label.frame.maxX + 8, y: 11, width: 200, height: 1))
    line2.autoresizingMask = .width
    line2.boxType = .custom
    line2.fillColor = NSColor.separatorColor
    line2.borderWidth = 0

    view.addSubview(line1)
    view.addSubview(label)
    view.addSubview(line2)

    let item = NSMenuItem()
    item.view = view
    item.isEnabled = false
    return item
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
}

private enum SettingsStore {
    private static let formatTypeKey = "timestampFormatType"
    private static let formatKey = "timestampFormat"
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
            return .european
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
        activeFormatType = .european
        hotKey = .defaultValue
    }
}

private final class TimestampFormatter {
    func string(from date: Date = Date(), type: FormatType = SettingsStore.activeFormatType) -> String {
        switch type {
        case .seconds:
            return String(Int(date.timeIntervalSince1970))
        case .milliseconds:
            return String(Int(date.timeIntervalSince1970 * 1000))
        case .iso8601:
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.string(from: date)
        case .europeanShort:
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy"
            return formatter.string(from: date)
        case .european:
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
            return formatter.string(from: date)
        case .germanLong:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "de_DE")
            formatter.dateFormat = "d. MMMM yyyy, HH:mm 'Uhr'"
            return formatter.string(from: date)
        case .us:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "MM/dd/yyyy hh:mm:ss a"
            return formatter.string(from: date)
        case .usShort:
            let formatter = DateFormatter()
            formatter.dateFormat = "M/dd/yyyy"
            return formatter.string(from: date)
        case .british:
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
            return formatter.string(from: date)
        case .rfc2822:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
            return formatter.string(from: date)
        case .unixReadable:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "EEE MMM dd HH:mm:ss zzz yyyy"
            return formatter.string(from: date)
        case .custom:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = SettingsStore.customFormat
            return formatter.string(from: date)
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
        let path = NSBezierPath(roundedRect: bounds, xRadius: 6, yRadius: 6)
        let isFocused = window?.firstResponder === self

        (isFocused ? NSColor.controlAccentColor.withAlphaComponent(0.12) : NSColor.controlBackgroundColor).setFill()
        path.fill()

        (isFocused ? NSColor.controlAccentColor : NSColor.separatorColor).setStroke()
        path.lineWidth = isFocused ? 2 : 1
        path.stroke()

        let text = isRecording ? "Press shortcut..." : hotKey.displayString
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraph
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let textRect = NSRect(x: 8, y: (bounds.height - attributed.size().height) / 2, width: bounds.width - 16, height: attributed.size().height)
        attributed.draw(in: textRect)
    }
}

private final class PreferencesWindowController: NSWindowController, NSTextFieldDelegate {
    private let formatField = NSTextField()
    private let sampleLabel = NSTextField(labelWithString: "")
    private let hotKeyRecorder = HotKeyRecorderView(hotKey: SettingsStore.hotKey)
    private let onSave: () -> Void

    init(onSave: @escaping () -> Void) {
        self.onSave = onSave

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 360),
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
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func buildUI() {
        guard let contentView = window?.contentView else {
            return
        }

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 14
        root.translatesAutoresizingMaskIntoConstraints = false
        root.edgeInsets = NSEdgeInsets(top: 18, left: 20, bottom: 18, right: 20)
        contentView.addSubview(root)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            root.topAnchor.constraint(equalTo: contentView.topAnchor),
            root.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        let headerStack = NSStackView()
        headerStack.orientation = .horizontal
        headerStack.alignment = .centerY
        headerStack.spacing = 12

        let appIconImage = NSImage(named: "AppIcon") ?? NSImage()
        let appIconView = NSImageView(image: appIconImage)
        appIconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            appIconView.widthAnchor.constraint(equalToConstant: 64),
            appIconView.heightAnchor.constraint(equalToConstant: 64)
        ])

        let titleStack = NSStackView()
        titleStack.orientation = .vertical
        titleStack.alignment = .leading
        titleStack.spacing = 4

        let appTitleLabel = NSTextField(labelWithString: "Timestamp Inserter")
        appTitleLabel.font = .systemFont(ofSize: 18, weight: .bold)

        let descriptionLabel = NSTextField(labelWithString: "Insert timestamps directly into any text field.")
        descriptionLabel.font = .systemFont(ofSize: 12)
        descriptionLabel.textColor = .secondaryLabelColor

        titleStack.addArrangedSubview(appTitleLabel)
        titleStack.addArrangedSubview(descriptionLabel)

        headerStack.addArrangedSubview(appIconView)
        headerStack.addArrangedSubview(titleStack)

        root.addArrangedSubview(headerStack)

        let divider = NSBox()
        divider.boxType = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        root.addArrangedSubview(divider)

        if #available(macOS 13.0, *) {
            let launchAtLoginButton = NSButton(checkboxWithTitle: "Launch at login", target: self, action: #selector(toggleLaunchAtLogin))
            launchAtLoginButton.state = SMAppService.mainApp.status == .enabled ? .on : .off
            root.addArrangedSubview(launchAtLoginButton)
        }

        let formatLabel = NSTextField(labelWithString: "Custom Timestamp format")
        formatLabel.font = .boldSystemFont(ofSize: 13)

        formatField.delegate = self
        formatField.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        formatField.placeholderString = defaultTimestampFormat
        formatField.translatesAutoresizingMaskIntoConstraints = false
        formatField.target = self
        formatField.action = #selector(formatFieldChanged)

        let helpLabel = NSTextField(labelWithString: "Examples: yyyy-MM-dd-HHmm, yyyy-MM-dd-HHmmX gives +07. Editing this will switch you to the Custom format.")
        helpLabel.font = .systemFont(ofSize: 11)
        helpLabel.textColor = .secondaryLabelColor
        helpLabel.lineBreakMode = .byWordWrapping
        helpLabel.maximumNumberOfLines = 2

        sampleLabel.font = .systemFont(ofSize: 12)
        sampleLabel.textColor = .secondaryLabelColor

        root.addArrangedSubview(formatLabel)
        root.addArrangedSubview(formatField)
        root.addArrangedSubview(helpLabel)
        root.addArrangedSubview(sampleLabel)

        let hotKeyLabel = NSTextField(labelWithString: "Keyboard shortcut")
        hotKeyLabel.font = .boldSystemFont(ofSize: 13)

        hotKeyRecorder.translatesAutoresizingMaskIntoConstraints = false
        hotKeyRecorder.onChange = { [weak self] _ in
            self?.updateSample()
        }

        let hotKeyHelpLabel = NSTextField(labelWithString: "Click the field, then press the shortcut you want to use.")
        hotKeyHelpLabel.font = .systemFont(ofSize: 11)
        hotKeyHelpLabel.textColor = .secondaryLabelColor

        root.addArrangedSubview(hotKeyLabel)
        root.addArrangedSubview(hotKeyRecorder)
        root.addArrangedSubview(hotKeyHelpLabel)

        let buttonRow = NSStackView()
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY
        buttonRow.spacing = 8
        buttonRow.translatesAutoresizingMaskIntoConstraints = false

        let resetButton = NSButton(title: "Reset", target: self, action: #selector(resetSettings))
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        let saveButton = NSButton(title: "Save", target: self, action: #selector(saveSettings))
        saveButton.keyEquivalent = "\r"

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        buttonRow.addArrangedSubview(spacer)
        buttonRow.addArrangedSubview(resetButton)
        buttonRow.addArrangedSubview(cancelButton)
        buttonRow.addArrangedSubview(saveButton)

        root.addArrangedSubview(buttonRow)

        NSLayoutConstraint.activate([
            divider.widthAnchor.constraint(equalTo: root.widthAnchor, constant: -40),
            formatField.widthAnchor.constraint(equalTo: root.widthAnchor, constant: -40),
            hotKeyRecorder.widthAnchor.constraint(equalToConstant: 260),
            hotKeyRecorder.heightAnchor.constraint(equalToConstant: 34),
            buttonRow.widthAnchor.constraint(equalTo: root.widthAnchor, constant: -40),
            spacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 1)
        ])
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
            // Revert state on failure
            sender.state = sender.state == .on ? .off : .on
        }
    }

    private func loadSettings() {
        formatField.stringValue = SettingsStore.customFormat
        hotKeyRecorder.hotKey = SettingsStore.hotKey
        updateSample()
    }

    private func updateSample() {
        let formatter = TimestampFormatter()
        // If the user modified the field, preview the custom format string directly.
        // Otherwise, just preview whatever custom format it currently evaluates to.
        let format = cleanedFormat()
        let tempDateFormatter = DateFormatter()
        tempDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        tempDateFormatter.dateFormat = format

        sampleLabel.stringValue = "Custom Preview: \(tempDateFormatter.string(from: Date()))"
    }

    private func cleanedFormat() -> String {
        let trimmed = formatField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultTimestampFormat : trimmed
    }

    func controlTextDidChange(_ notification: Notification) {
        updateSample()
    }

    @objc private func formatFieldChanged() {
        updateSample()
    }

    @objc private func resetSettings() {
        formatField.stringValue = defaultTimestampFormat
        SettingsStore.activeFormatType = .european
        hotKeyRecorder.hotKey = .defaultValue
        updateSample()
    }

    @objc private func cancel() {
        close()
    }

    @objc private func saveSettings() {
        let oldCustom = SettingsStore.customFormat
        let newCustom = cleanedFormat()

        SettingsStore.customFormat = newCustom

        // If the user typed a new custom format in settings, switch to custom format mode automatically.
        if oldCustom != newCustom || SettingsStore.activeFormatType == .custom {
            SettingsStore.activeFormatType = .custom
        }

        SettingsStore.hotKey = hotKeyRecorder.hotKey
        onSave()
        close()
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
        NSApp.setActivationPolicy(.accessory)
        installMenuBarItem()
        installHotKey()
        _ = AccessibilityPermission.isTrusted(prompt: true)
    }

    private func installMenuBarItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "calendar.badge.clock", accessibilityDescription: "Timestamp Inserter")
        item.button?.toolTip = "Timestamp Inserter"

        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        statusItem = item
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        // Add Unix Timestamps section
        menu.addItem(createSectionHeader(title: "UNIX TIMESTAMP"))
        for def in FormatDefinition.unix {
            menu.addItem(createFormatMenuItem(for: def))
        }

        // Add Date Formats section
        menu.addItem(createSectionHeader(title: "DATE FORMAT"))
        for def in FormatDefinition.date {
            menu.addItem(createFormatMenuItem(for: def))
        }

        // Add Custom section
        menu.addItem(createSectionHeader(title: "CUSTOM"))
        let customItem = NSMenuItem(title: "Custom Format...", action: #selector(openSettings), keyEquivalent: "")
        customItem.target = self
        if SettingsStore.activeFormatType == .custom {
            customItem.state = .on
        }

        let customPreview = TimestampFormatter().string(type: .custom)
        let customAttr = NSAttributedString(string: customPreview, attributes: [.font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular), .foregroundColor: NSColor.secondaryLabelColor])

        // Setup a custom view to show the text + right aligned preview
        let container = InteractiveMenuItemView(frame: NSRect(x: 0, y: 0, width: 340, height: 22))
        let titleLabel = NSTextField(labelWithString: "   Custom Format")
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.sizeToFit()
        titleLabel.frame.origin = NSPoint(x: 20, y: (container.frame.height - titleLabel.frame.height) / 2)

        let previewLabel = NSTextField(labelWithAttributedString: customAttr)
        previewLabel.sizeToFit()
        previewLabel.frame.origin = NSPoint(x: container.frame.width - previewLabel.frame.width - 20, y: (container.frame.height - previewLabel.frame.height) / 2)

        container.addSubview(titleLabel)
        container.addSubview(previewLabel)

        let customHostItem = NSMenuItem()
        customHostItem.view = container
        customHostItem.action = #selector(selectCustomFormat)
        customHostItem.target = self

        menu.addItem(customHostItem)

        // If it's custom, add the checkmark logic.
        // We can't use standard state = .on with a custom view easily without drawing it ourselves,
        // so we just prepend a checkmark if it's active.
        if SettingsStore.activeFormatType == .custom {
            titleLabel.stringValue = "✓ Custom Format"
        } else {
            titleLabel.stringValue = "   Custom Format"
        }

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Hotkey: \(SettingsStore.hotKey.displayString)",
            action: nil,
            keyEquivalent: ""
        ))

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        ))
        menu.addItem(NSMenuItem(
            title: "Open Accessibility Settings",
            action: #selector(openAccessibilitySettings),
            keyEquivalent: ""
        ))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "About Timestamp Inserter",
            action: #selector(openAbout),
            keyEquivalent: ""
        ))
        menu.addItem(NSMenuItem(
            title: "Quit",
            action: #selector(quit),
            keyEquivalent: "q"
        ))
    }

    private func createFormatMenuItem(for def: FormatDefinition) -> NSMenuItem {
        let container = InteractiveMenuItemView(frame: NSRect(x: 0, y: 0, width: 340, height: 22))

        let badgeView = NSImageView(image: createBadgeImage(text: def.badgeText, color: def.badgeColor))
        badgeView.frame = NSRect(x: 20, y: (container.frame.height - 16) / 2, width: 32, height: 16)

        let titleLabel = NSTextField(labelWithString: def.label)
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.sizeToFit()
        titleLabel.frame.origin = NSPoint(x: badgeView.frame.maxX + 8, y: (container.frame.height - titleLabel.frame.height) / 2)

        let sampleText = TimestampFormatter().string(type: def.type)
        let sampleAttr = NSAttributedString(string: sampleText, attributes: [.font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular), .foregroundColor: NSColor.secondaryLabelColor])
        let sampleLabel = NSTextField(labelWithAttributedString: sampleAttr)
        sampleLabel.sizeToFit()

        sampleLabel.frame.origin = NSPoint(x: container.frame.width - sampleLabel.frame.width - 20, y: (container.frame.height - sampleLabel.frame.height) / 2)

        container.addSubview(badgeView)
        container.addSubview(titleLabel)
        container.addSubview(sampleLabel)

        if SettingsStore.activeFormatType == def.type {
            let checkmark = NSTextField(labelWithString: "✓")
            checkmark.font = .systemFont(ofSize: 14)
            checkmark.sizeToFit()
            checkmark.frame.origin = NSPoint(x: 6, y: (container.frame.height - checkmark.frame.height) / 2)
            container.addSubview(checkmark)
        }

        let item = NSMenuItem()
        item.view = container
        item.representedObject = def.type.rawValue
        item.action = #selector(selectFormat(_:))
        item.target = self
        return item
    }

    @objc private func selectFormat(_ sender: NSMenuItem) {
        if let rawValue = sender.representedObject as? String, let type = FormatType(rawValue: rawValue) {
            SettingsStore.activeFormatType = type
        }
    }

    @objc private func selectCustomFormat(_ sender: NSMenuItem) {
        SettingsStore.activeFormatType = .custom
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
                self?.updateMenuLabels()
            }
        }

        preferencesWindowController?.show()
    }

    @objc private func openAccessibilitySettings() {
        AccessibilityPermission.openSettings()
    }

    @objc private func openAbout() {
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
