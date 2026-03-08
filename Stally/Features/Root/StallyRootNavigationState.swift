import Foundation
import MHPlatform

struct StallyRootNavigationState {
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

    mutating func dismissEditor() {
        editorRoute = nil
    }

    mutating func dismissOperationError() {
        operationErrorMessage = nil
    }

    mutating func presentCreateEditor() {
        editorRoute = .init(mode: .create)
    }

    mutating func presentEditEditor(
        _ itemID: UUID
    ) {
        editorRoute = .init(mode: .edit(itemID))
    }

    mutating func presentOperationError(
        _ error: any Error
    ) {
        operationErrorMessage = (error as? LocalizedError)?.errorDescription
            ?? "Please try again."
    }

    mutating func presentUnsupportedDeepLinkError() {
        operationErrorMessage = "This link isn't supported by this version of Stally."
    }

    mutating func loadReviewPreferencesIfNeeded(
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

    mutating func loadInsightsPreferencesIfNeeded(
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

    mutating func removeItemRoute(
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
