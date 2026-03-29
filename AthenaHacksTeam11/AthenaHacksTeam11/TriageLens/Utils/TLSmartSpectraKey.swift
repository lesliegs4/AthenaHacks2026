import Foundation

enum TLSmartSpectraKey {
    private static let storedKeyName = "SMARTSPECTRA_API_KEY_STORED"

    static func load() -> (value: String?, sourceLabel: String) {
        if let stored = UserDefaults.standard.string(forKey: storedKeyName) {
            let trimmed = stored.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return (trimmed, "Loaded from device storage (len \(trimmed.count))")
            }
        }

        let envKeys = ["SMARTSPECTRA_API_KEY", "API_Key", "API_KEY"]
        for keyName in envKeys {
            if let raw = ProcessInfo.processInfo.environment[keyName] {
                let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    // Running from Xcode often provides the key via Scheme env vars.
                    // Persist it so the app also works when launched normally.
                    UserDefaults.standard.set(trimmed, forKey: storedKeyName)
                    return (trimmed, "Loaded from env: \(keyName) (len \(trimmed.count))")
                }
                return (nil, "Found env var \(keyName) but it’s empty")
            }
        }

        let plistKeys = ["SMARTSPECTRA_API_KEY", "API_Key", "API_KEY"]
        for keyName in plistKeys {
            if let raw = Bundle.main.object(forInfoDictionaryKey: keyName) as? String {
                let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return (trimmed, "Loaded from Info.plist: \(keyName) (len \(trimmed.count))")
                }
                return (nil, "Found Info.plist key \(keyName) but it’s empty")
            }
        }

        return (nil, "Set env \(envKeys.joined(separator: ", ")) or Info.plist \(plistKeys.joined(separator: ", "))")
    }
}

