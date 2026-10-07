import AppKit
import ApplicationServices
import Carbon
import ServiceManagement

private let defaultTimestampFormat = "yyyy-MM-dd-HHmm"

private enum FormatType: String, Equatable, Codable, CaseIterable {
    case seconds
    case milliseconds
    case compactLocal
    case dateOnly
    case timeOnly
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

    var displayName: String {
        switch self {
        case .compactLocal: return "Compact local (yyyy-MM-dd-HHmm)"
        case .dateOnly: return "Date only (yyyy-MM-dd)"
        case .timeOnly: return "Time only (HH:mm:ss)"
        case .seconds: return "Unix timestamp (seconds)"
        case .milliseconds: return "Unix timestamp (ms)"
        case .rfc3339Local: return "RFC 3339 Local"
        case .rfc3339LocalMilliseconds: return "RFC 3339 Local ms"
        case .iso8601: return "RFC 3339 UTC (ISO 8601)"
        case .europeanShort: return "European date (dd.MM.yyyy)"
        case .european: return "European (dd.MM.yyyy HH:mm:ss)"
        case .germanLong: return "German long"
        case .us: return "US (MM/dd/yyyy hh:mm:ss a)"
        case .usShort: return "US date (M/d/yyyy)"
        case .british: return "UK (dd/MM/yyyy HH:mm:ss)"
        case .rfc2822: return "Email date (RFC 2822)"
        case .unixReadable: return "Unix readable"
        case .custom: return "Custom Pattern…"
        }
    }
}

private struct FormatDefinition {
    let type: FormatType
    let label: String

    static let compactLocal = FormatDefinition(type: .compactLocal, label: "Compact local")
    static let dateOnly = FormatDefinition(type: .dateOnly, label: "Date only")
    static let timeOnly = FormatDefinition(type: .timeOnly, label: "Time only")
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
        dateOnly,
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
        dateOnly,
        timeOnly,
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
        dateOnly,
        timeOnly,
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

private struct HotKey: Equatable, Codable {
    var keyCode: UInt32
    var modifiers: UInt32

    static let defaultValue = HotKey(
        keyCode: UInt32(kVK_ANSI_S),
        modifiers: UInt32(controlKey | shiftKey)
    )

    static let dateDefaultValue = HotKey(
        keyCode: UInt32(kVK_ANSI_D),
        modifiers: UInt32(controlKey | shiftKey)
    )

    var displayString: String {
        var parts: [String] = []

        if modifiers & UInt32(controlKey) != 0 { parts.append("Control") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("Option") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("Shift") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("Command") }

        parts.append(Self.keyName(for: keyCode))
        return parts.joined(separator: "-")
    }

    var glyphString: String {
        var glyphs = ""
        if modifiers & UInt32(controlKey) != 0 { glyphs += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { glyphs += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { glyphs += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { glyphs += "⌘" }
        glyphs += Self.keyGlyph(for: keyCode)
        return glyphs
    }

    static func modifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.control) { result |= UInt32(controlKey) }
        if flags.contains(.option) { result |= UInt32(optionKey) }
        if flags.contains(.shift) { result |= UInt32(shiftKey) }
        if flags.contains(.command) { result |= UInt32(cmdKey) }
        return result
    }

    static func modifierMask(from carbonModifiers: UInt32) -> NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if carbonModifiers & UInt32(controlKey) != 0 { flags.insert(.control) }
        if carbonModifiers & UInt32(optionKey) != 0 { flags.insert(.option) }
        if carbonModifiers & UInt32(shiftKey) != 0 { flags.insert(.shift) }
        if carbonModifiers & UInt32(cmdKey) != 0 { flags.insert(.command) }
        return flags
    }

