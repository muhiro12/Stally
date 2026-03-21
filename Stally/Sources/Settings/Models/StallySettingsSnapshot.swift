import Foundation
import StallyLibrary

// swiftlint:disable file_types_order one_declaration_per_file function_body_length
struct StallySettingsSnapshot {
    struct DeepLinkRow: Identifiable {
        let id: String
        let title: String
        let route: StallyRoute
        let supporting: String
    }

    let appVersion: String
    let buildNumber: String
    let deepLinkRows: [DeepLinkRow]

    var syncKey: String {
        [
            appVersion,
            buildNumber,
            deepLinkRows.map(\.id).joined(separator: ","),
        ].joined(separator: "#")
    }
}

enum StallySettingsSnapshotBuilder {
    static func build() -> StallySettingsSnapshot {
        .init(
            appVersion: Bundle.main.object(
                forInfoDictionaryKey: "CFBundleShortVersionString"
            ) as? String ?? StallyLocalization.string("Unknown"),
            buildNumber: Bundle.main.object(
                forInfoDictionaryKey: kCFBundleVersionKey as String
            ) as? String ?? StallyLocalization.string("Unknown"),
            deepLinkRows: [
                .init(
                    id: "home",
                    title: StallyLocalization.string("Library"),
                    route: .home,
                    supporting: StallyLocalization.string("Open the main collection view.")
                ),
                .init(
                    id: "archive",
                    title: StallyLocalization.string("Archive"),
                    route: .archive,
                    supporting: StallyLocalization.string("Jump straight to archived items.")
                ),
                .init(
                    id: "backup",
                    title: StallyLocalization.string("Backup Center"),
                    route: .backup,
                    supporting: StallyLocalization.string("Open backup and restore tools.")
                ),
                .init(
                    id: "insights",
                    title: StallyLocalization.string("Insights"),
                    route: .insights,
                    supporting: StallyLocalization.string("Open collection analytics and reports.")
                ),
                .init(
                    id: "review",
                    title: StallyLocalization.string("Review"),
                    route: .review,
                    supporting: StallyLocalization.string("Open the review workflow.")
                ),
                .init(
                    id: "createItem",
                    title: StallyLocalization.string("Create Item"),
                    route: .createItem,
                    supporting: StallyLocalization.string("Start a new item from a link.")
                ),
                .init(
                    id: "settings",
                    title: StallyLocalization.string("Settings"),
                    route: .settings,
                    supporting: StallyLocalization.string("Open Settings directly.")
                )
            ]
        )
    }
}
// swiftlint:enable file_types_order one_declaration_per_file function_body_length
