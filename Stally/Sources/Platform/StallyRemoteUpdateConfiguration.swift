import Foundation
import MHPlatform
import StallyLibrary

enum StallyRemoteUpdateConfiguration {
    private static let appStoreID = 6_760_996_986

    @MainActor
    static func makeOperations() -> RemoteUpdateOperations {
        guard
            let url = URL(
                string: "https://raw.githubusercontent.com/muhiro12/MHAppConfig/main/stally/app.json"
            )
        else {
            return .init(configurationError: MHRemoteUpdateController.Failure.invalidConfiguration)
        }
        do {
            return .init(controller: try .init(appStoreID: appStoreID, configurationURL: url))
        } catch {
            return .init(configurationError: error)
        }
    }
}
