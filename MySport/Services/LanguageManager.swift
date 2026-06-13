import SwiftUI

enum AppLanguage: String, CaseIterable {
    case ukrainian = "uk"
    case english   = "en"

    var displayName: String {
        switch self {
        case .ukrainian: return "Українська 🇺🇦"
        case .english:   return "English 🇬🇧"
        }
    }
}

// Reads directly from UserDefaults — no actor isolation, no singleton.
// Views force a full rebuild via .id(appLanguage) when the stored value changes.
func t(_ key: LocalizationKey) -> String {
    let saved = UserDefaults.standard.string(forKey: "appLanguage") ?? "uk"
    return saved == AppLanguage.english.rawValue ? key.en : key.uk
}
