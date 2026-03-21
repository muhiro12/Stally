import Foundation
import Observation

@Observable
final class StallySettingsScreenModel {
    struct BuildCard: Identifiable, Hashable {
        let title: String
        let value: String

        var id: String {
            title
        }
    }

    private(set) var snapshot: StallySettingsSnapshot

    var buildCards: [BuildCard] {
        [
            .init(title: "Version", value: snapshot.appVersion),
            .init(title: "Build", value: snapshot.buildNumber),
        ]
    }

    var deepLinkRows: [StallySettingsSnapshot.DeepLinkRow] {
        snapshot.deepLinkRows
    }

    init(
        snapshot: StallySettingsSnapshot
    ) {
        self.snapshot = snapshot
    }

    func update(
        snapshot: StallySettingsSnapshot
    ) {
        self.snapshot = snapshot
    }
}
