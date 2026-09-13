import Foundation

enum ItemTrackingFormError: LocalizedError {
    case invalidDate

    var errorDescription: String? {
        String(localized: "Choose a valid year, month, and day for the selected precision.")
    }
}
