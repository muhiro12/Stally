import Foundation
import MHPlatform

enum StallyRemoteUpdateConfiguration {
    static let configurationURL = URL(
        string: "https://raw.githubusercontent.com/muhiro12/MHAppConfig/main/stally/app.json"
    )
    static let appStoreID = 6_760_996_986
    static let appStoreURL = URL(string: "https://apps.apple.com/app/id6760996986")

    @MainActor
    static func makeOperations(platformMode: StallyPlatformMode) -> RemoteUpdateOperations {
        if isPreview(platformMode: platformMode) {
            #if DEBUG
            if CommandLine.arguments.contains("--stally-preview-update-required") {
                return StallyRemoteUpdatePreview.makeOperations()
            }
            #endif
            return .init()
        }
        guard let configurationURL else {
            return .init(configurationError: MHRemoteUpdateController.Failure.invalidConfiguration)
        }
        do {
            return .init(controller: try .init(appStoreID: appStoreID, configurationURL: configurationURL))
        } catch {
            return .init(configurationError: error)
        }
    }

    private static func isPreview(platformMode: StallyPlatformMode) -> Bool {
        if case .preview = platformMode {
            return true
        }
        #if DEBUG
        return StallyPreviewLaunchConfiguration.current.usesPreviewData
        #else
        return false
        #endif
    }

    @MainActor
    static func prepare(_ updates: RemoteUpdateOperations, logging: MHLoggingBootstrap) async {
        guard updates.isEnabled else {
            return
        }
        let logger = StallyLogging.logger(logging: logging, category: "RemoteUpdate", source: #fileID)
        do {
            let preparation = try await updates.prepare()
            if let error = preparation?.restorationError {
                logger.warning("remote_update.restore_failed", metadata: StallyLogging.errorMetadata(error))
            }
            if let error = preparation?.refreshError {
                logger.warning("remote_update.refresh_failed", metadata: StallyLogging.errorMetadata(error))
            }
            logger.notice("remote_update.evaluated", metadata: StallyLogging.metadata(
                ("reason", updates.evaluation?.reason.rawValue),
                ("revision", updates.evaluation?.revision.map(String.init))
            ))
        } catch is CancellationError {
            return
        } catch {
            logger.error("remote_update.prepare_failed", metadata: StallyLogging.errorMetadata(error))
        }
    }
}
