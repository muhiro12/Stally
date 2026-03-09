import Foundation

enum StallyLibraryLocalization {
    nonisolated static func string(
        _ key: String
    ) -> String {
        NSLocalizedString(
            key,
            tableName: "Localizable",
            bundle: .module,
            value: key,
            comment: ""
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
