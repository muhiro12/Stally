import Foundation
import SwiftUI
import TipKit

enum StallyTips {
    struct AddFirstItemTip: Tip {
        var title: Text {
            Text("Begin with one item")
        }

        var message: Text? {
            Text("Add something you genuinely reach for, then mark it on the days you choose it.")
        }

        var image: Image? {
            Image(systemName: "plus.circle")
        }

        var options: [any TipOption] {
            MaxDisplayCount(1)
        }
    }

    struct OpenReviewTip: Tip {
        var title: Text {
            Text("Open Review when the list starts to drift")
        }

        var message: Text? {
            Text(
                "Review gathers items that still need a first mark, feel dormant, or may deserve a return from Archive."
            )
        }

        var image: Image? {
            Image(systemName: "rectangle.stack.badge.person.crop")
        }

        var options: [any TipOption] {
            MaxDisplayCount(1)
        }
    }

    struct ReviewBulkSelectTip: Tip {
        var title: Text {
            Text("Handle one lane together")
        }

        var message: Text? {
            Text("Use Select when several items in the same lane are ready for the same next step.")
        }

        var image: Image? {
            Image(systemName: "checklist")
        }

        var options: [any TipOption] {
            MaxDisplayCount(1)
        }
    }

    struct InsightsRangeTip: Tip {
        var title: Text {
            Text("Change the reading window first")
        }

        var message: Text? {
            Text("Switch the range here when you want the metrics to reflect a shorter or longer stretch of time.")
        }

        var image: Image? {
            Image(systemName: "calendar")
        }

        var options: [any TipOption] {
            MaxDisplayCount(1)
        }
    }

    struct AdjustHistoryTip: Tip {
        var title: Text {
            Text("Adjust a past day carefully")
        }

        var message: Text? {
            Text("Open another day when you need to correct history without changing the rest of the item.")
        }

        var image: Image? {
            Image(systemName: "calendar.badge.clock")
        }

        var options: [any TipOption] {
            MaxDisplayCount(1)
        }
    }

    struct BackupSafetyTip: Tip {
        var title: Text {
            Text("Export before higher-risk changes")
        }

        var message: Text? {
            Text("Keep a recent backup close before you replace the library or test a restore.")
        }

        var image: Image? {
            Image(systemName: "externaldrive.badge.icloud")
        }

        var options: [any TipOption] {
            MaxDisplayCount(1)
        }
    }
}

extension StallyTips {
    static var configurationOptions: [Tips.ConfigurationOption] {
        [
            .displayFrequency(.immediate)
        ]
    }

    static func configure() throws {
        do {
            try Tips.configure(configurationOptions)
        } catch {
            throw RuntimeError.configurationFailed
        }
    }

    static func reset() throws {
        do {
            try Tips.resetDatastore()
            try Tips.configure(configurationOptions)
        } catch {
            throw RuntimeError.resetFailed
        }
    }
}

private extension StallyTips {
    enum RuntimeError: LocalizedError {
        case configurationFailed
        case resetFailed

        var errorDescription: String? {
            switch self {
            case .configurationFailed:
                StallyLocalization.string(
                    "Stally couldn't prepare the guidance tips."
                )
            case .resetFailed:
                StallyLocalization.string(
                    "Stally couldn't show the guidance tips again."
                )
            }
        }
    }
}
