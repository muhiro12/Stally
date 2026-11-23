import Foundation

enum RecordSessionError: LocalizedError {
    case accountChanged

    var errorDescription: String? {
        String(localized: "The iCloud account changed. Reopen the record or review before saving.", bundle: .module)
    }
}
