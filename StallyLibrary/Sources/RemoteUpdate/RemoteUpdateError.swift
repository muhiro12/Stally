import Foundation

/// A confirmed published update prevents a requested write.
public enum RemoteUpdateError: LocalizedError, CustomLocalizedStringResourceConvertible, Equatable {
    case updateRequired

    public var errorDescription: String? {
        String(localized: localizedStringResource)
    }

    public var localizedStringResource: LocalizedStringResource {
        .init("Update Stally to continue.", table: "RemoteUpdate", bundle: #bundle)
    }
}
