import Foundation
import StallyLibrary

struct StallyHomeActions {
    let onOpenItem: (UUID) -> Void
    let onCreateItem: () -> Void
    let onSeedSampleData: () -> Void
    let onOpenArchive: () -> Void
    let onOpenBackup: () -> Void
    let onOpenInsights: () -> Void
    let onOpenReview: () -> Void
    let onOpenSettings: () -> Void
    let onToggleTodayMark: (Item) -> Void

    static let noop = Self(
        onOpenItem: { _ in
            // no-op
        },
        onCreateItem: {
            // no-op
        },
        onSeedSampleData: {
            // no-op
        },
        onOpenArchive: {
            // no-op
        },
        onOpenBackup: {
            // no-op
        },
        onOpenInsights: {
            // no-op
        },
        onOpenReview: {
            // no-op
        },
        onOpenSettings: {
            // no-op
        },
        onToggleTodayMark: { _ in
            // no-op
        }
    )
}
