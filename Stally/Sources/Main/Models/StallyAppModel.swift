import Foundation
import MHPlatform
import Observation

@MainActor
@Observable
final class StallyAppModel {
    enum Tab: String, CaseIterable, Hashable, Identifiable {
        case library
        case review
        case insights
        case archive

        var id: String {
            rawValue
        }

        var title: String {
            switch self {
            case .library:
                "Library"
            case .review:
                "Review"
            case .insights:
                "Insights"
            case .archive:
                "Archive"
            }
        }

        var symbolName: String {
            switch self {
            case .library:
                "square.grid.2x2.fill"
            case .review:
                "checklist"
            case .insights:
                "chart.xyaxis.line"
            case .archive:
                "archivebox.fill"
            }
        }
    }

    enum StackDestination: Hashable {
        case item(UUID)
        case settings
        case backup
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

    var selectedTab: Tab = .library
    var libraryPath: [StackDestination] = []
    var reviewPath: [StackDestination] = []
    var insightsPath: [StackDestination] = []
    var archivePath: [StackDestination] = []
    var editorRoute: EditorRoute?
    var operationErrorMessage: String?
    var reviewPreferences = StallyReviewPreferences()
    var insightsPreferences = StallyInsightsPreferences()

    private var hasLoadedReviewPreferences = false
    private var hasLoadedInsightsPreferences = false

    var currentPath: [StackDestination] {
        get {
            path(for: selectedTab)
        }
        set {
            replacePath(newValue, for: selectedTab)
        }
    }

    func path(
        for tab: Tab
    ) -> [StackDestination] {
        switch tab {
        case .library:
            libraryPath
        case .review:
            reviewPath
        case .insights:
            insightsPath
        case .archive:
            archivePath
        }
    }

    func replacePath(
        _ newValue: [StackDestination],
        for tab: Tab
    ) {
        switch tab {
        case .library:
            libraryPath = newValue
        case .review:
            reviewPath = newValue
        case .insights:
            insightsPath = newValue
        case .archive:
            archivePath = newValue
        }
    }

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

    func resetNavigation(
        selecting tab: Tab = .library
    ) {
        selectedTab = tab
        libraryPath = []
        reviewPath = []
        insightsPath = []
        archivePath = []
    }

    func show(
        tab: Tab,
        path: [StackDestination]
    ) {
        resetNavigation(selecting: tab)
        replacePath(path, for: tab)
    }

    func openItem(
        _ itemID: UUID,
        in tab: Tab? = nil
    ) {
        let hostTab = tab ?? selectedTab
        selectedTab = hostTab
        append(.item(itemID), to: hostTab)
    }

    func openSettings(
        in tab: Tab? = nil
    ) {
        let hostTab = tab ?? selectedTab
        selectedTab = hostTab
        append(.settings, to: hostTab)
    }

    func openBackup(
        in tab: Tab? = nil
    ) {
        let hostTab = tab ?? selectedTab
        selectedTab = hostTab

        var path = path(for: hostTab)

        if !path.contains(.settings) {
            path.append(.settings)
        }

        if path.last != .backup {
            path.append(.backup)
        }

        replacePath(path, for: hostTab)
    }

    func removeItemDestination(
        _ itemID: UUID
    ) {
        for tab in Tab.allCases {
            replacePath(
                path(for: tab).filter { destination in
                    if case .item(let pathItemID) = destination {
                        return pathItemID != itemID
                    }

                    return true
                },
                for: tab
            )
        }
    }

    func performAction(
        _ operation: () throws -> Void
    ) {
        do {
            try operation()
        } catch {
            presentOperationError(error)
        }
    }

    func performBooleanAction(
        _ operation: () throws -> Bool
    ) -> Bool {
        do {
            return try operation()
        } catch {
            presentOperationError(error)
            return false
        }
    }
}

private extension StallyAppModel {
    func append(
        _ destination: StackDestination,
        to tab: Tab
    ) {
        var path = path(for: tab)

        if path.last != destination {
            path.append(destination)
        }

        replacePath(path, for: tab)
    }
}