    static func keyEquivalentChar(for keyCode: UInt32) -> String? {
        switch Int(keyCode) {
        case kVK_ANSI_A: return "a"
        case kVK_ANSI_B: return "b"
        case kVK_ANSI_C: return "c"
        case kVK_ANSI_D: return "d"
        case kVK_ANSI_E: return "e"
        case kVK_ANSI_F: return "f"
        case kVK_ANSI_G: return "g"
        case kVK_ANSI_H: return "h"
        case kVK_ANSI_I: return "i"
        case kVK_ANSI_J: return "j"
        case kVK_ANSI_K: return "k"
        case kVK_ANSI_L: return "l"
        case kVK_ANSI_M: return "m"
        case kVK_ANSI_N: return "n"
        case kVK_ANSI_O: return "o"
        case kVK_ANSI_P: return "p"
        case kVK_ANSI_Q: return "q"
        case kVK_ANSI_R: return "r"
        case kVK_ANSI_S: return "s"
        case kVK_ANSI_T: return "t"
        case kVK_ANSI_U: return "u"
        case kVK_ANSI_V: return "v"
        case kVK_ANSI_W: return "w"
        case kVK_ANSI_X: return "x"
        case kVK_ANSI_Y: return "y"
        case kVK_ANSI_Z: return "z"
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
        default: return nil
        }
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

private struct ShortcutBinding: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var formatType: FormatType
    var customFormat: String
    var useUTC: Bool
    var hotKey: HotKey
    var isEnabled: Bool

    init(
        id: String = UUID().uuidString,
        name: String = "",
        formatType: FormatType = .compactLocal,
        customFormat: String = defaultTimestampFormat,
        useUTC: Bool = false,
        hotKey: HotKey = HotKey.defaultValue,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.formatType = formatType
        self.customFormat = customFormat
        self.useUTC = useUTC
        self.hotKey = hotKey
        self.isEnabled = isEnabled
    }

    static var defaultBindings: [ShortcutBinding] {
        [
            ShortcutBinding(
                id: "default-compact",
                name: "Full Timestamp",
                formatType: .compactLocal,
                customFormat: defaultTimestampFormat,
                useUTC: false,
                hotKey: HotKey(keyCode: UInt32(kVK_ANSI_S), modifiers: UInt32(controlKey | shiftKey)),
                isEnabled: true
            ),
            ShortcutBinding(
                id: "default-date",
                name: "Date Only",
                formatType: .dateOnly,
                customFormat: "yyyy-MM-dd",
                useUTC: false,
                hotKey: HotKey(keyCode: UInt32(kVK_ANSI_D), modifiers: UInt32(controlKey | shiftKey)),
                isEnabled: true
            )
        ]
    }
}

private enum SettingsStore {
    private static let bindingsKey = "shortcutBindings"
    private static let formatTypeKey = "timestampFormatType"
    private static let formatKey = "timestampFormat"
    private static let useUTCTimeKey = "useUTCTime"
    private static let hotKeyCodeKey = "hotKeyCode"
    private static let hotKeyModifiersKey = "hotKeyModifiers"

    static var bindings: [ShortcutBinding] {
        get {
            if let data = UserDefaults.standard.data(forKey: bindingsKey),
               let decoded = try? JSONDecoder().decode([ShortcutBinding].self, from: data),
               !decoded.isEmpty {
                return decoded
            }

            // Migration from legacy single-shortcut settings if present
            if UserDefaults.standard.object(forKey: hotKeyCodeKey) != nil {
                let keyCode = UInt32(UserDefaults.standard.integer(forKey: hotKeyCodeKey))
                let modifiers = UInt32(UserDefaults.standard.integer(forKey: hotKeyModifiersKey))
                let legacyHotKey = (modifiers != 0) ? HotKey(keyCode: keyCode, modifiers: modifiers) : HotKey.defaultValue
                let legacyType = activeFormatType
                let legacyCustom = customFormat
                let legacyUTC = useUTCTime

                let migrated = [
                    ShortcutBinding(
                        id: "legacy-primary",
                        name: "Full Timestamp",
                        formatType: legacyType,
                        customFormat: legacyCustom,
                        useUTC: legacyUTC,
                        hotKey: legacyHotKey,
                        isEnabled: true
                    ),
                    ShortcutBinding(
                        id: "default-date",
                        name: "Date Only",
                        formatType: .dateOnly,
                        customFormat: "yyyy-MM-dd",
                        useUTC: false,
                        hotKey: HotKey.dateDefaultValue,
                        isEnabled: true
                    )
                ]
                Self.bindings = migrated
                return migrated
            }

            return ShortcutBinding.defaultBindings
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: bindingsKey)
            }
        }
    }

    static var activeFormatType: FormatType {
        get {
            if let saved = UserDefaults.standard.string(forKey: formatTypeKey), let type = FormatType(rawValue: saved) {
                return type
            }
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
            bindings.first?.hotKey ?? HotKey.defaultValue
        }
    }

    static func reset() {
        bindings = ShortcutBinding.defaultBindings
        activeFormatType = .compactLocal
        customFormat = defaultTimestampFormat
        useUTCTime = false
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

    func string(from date: Date = Date(), type: FormatType = .compactLocal, useUTC: Bool = false, customFormat: String? = nil) -> String {
        switch type {
        case .seconds:
            return String(Int(date.timeIntervalSince1970))
        case .milliseconds:
            return String(Int(date.timeIntervalSince1970 * 1000))
        case .compactLocal:
            return formatter(format: defaultTimestampFormat, useUTC: useUTC).string(from: date)
        case .dateOnly:
            return formatter(format: "yyyy-MM-dd", useUTC: useUTC).string(from: date)
        case .timeOnly:
            return formatter(format: "HH:mm:ss", useUTC: useUTC).string(from: date)
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
            let pattern = customFormat?.trimmingCharacters(in: .whitespacesAndNewlines)
            let effective = (pattern == nil || pattern!.isEmpty) ? defaultTimestampFormat : pattern!
            return formatter(format: effective, useUTC: useUTC).string(from: date)
        }
    }

    func string(from date: Date = Date(), binding: ShortcutBinding) -> String {
        string(from: date, type: binding.formatType, useUTC: binding.useUTC, customFormat: binding.customFormat)
    }
}

private final class TimestampInserter {
    private let formatter = TimestampFormatter()

