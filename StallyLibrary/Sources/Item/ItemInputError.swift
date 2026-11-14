import Foundation

public enum ItemInputError: LocalizedError, Equatable {
    case emptyInput
    case inputTooLong
    case deviceNotEligible
    case intelligenceNotEnabled
    case modelNotReady
    case unavailable
    case unsupportedLanguage
    case rejectedInput
    case invalidResult
    case generationFailed

    public var errorDescription: String? {
        switch self {
        case .emptyInput:
            String(
                localized: "Enter a description of one Item.",
                bundle: .module
            )
        case .inputTooLong:
            String(
                localized: "Use a shorter description, up to 4,000 characters.",
                bundle: .module
            )
        case .deviceNotEligible:
            String(
                localized: "Input assistance requires a device that supports Apple Intelligence.",
                bundle: .module
            )
        case .intelligenceNotEnabled:
            String(
                localized: "Turn on Apple Intelligence in Settings to use input assistance.",
                bundle: .module
            )
        case .modelNotReady:
            String(
                localized: "Apple Intelligence is still preparing. Try again later.",
                bundle: .module
            )
        case .unavailable:
            String(
                localized: "Input assistance is currently unavailable. You can enter the Item manually.",
                bundle: .module
            )
        case .unsupportedLanguage:
            String(
                localized: "Apple Intelligence does not support this language for input assistance.",
                bundle: .module
            )
        case .rejectedInput:
            String(
                localized: "This description could not be processed. Try different wording or enter the Item manually.",
                bundle: .module
            )
        case .invalidResult:
            String(
                localized: "No reliable Item suggestion was found. Describe one Item more clearly and try again.",
                bundle: .module
            )
        case .generationFailed:
            String(
                localized: "Could not prepare a suggestion. Try again or enter the Item manually.",
                bundle: .module
            )
        }
    }
}
