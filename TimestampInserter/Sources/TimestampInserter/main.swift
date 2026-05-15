import AppKit
import ApplicationServices
import Carbon

private let defaultTimestampFormat = "yyyy-MM-dd-HHmm"

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
    private static let formatKey = "timestampFormat"
    private static let hotKeyCodeKey = "hotKeyCode"
    private static let hotKeyModifiersKey = "hotKeyModifiers"

    static var timestampFormat: String {
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
        timestampFormat = defaultTimestampFormat
        hotKey = .defaultValue
    }
}

private final class TimestampFormatter {
    func string(from date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = SettingsStore.timestampFormat
        return formatter.string(from: date)
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
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 270),
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

        let formatLabel = NSTextField(labelWithString: "Timestamp format")
        formatLabel.font = .boldSystemFont(ofSize: 13)

        formatField.delegate = self
        formatField.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        formatField.placeholderString = defaultTimestampFormat
        formatField.translatesAutoresizingMaskIntoConstraints = false
        formatField.target = self
        formatField.action = #selector(formatFieldChanged)

        let helpLabel = NSTextField(labelWithString: "Examples: yyyy-MM-dd-HHmm, yyyy-MM-dd-HHmmX gives +07, yyyy-MM-dd-HHmmXXX gives +07:00.")
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
            formatField.widthAnchor.constraint(equalTo: root.widthAnchor, constant: -40),
            hotKeyRecorder.widthAnchor.constraint(equalToConstant: 260),
            hotKeyRecorder.heightAnchor.constraint(equalToConstant: 34),
            buttonRow.widthAnchor.constraint(equalTo: root.widthAnchor, constant: -40),
            spacer.widthAnchor.constraint(greaterThanOrEqualToConstant: 1)
        ])
    }

    private func loadSettings() {
        formatField.stringValue = SettingsStore.timestampFormat
        hotKeyRecorder.hotKey = SettingsStore.hotKey
        updateSample()
    }

    private func updateSample() {
        let format = cleanedFormat()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        sampleLabel.stringValue = "Preview: \(formatter.string(from: Date()))"
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
        hotKeyRecorder.hotKey = .defaultValue
        updateSample()
    }

    @objc private func cancel() {
        close()
    }

    @objc private func saveSettings() {
        SettingsStore.timestampFormat = cleanedFormat()
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

private final class AppDelegate: NSObject, NSApplicationDelegate {
    private let inserter = TimestampInserter()
    private var hotKeyController: HotKeyController?
    private var preferencesWindowController: PreferencesWindowController?
    private var statusItem: NSStatusItem?
    private var hotKeyMenuItem: NSMenuItem?
    private var formatMenuItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        installMenuBarItem()
        installHotKey()
        _ = AccessibilityPermission.isTrusted(prompt: true)
    }

    private func installMenuBarItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "TS"
        item.button?.toolTip = "Timestamp Inserter"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(
            title: "Insert Timestamp",
            action: #selector(insertTimestamp),
            keyEquivalent: ""
        ))

        let hotKeyItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        let formatItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        menu.addItem(hotKeyItem)
        menu.addItem(formatItem)
        menu.addItem(NSMenuItem(
            title: "Inserts directly without using clipboard",
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
            title: "Quit",
            action: #selector(quit),
            keyEquivalent: "q"
        ))

        item.menu = menu
        statusItem = item
        hotKeyMenuItem = hotKeyItem
        formatMenuItem = formatItem
        updateMenuLabels()
    }

    private func installHotKey() {
        let controller = hotKeyController ?? HotKeyController { [weak self] in
            self?.inserter.insertTimestamp()
        }
        controller.register(SettingsStore.hotKey)
        hotKeyController = controller
        updateMenuLabels()
    }

    private func updateMenuLabels() {
        hotKeyMenuItem?.title = "Hotkey: \(SettingsStore.hotKey.displayString)"
        formatMenuItem?.title = "Format: \(SettingsStore.timestampFormat)"
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

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

private let app = NSApplication.shared
private let delegate = AppDelegate()
app.delegate = delegate
app.run()