    func insertTimestamp(for binding: ShortcutBinding? = nil) {
        guard AccessibilityPermission.isTrusted(prompt: true) else {
            NSSound.beep()
            return
        }

        let timestamp: String
        if let binding = binding {
            timestamp = formatter.string(binding: binding)
        } else if let first = SettingsStore.bindings.first {
            timestamp = formatter.string(binding: first)
        } else {
            timestamp = formatter.string(type: SettingsStore.activeFormatType, useUTC: SettingsStore.useUTCTime)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.typeText(timestamp)
        }
    }

    func insertTimestamp(type: FormatType, useUTC: Bool, customFormat: String? = nil) {
        guard AccessibilityPermission.isTrusted(prompt: true) else {
            NSSound.beep()
            return
        }

        let timestamp = formatter.string(type: type, useUTC: useUTC, customFormat: customFormat)
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
    private let callback: (ShortcutBinding) -> Void
    private var eventHandler: EventHandlerRef?
    private var registeredHotKeys: [UInt32: (ref: EventHotKeyRef, binding: ShortcutBinding)] = [:]
    private var nextID: UInt32 = 1

    init(callback: @escaping (ShortcutBinding) -> Void) {
        self.callback = callback
        installEventHandler()
    }

    func register(bindings: [ShortcutBinding]) {
        unregisterAll()

        for binding in bindings where binding.isEnabled {
            guard binding.hotKey.modifiers != 0 else { continue }

            let hotKeyID = EventHotKeyID(signature: fourCharacterCode("TmSt"), id: nextID)
            var hotKeyRef: EventHotKeyRef?
            let status = RegisterEventHotKey(
                binding.hotKey.keyCode,
                binding.hotKey.modifiers,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &hotKeyRef
            )

            if status == noErr, let ref = hotKeyRef {
                registeredHotKeys[nextID] = (ref, binding)
                nextID += 1
            } else {
                print("Could not register hotkey \(binding.hotKey.displayString)")
            }
        }
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let event = event, let userData = userData else {
                    return noErr
                }

                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                if status == noErr {
                    let controller = Unmanaged<HotKeyController>.fromOpaque(userData).takeUnretainedValue()
                    controller.handleHotKey(id: hotKeyID.id)
                }

                return noErr
            },
            1,
            &eventType,
            userData,
            &eventHandler
        )
    }

    private func handleHotKey(id: UInt32) {
        guard let entry = registeredHotKeys[id] else { return }
        callback(entry.binding)
    }

    private func unregisterAll() {
        for (_, entry) in registeredHotKeys {
            UnregisterEventHotKey(entry.ref)
        }
        registeredHotKeys.removeAll()
        nextID = 1
    }

    deinit {
        unregisterAll()
        if let eventHandler = eventHandler {
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
        let path = NSBezierPath(roundedRect: bounds, xRadius: 7, yRadius: 7)
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
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: isRecording ? NSColor.secondaryLabelColor : NSColor.labelColor,
            .paragraphStyle: paragraph
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let textRect = NSRect(x: 4, y: (bounds.height - attributed.size().height) / 2, width: bounds.width - 8, height: attributed.size().height)
        attributed.draw(in: textRect)
    }
}

private final class AppIconSquircleView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let squirclePath = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 11, yRadius: 11)

        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let bgColor = isDark
            ? NSColor(white: 0.24, alpha: 1.0)
            : NSColor(white: 0.92, alpha: 1.0)
        let borderColor = isDark
            ? NSColor(white: 0.38, alpha: 0.6)
            : NSColor(white: 0.78, alpha: 0.8)

        bgColor.setFill()
        squirclePath.fill()

        borderColor.setStroke()
        squirclePath.lineWidth = 1
        squirclePath.stroke()

        let iconRect = bounds.insetBy(dx: 10, dy: 10)
        let tintColor: NSColor = isDark ? .white : NSColor(white: 0.15, alpha: 1.0)

        if let icon = Bundle.main.image(forResource: "MenuBarIcon") ?? NSImage(named: "MenuBarIcon"),
           let cgImage = icon.cgImage(forProposedRect: nil, context: nil, hints: nil),
           let ctx = NSGraphicsContext.current?.cgContext {
            ctx.saveGState()
            ctx.clip(to: iconRect, mask: cgImage)
            tintColor.setFill()
            ctx.fill(iconRect)
            ctx.restoreGState()
        } else {
            let circlePath = NSBezierPath(ovalIn: iconRect)
            tintColor.setStroke()
            circlePath.lineWidth = 2.2
            circlePath.stroke()

            let center = NSPoint(x: iconRect.midX, y: iconRect.midY)
            let hand1 = NSBezierPath()
            hand1.move(to: center)
            hand1.line(to: NSPoint(x: center.x, y: center.y + iconRect.height * 0.35))
            tintColor.setStroke()
            hand1.lineWidth = 2.2
            hand1.lineCapStyle = .round
            hand1.stroke()

            let hand2 = NSBezierPath()
            hand2.move(to: center)
            hand2.line(to: NSPoint(x: center.x + iconRect.width * 0.28, y: center.y))
            tintColor.setStroke()
            hand2.lineWidth = 2.2
            hand2.lineCapStyle = .round
            hand2.stroke()
        }
    }
}

