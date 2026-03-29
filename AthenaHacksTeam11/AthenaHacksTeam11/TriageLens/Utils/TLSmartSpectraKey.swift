import Foundation

enum TLSmartSpectraKey {
    static func load() -> (value: String?, sourceLabel: String) {
        let envKeys = ["SMARTSPECTRA_API_KEY", "API_Key", "API_KEY"]
        for keyName in envKeys {
            if let raw = ProcessInfo.processInfo.environment[keyName] {
                let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
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

