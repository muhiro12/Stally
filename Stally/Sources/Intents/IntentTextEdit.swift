import Foundation

enum IntentTextEdit {
    static func value(_ text: String?, clearing: Bool, current: String?) throws -> String? {
        guard let text, !text.isEmpty else {
            return clearing ? nil : current
        }
        guard !clearing else {
            throw StallyIntentError(message: String(localized: "Choose either a replacement value or Clear."))
        }
        return text
    }
}