private final class CardView: NSView {
    let stack: NSStackView

    init(spacing: CGFloat = 12, insets: NSEdgeInsets = NSEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)) {
        self.stack = NSStackView()
        self.stack.orientation = .vertical
        self.stack.alignment = .leading
        self.stack.spacing = spacing
        self.stack.translatesAutoresizingMaskIntoConstraints = false

        super.init(frame: .zero)
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false

        layer?.cornerRadius = 10
        layer?.borderWidth = 1
        updateColors()

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func updateLayer() {
        super.updateLayer()
        updateColors()
    }

    private func updateColors() {
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        layer?.backgroundColor = isDark
            ? NSColor(white: 0.17, alpha: 0.75).cgColor
            : NSColor(white: 0.96, alpha: 0.85).cgColor
        layer?.borderColor = isDark
            ? NSColor(white: 0.28, alpha: 0.8).cgColor
            : NSColor(white: 0.82, alpha: 0.9).cgColor
    }
}

private final class ShortcutRowView: NSView, NSTextFieldDelegate {
    private var binding: ShortcutBinding
    private let presetPopup = NSPopUpButton()
    private let hotKeyRecorder: HotKeyRecorderView
    private let deleteButton = NSButton()
    private let customPatternField = NSTextField()
    private let livePreviewText = NSTextField(labelWithString: "")
    private let utcButton = NSButton(checkboxWithTitle: "UTC", target: nil, action: nil)
    private let formatter = TimestampFormatter()

    var onUpdate: ((ShortcutBinding) -> Void)?
    var onDelete: (() -> Void)?

    init(binding: ShortcutBinding, canDelete: Bool) {
        self.binding = binding
        self.hotKeyRecorder = HotKeyRecorderView(hotKey: binding.hotKey)
        super.init(frame: .zero)
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false

        layer?.cornerRadius = 8
        layer?.borderWidth = 1
        updateColors()

        buildUI(canDelete: canDelete)
        populateData()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func updateLayer() {
        super.updateLayer()
        updateColors()
    }

    private func updateColors() {
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        layer?.backgroundColor = isDark
            ? NSColor(white: 0.10, alpha: 0.6).cgColor
            : NSColor(white: 0.92, alpha: 0.7).cgColor
        layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.3).cgColor
    }

