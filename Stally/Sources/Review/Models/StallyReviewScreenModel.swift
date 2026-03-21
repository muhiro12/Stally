import Foundation
import Observation
import StallyLibrary

@Observable
final class StallyReviewScreenModel {
    enum SelectionTipLane {
        case untouched
        case dormant
        case recovery
    }

    var selectionState = StallyReviewSelectionState()
    private(set) var snapshot: StallyReviewSnapshot
    private(set) var showsCompletedSections: Bool

    var shouldShowUntouchedSection: Bool {
        showsCompletedSections || !snapshot.untouchedItems.isEmpty
    }

    var shouldShowDormantSection: Bool {
        showsCompletedSections || !snapshot.dormantItems.isEmpty
    }

    var shouldShowRecoverySection: Bool {
        showsCompletedSections || !snapshot.recoveryCandidateItems.isEmpty
    }

    var selectionTipLane: SelectionTipLane? {
        if shouldShowUntouchedSection, snapshot.untouchedItems.count >= 2 {
            return .untouched
        }

        if shouldShowDormantSection, snapshot.dormantItems.count >= 2 {
            return .dormant
        }

        if shouldShowRecoverySection, snapshot.recoveryCandidateItems.count >= 2 {
            return .recovery
        }

        return nil
    }

    var summaryMetrics: [StallyMetricGrid.Metric] {
        [
            .init(
                title: StallyLocalization.string("First Mark"),
                value: "\(snapshot.summary.untouchedCount)"
            ),
            .init(
                title: StallyLocalization.string("Dormant"),
                value: "\(snapshot.summary.dormantCount)"
            ),
            .init(
                title: StallyLocalization.string("Recovery"),
                value: "\(snapshot.summary.recoveryCandidateCount)"
            ),
        ]
    }

    var snapshotsByID: [UUID: ItemReviewSnapshot] {
        snapshot.snapshotsByID
    }

    var untouchedItems: [Item] {
        snapshot.untouchedItems
    }

    var dormantItems: [Item] {
        snapshot.dormantItems
    }

    var recoveryCandidateItems: [Item] {
        snapshot.recoveryCandidateItems
    }

    init(
        snapshot: StallyReviewSnapshot,
        showsCompletedSections: Bool
    ) {
        self.snapshot = snapshot
        self.showsCompletedSections = showsCompletedSections
    }

    func update(
        snapshot: StallyReviewSnapshot,
        showsCompletedSections: Bool
    ) {
        self.snapshot = snapshot
        self.showsCompletedSections = showsCompletedSections
        trimSelection()
    }
}

private extension StallyReviewScreenModel {
    func trimSelection() {
        selectionState.untouched.selectedItemIDs.formIntersection(
            Set(snapshot.untouchedItems.map(\.id))
        )
        selectionState.dormant.selectedItemIDs.formIntersection(
            Set(snapshot.dormantItems.map(\.id))
        )
        selectionState.recovery.selectedItemIDs.formIntersection(
            Set(snapshot.recoveryCandidateItems.map(\.id))
        )
    }
}
