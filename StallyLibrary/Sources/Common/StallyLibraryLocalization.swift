import Foundation

enum StallyLibraryLocalization {
    nonisolated static func string(
        _ key: String
    ) -> String {
        Bundle.module.localizedString(
            forKey: key,
            value: key,
            table: "Localizable"
        )
    }

    nonisolated static func format(
        _ key: String,
        _ arguments: CVarArg...
    ) -> String {
        String(
            format: string(key),
            locale: .autoupdatingCurrent,
            arguments: arguments
        )
    }
}