    private func buildUI(canDelete: Bool) {
        let rowStack = NSStackView()
        rowStack.orientation = .vertical
        rowStack.alignment = .leading
        rowStack.spacing = 8
        rowStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(rowStack)
        NSLayoutConstraint.activate([
            rowStack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            rowStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            rowStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            rowStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])

        // Top line
        let topLine = NSStackView()
        topLine.orientation = .horizontal
        topLine.alignment = .centerY
        topLine.spacing = 8
        topLine.translatesAutoresizingMaskIntoConstraints = false

        configurePresetPopup()
        presetPopup.target = self
        presetPopup.action = #selector(presetChanged)
        presetPopup.setContentHuggingPriority(.defaultLow, for: .horizontal)

        hotKeyRecorder.translatesAutoresizingMaskIntoConstraints = false
        hotKeyRecorder.onChange = { [weak self] newKey in
            guard let self = self else { return }
            self.binding.hotKey = newKey
            self.onUpdate?(self.binding)
        }
        NSLayoutConstraint.activate([
            hotKeyRecorder.widthAnchor.constraint(equalToConstant: 88),
            hotKeyRecorder.heightAnchor.constraint(equalToConstant: 28)
        ])

        topLine.addArrangedSubview(presetPopup)
        topLine.addArrangedSubview(hotKeyRecorder)

        if canDelete {
            deleteButton.title = "✕"
            deleteButton.bezelStyle = .inline
            deleteButton.font = .systemFont(ofSize: 11, weight: .bold)
            deleteButton.contentTintColor = .secondaryLabelColor
            deleteButton.target = self
            deleteButton.action = #selector(deleteClicked)
            deleteButton.setContentHuggingPriority(.required, for: .horizontal)
            topLine.addArrangedSubview(deleteButton)
        }

        rowStack.addArrangedSubview(topLine)
        NSLayoutConstraint.activate([
            topLine.leadingAnchor.constraint(equalTo: rowStack.leadingAnchor),
            topLine.trailingAnchor.constraint(equalTo: rowStack.trailingAnchor)
        ])

        // Custom pattern field
        customPatternField.delegate = self
        customPatternField.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        customPatternField.placeholderString = defaultTimestampFormat
        customPatternField.translatesAutoresizingMaskIntoConstraints = false
        customPatternField.target = self
        customPatternField.action = #selector(patternFieldChanged)
        customPatternField.isHidden = true
        rowStack.addArrangedSubview(customPatternField)
        NSLayoutConstraint.activate([
            customPatternField.leadingAnchor.constraint(equalTo: rowStack.leadingAnchor),
            customPatternField.trailingAnchor.constraint(equalTo: rowStack.trailingAnchor)
        ])

        // Bottom line: Preview + UTC
        let bottomLine = NSStackView()
        bottomLine.orientation = .horizontal
        bottomLine.alignment = .centerY
        bottomLine.distribution = .fill
        bottomLine.translatesAutoresizingMaskIntoConstraints = false

        let prevStack = NSStackView()
        prevStack.orientation = .horizontal
        prevStack.alignment = .firstBaseline
        prevStack.spacing = 6

        let previewTag = NSTextField(labelWithString: "Types:")
        previewTag.font = .systemFont(ofSize: 10, weight: .bold)
        previewTag.textColor = .secondaryLabelColor

        livePreviewText.font = .monospacedSystemFont(ofSize: 11, weight: .semibold)
        livePreviewText.textColor = .controlAccentColor

        prevStack.addArrangedSubview(previewTag)
        prevStack.addArrangedSubview(livePreviewText)

        utcButton.font = .systemFont(ofSize: 11)
        utcButton.target = self
        utcButton.action = #selector(utcChanged)
        utcButton.setContentHuggingPriority(.required, for: .horizontal)

        bottomLine.addArrangedSubview(prevStack)
        bottomLine.addArrangedSubview(utcButton)

        rowStack.addArrangedSubview(bottomLine)
        NSLayoutConstraint.activate([
            bottomLine.leadingAnchor.constraint(equalTo: rowStack.leadingAnchor),
            bottomLine.trailingAnchor.constraint(equalTo: rowStack.trailingAnchor)
        ])
    }

    private func configurePresetPopup() {
        presetPopup.removeAllItems()
        let presets: [FormatType] = [
            .compactLocal,
            .dateOnly,
            .timeOnly,
            .iso8601,
            .rfc3339Local,
            .british,
            .us,
            .european,
            .seconds,
            .milliseconds
        ]
        for type in presets {
            presetPopup.addItem(withTitle: type.displayName)
            presetPopup.lastItem?.representedObject = type.rawValue
        }
        presetPopup.menu?.addItem(.separator())
        presetPopup.addItem(withTitle: "Custom Pattern…")
        presetPopup.lastItem?.representedObject = FormatType.custom.rawValue
    }

    private func populateData() {
        if let item = presetPopup.itemArray.first(where: { $0.representedObject as? String == binding.formatType.rawValue }) {
            presetPopup.select(item)
        } else {
            presetPopup.selectItem(withTitle: "Custom Pattern…")
        }

        customPatternField.stringValue = binding.customFormat
        customPatternField.isHidden = (binding.formatType != .custom)
        utcButton.state = binding.useUTC ? .on : .off
        hotKeyRecorder.hotKey = binding.hotKey
        updatePreview()
    }

    private func updatePreview() {
        livePreviewText.stringValue = formatter.string(binding: binding)
    }

    @objc private func presetChanged() {
        guard let raw = presetPopup.selectedItem?.representedObject as? String,
              let type = FormatType(rawValue: raw) else { return }
        binding.formatType = type
        customPatternField.isHidden = (type != .custom)
        updatePreview()
        onUpdate?(binding)
    }

    @objc private func utcChanged() {
        binding.useUTC = (utcButton.state == .on)
        updatePreview()
        onUpdate?(binding)
    }

    @objc private func patternFieldChanged() {
        let trimmed = customPatternField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        binding.customFormat = trimmed.isEmpty ? defaultTimestampFormat : trimmed
        updatePreview()
        onUpdate?(binding)
    }

    func controlTextDidChange(_ notification: Notification) {
        patternFieldChanged()
    }

    @objc private func deleteClicked() {
        onDelete?()
    }
}

private final class PreferencesWindowController: NSWindowController {
    private var bindings: [ShortcutBinding] = []
    private let shortcutsStack = NSStackView()
    private var launchAtLoginButton: NSButton?
    private let accessibilityStatusDot = NSView()
    private let accessibilityStatusLabel = NSTextField(labelWithString: "")
    private let accessibilityButton = NSButton(title: "System Settings…", target: nil, action: nil)
    private let onChange: () -> Void

