import AppIntents
import Foundation

struct StallyIntentError: LocalizedError, CustomLocalizedStringResourceConvertible {
    let message: String

    var errorDescription: String? { message }
    var localizedStringResource: LocalizedStringResource { "\(message)" }
}
