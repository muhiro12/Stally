import Foundation

enum StallyLocalization {
    nonisolated static func string(
        _ key: String
    ) -> String {
        Bundle.main.localizedString(
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