    init(onChange: @escaping () -> Void) {
        self.onChange = onChange

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 490, height: 480),
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

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func show() {
        loadSettings()
        updateAccessibilityStatus()
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func buildUI() {
        guard let contentView = window?.contentView else { return }

        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 14
        root.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(root)

        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
            root.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            root.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            root.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18)
        ])

        // 1. Header
        let header = NSStackView()
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 14
        header.translatesAutoresizingMaskIntoConstraints = false

        let squircleIcon = AppIconSquircleView()
        NSLayoutConstraint.activate([
            squircleIcon.widthAnchor.constraint(equalToConstant: 44),
            squircleIcon.heightAnchor.constraint(equalToConstant: 44)
        ])

        let titleCol = NSStackView()
        titleCol.orientation = .vertical
        titleCol.alignment = .leading
        titleCol.spacing = 2
        titleCol.translatesAutoresizingMaskIntoConstraints = false

        let titleRow = NSStackView()
        titleRow.orientation = .horizontal
        titleRow.alignment = .firstBaseline
        titleRow.spacing = 6
        let appTitleLabel = NSTextField(labelWithString: "Timestamp Inserter")
        appTitleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        appTitleLabel.textColor = .labelColor

        let versionLabel = NSTextField(labelWithString: "v1.0")
        versionLabel.font = .monospacedSystemFont(ofSize: 11, weight: .medium)
        versionLabel.textColor = .secondaryLabelColor

        titleRow.addArrangedSubview(appTitleLabel)
        titleRow.addArrangedSubview(versionLabel)

        let descLabel = NSTextField(labelWithString: "Insert formatted timestamps directly into any focused text field.")
        descLabel.font = .systemFont(ofSize: 11)
        descLabel.textColor = .secondaryLabelColor

        titleCol.addArrangedSubview(titleRow)
        titleCol.addArrangedSubview(descLabel)

        header.addArrangedSubview(squircleIcon)
        header.addArrangedSubview(titleCol)
        root.addArrangedSubview(header)

        // 2. Shortcuts Card
        let shortcutsCard = CardView(spacing: 12)

        let sectionHeaderRow = NSStackView()
        sectionHeaderRow.orientation = .horizontal
        sectionHeaderRow.alignment = .centerY
        sectionHeaderRow.distribution = .fill
        sectionHeaderRow.translatesAutoresizingMaskIntoConstraints = false

        let secHeader = NSTextField(labelWithString: "KEYBOARD SHORTCUTS & FORMATS")
        secHeader.font = .systemFont(ofSize: 10, weight: .bold)
        secHeader.textColor = .secondaryLabelColor
        secHeader.setContentHuggingPriority(.defaultLow, for: .horizontal)
        sectionHeaderRow.addArrangedSubview(secHeader)

        let addBtn = NSButton(title: "+ Add Shortcut", target: self, action: #selector(addShortcutClicked))
        addBtn.bezelStyle = .inline
        addBtn.font = .systemFont(ofSize: 11, weight: .medium)
        addBtn.setContentHuggingPriority(.required, for: .horizontal)
        sectionHeaderRow.addArrangedSubview(addBtn)

        shortcutsCard.stack.addArrangedSubview(sectionHeaderRow)
        NSLayoutConstraint.activate([
            sectionHeaderRow.leadingAnchor.constraint(equalTo: shortcutsCard.stack.leadingAnchor),
            sectionHeaderRow.trailingAnchor.constraint(equalTo: shortcutsCard.stack.trailingAnchor)
        ])

        shortcutsStack.orientation = .vertical
        shortcutsStack.alignment = .leading
        shortcutsStack.spacing = 8
        shortcutsStack.translatesAutoresizingMaskIntoConstraints = false
        shortcutsCard.stack.addArrangedSubview(shortcutsStack)
        NSLayoutConstraint.activate([
            shortcutsStack.leadingAnchor.constraint(equalTo: shortcutsCard.stack.leadingAnchor),
            shortcutsStack.trailingAnchor.constraint(equalTo: shortcutsCard.stack.trailingAnchor)
        ])

        root.addArrangedSubview(shortcutsCard)

        // 3. System & Permissions Card
        let sysCard = CardView(spacing: 10)
        let sHeader = NSTextField(labelWithString: "SYSTEM & PERMISSIONS")
        sHeader.font = .systemFont(ofSize: 10, weight: .bold)
        sHeader.textColor = .secondaryLabelColor
        sysCard.stack.addArrangedSubview(sHeader)

        if #available(macOS 13.0, *) {
            let launchButton = NSButton(checkboxWithTitle: "Launch at login", target: self, action: #selector(toggleLaunchAtLogin))
            launchButton.state = SMAppService.mainApp.status == .enabled ? .on : .off
            launchButton.font = .systemFont(ofSize: 12)
            self.launchAtLoginButton = launchButton
            sysCard.stack.addArrangedSubview(launchButton)
        }

        let permRow = NSStackView()
        permRow.orientation = .horizontal
        permRow.alignment = .centerY
        permRow.distribution = .fill
        permRow.translatesAutoresizingMaskIntoConstraints = false

        let permLeft = NSStackView()
        permLeft.orientation = .horizontal
        permLeft.alignment = .centerY
        permLeft.spacing = 8

        accessibilityStatusDot.wantsLayer = true
        accessibilityStatusDot.layer?.cornerRadius = 4
        accessibilityStatusDot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            accessibilityStatusDot.widthAnchor.constraint(equalToConstant: 8),
            accessibilityStatusDot.heightAnchor.constraint(equalToConstant: 8)
        ])

        accessibilityStatusLabel.font = .systemFont(ofSize: 11, weight: .medium)
        accessibilityStatusLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        permLeft.addArrangedSubview(accessibilityStatusDot)
        permLeft.addArrangedSubview(accessibilityStatusLabel)

        accessibilityButton.bezelStyle = .inline
        accessibilityButton.font = .systemFont(ofSize: 11)
        accessibilityButton.target = self
        accessibilityButton.action = #selector(openSystemSettings)
        accessibilityButton.setContentHuggingPriority(.required, for: .horizontal)

        permRow.addArrangedSubview(permLeft)
        permRow.addArrangedSubview(accessibilityButton)
        sysCard.stack.addArrangedSubview(permRow)
        NSLayoutConstraint.activate([
            permRow.leadingAnchor.constraint(equalTo: sysCard.stack.leadingAnchor),
            permRow.trailingAnchor.constraint(equalTo: sysCard.stack.trailingAnchor)
        ])

        root.addArrangedSubview(sysCard)

        // 4. Footer
        let footer = NSStackView()
        footer.orientation = .horizontal
        footer.alignment = .centerY
        footer.distribution = .fill
        footer.translatesAutoresizingMaskIntoConstraints = false

        let autoSave = NSTextField(labelWithString: "Changes are applied automatically.")
        autoSave.font = .systemFont(ofSize: 11)
        autoSave.textColor = .tertiaryLabelColor
        autoSave.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let resetBtn = NSButton(title: "Reset to Defaults", target: self, action: #selector(resetSettings))
        resetBtn.bezelStyle = .rounded
        resetBtn.font = .systemFont(ofSize: 11)
        resetBtn.setContentHuggingPriority(.required, for: .horizontal)

        footer.addArrangedSubview(autoSave)
        footer.addArrangedSubview(resetBtn)
        root.addArrangedSubview(footer)

        // Full width constraints
        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            shortcutsCard.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            shortcutsCard.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            sysCard.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            sysCard.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            footer.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            footer.trailingAnchor.constraint(equalTo: root.trailingAnchor)
        ])
    }

    private func loadSettings() {
        bindings = SettingsStore.bindings
        rebuildRows()
    }

    private func rebuildRows() {
        for sub in shortcutsStack.arrangedSubviews {
            shortcutsStack.removeArrangedSubview(sub)
            sub.removeFromSuperview()
        }

        let canDelete = bindings.count > 1
        for (idx, binding) in bindings.enumerated() {
            let row = ShortcutRowView(binding: binding, canDelete: canDelete)
            row.onUpdate = { [weak self] updated in
                guard let self = self, idx < self.bindings.count else { return }
                self.bindings[idx] = updated
                SettingsStore.bindings = self.bindings
                self.onChange()
            }
            row.onDelete = { [weak self] in
                guard let self = self, idx < self.bindings.count else { return }
                self.bindings.remove(at: idx)
                SettingsStore.bindings = self.bindings
                self.rebuildRows()
                self.onChange()
            }
            shortcutsStack.addArrangedSubview(row)
            NSLayoutConstraint.activate([
                row.leadingAnchor.constraint(equalTo: shortcutsStack.leadingAnchor),
                row.trailingAnchor.constraint(equalTo: shortcutsStack.trailingAnchor)
            ])
        }

        adjustWindowHeight()
    }

    private func adjustWindowHeight() {
        guard let window = window, let contentView = window.contentView else { return }
        window.layoutIfNeeded()
        let idealHeight = contentView.fittingSize.height
        let targetHeight = max(440, min(idealHeight, 720))
        var frame = window.frame
        let diff = targetHeight - frame.height
        frame.origin.y -= diff
        frame.size.height = targetHeight
        window.setFrame(frame, display: true, animate: window.isVisible)
    }

    @objc private func addShortcutClicked() {
        let usedKeyCodes = Set(bindings.map { $0.hotKey.keyCode })
        let nextKey: UInt32
        let nextFormat: FormatType
        let nextName: String

        if !usedKeyCodes.contains(UInt32(kVK_ANSI_T)) {
            nextKey = UInt32(kVK_ANSI_T)
            nextFormat = .timeOnly
            nextName = "Time Only"
        } else if !usedKeyCodes.contains(UInt32(kVK_ANSI_U)) {
            nextKey = UInt32(kVK_ANSI_U)
            nextFormat = .seconds
            nextName = "Unix Epoch"
        } else {
            nextKey = UInt32(kVK_ANSI_K)
            nextFormat = .custom
            nextName = "Custom"
        }

        let newBinding = ShortcutBinding(
            name: nextName,
            formatType: nextFormat,
            customFormat: defaultTimestampFormat,
            useUTC: false,
            hotKey: HotKey(keyCode: nextKey, modifiers: UInt32(controlKey | shiftKey)),
            isEnabled: true
        )
        bindings.append(newBinding)
        SettingsStore.bindings = bindings
        rebuildRows()
        onChange()
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

    @objc private func resetSettings() {
        SettingsStore.reset()
        bindings = SettingsStore.bindings
        rebuildRows()
        onChange()
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private var preferencesWindowController: PreferencesWindowController?
    private var hotKeyController: HotKeyController?
    private let inserter = TimestampInserter()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        installHotKeys()
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            if let customIcon = Bundle.main.image(forResource: "MenuBarIcon") ?? NSImage(named: "MenuBarIcon") {
                customIcon.isTemplate = true
                button.image = customIcon
            } else if let fallback = NSImage(systemSymbolName: "clock", accessibilityDescription: "Timestamp Inserter") {
                fallback.isTemplate = true
                button.image = fallback
            }
            button.imagePosition = .imageOnly
            button.toolTip = "Timestamp Inserter"
        }

        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        statusItem = item
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let formatter = TimestampFormatter()
        let bindings = SettingsStore.bindings.filter { $0.isEnabled }

        // 1. Top action items for each registered shortcut
        if bindings.isEmpty {
            let insertItem = NSMenuItem(
                title: "Insert Timestamp",
                action: #selector(insertTimestampNow),
                keyEquivalent: ""
            )
            insertItem.target = self
            menu.addItem(insertItem)
        } else {
            for (idx, binding) in bindings.enumerated() {
                let label = binding.name.isEmpty ? binding.formatType.displayName : binding.name
                let actionTitle = "Insert \(label)"
                let insertItem = NSMenuItem(
                    title: actionTitle,
                    action: #selector(insertShortcutBinding(_:)),
                    keyEquivalent: ""
                )
                insertItem.target = self
                insertItem.tag = idx
                insertItem.attributedTitle = createActionAttributedTitle(
                    action: actionTitle,
                    shortcut: binding.hotKey.glyphString
                )
                insertItem.toolTip = formatter.string(binding: binding)
                menu.addItem(insertItem)
            }
        }

        menu.addItem(.separator())

        // 2. Section: Quick Formats
        let formatHeader = NSMenuItem(title: "QUICK FORMATS", action: nil, keyEquivalent: "")
        formatHeader.isEnabled = false
        menu.addItem(formatHeader)

        for def in FormatDefinition.quickMenu {
            let item = NSMenuItem(
                title: def.label,
                action: #selector(selectFormat(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = def.type.rawValue
            item.state = (SettingsStore.activeFormatType == def.type) ? .on : .off
            let sample = formatter.string(type: def.type, useUTC: SettingsStore.useUTCTime)
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
        customItem.toolTip = formatter.string(type: .custom, useUTC: SettingsStore.useUTCTime)
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
        let sample = formatter.string(type: def.type, useUTC: SettingsStore.useUTCTime)
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
            inserter.insertTimestamp(type: type, useUTC: SettingsStore.useUTCTime)
        }
    }

    @objc private func selectCustomFormat() {
        SettingsStore.activeFormatType = .custom
        inserter.insertTimestamp(type: .custom, useUTC: SettingsStore.useUTCTime, customFormat: SettingsStore.customFormat)
    }

    @objc private func insertTimestampNow() {
        inserter.insertTimestamp()
    }

    @objc private func insertShortcutBinding(_ sender: NSMenuItem) {
        let bindings = SettingsStore.bindings.filter { $0.isEnabled }
        guard sender.tag < bindings.count else {
            inserter.insertTimestamp()
            return
        }
        let binding = bindings[sender.tag]
        inserter.insertTimestamp(for: binding)
    }

    @objc private func toggleUseUTCTime(_ sender: NSMenuItem) {
        SettingsStore.useUTCTime.toggle()
    }

    private func installHotKeys() {
        let controller = hotKeyController ?? HotKeyController { [weak self] binding in
            self?.inserter.insertTimestamp(for: binding)
        }
        controller.register(bindings: SettingsStore.bindings)
        hotKeyController = controller
    }

    @objc private func openSettings() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController { [weak self] in
                self?.installHotKeys()
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
