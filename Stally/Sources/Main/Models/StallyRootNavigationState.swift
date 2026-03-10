import Foundation
import MHPreferences
import Observation

@MainActor
@Observable
final class StallyRootNavigationState {
    enum Route: Hashable {
        case archive
        case backup
        case insights
        case item(UUID)
        case review
        case settings
    }

    enum EditorMode: Hashable {
        case create
        case edit(UUID)
    }

    struct EditorRoute: Hashable, Identifiable {
        let mode: EditorMode

        var id: String {
            switch mode {
            case .create:
                "create"
            case .edit(let itemID):
                "edit-\(itemID.uuidString)"
            }
        }
    }

    var path: [Route] = []
    var editorRoute: EditorRoute?
    var operationErrorMessage: String?
    var reviewPreferences = StallyReviewPreferences()
    var insightsPreferences = StallyInsightsPreferences()
    private var hasLoadedReviewPreferences = false
    private var hasLoadedInsightsPreferences = false

    func dismissEditor() {
        editorRoute = nil
    }

    func dismissOperationError() {
        operationErrorMessage = nil
    }

    func presentCreateEditor() {
        editorRoute = .init(mode: .create)
    }

    func presentEditEditor(
        _ itemID: UUID
    ) {
        editorRoute = .init(mode: .edit(itemID))
    }

    func presentOperationError(
        _ error: any Error
    ) {
        operationErrorMessage = (error as? LocalizedError)?.errorDescription
            ?? StallyLocalization.string("Please try again.")
    }

    func presentUnsupportedDeepLinkError() {
        operationErrorMessage = StallyLocalization.string(
            "This link isn't supported by this version of Stally."
        )
    }

    func loadReviewPreferencesIfNeeded(
        from store: MHPreferenceStore
    ) {
        guard hasLoadedReviewPreferences == false else {
            return
        }

        reviewPreferences = StallyReviewPreferences.load(
            from: store
        )
        hasLoadedReviewPreferences = true
    }

    func loadInsightsPreferencesIfNeeded(
        from store: MHPreferenceStore
    ) {
        guard hasLoadedInsightsPreferences == false else {
            return
        }

        insightsPreferences = StallyInsightsPreferences.load(
            from: store
        )
        hasLoadedInsightsPreferences = true
    }

    func removeItemRoute(
        _ itemID: UUID
    ) {
        path.removeAll { route in
            if case .item(let pathItemID) = route {
                return pathItemID == itemID
            }

            return false
        }
    }
}
