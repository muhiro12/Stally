import Foundation

enum StallyTransferFailurePhase: String {
    case preflight
    case fileAccess
    case decode
    case mutation
    case followUp
}

// swiftlint:disable:next one_declaration_per_file
struct StallyTransferOperationError: LocalizedError {
    enum Operation: String {
        case export
        case importPreview
        case mergeImport
        case replaceImport
        case deleteAll
    }

    let operation: Operation
    let phase: StallyTransferFailurePhase
    let underlyingError: any Error
    let fallbackDescription: String

    var errorDescription: String? {
        (underlyingError as? LocalizedError)?.errorDescription
            ?? fallbackDescription
    }

    static func wrapping(
        _ error: any Error,
        operation: Operation,
        phase: StallyTransferFailurePhase,
        fallbackDescription: String
    ) -> Self {
        if let transferError = error as? Self {
            return transferError
        }

        return .init(
            operation: operation,
            phase: phase,
            underlyingError: error,
            fallbackDescription: fallbackDescription
        )
    }
}
