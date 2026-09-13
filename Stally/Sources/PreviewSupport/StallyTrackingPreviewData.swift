#if DEBUG
import Foundation
import SwiftData

@MainActor
enum StallyTrackingPreviewData {
    static func seed(in context: ModelContext) throws {
        let now = Date()
        guard let today = LocalDay(containing: now, in: StallyPreviewData.timeZone) else {
            throw CocoaError(.coderInvalidValue)
        }
        let seeds = [
            (name: "Home", start: "2020", archived: false),
            (name: "Window Plant", start: "2020-09", archived: false),
            (name: "Archived Plant", start: "2020-09-13", archived: true)
        ]
        for seed in seeds {
            guard let start = ItemStart(rawValue: seed.start) else {
                throw CocoaError(.coderInvalidValue)
            }
            let item = try ItemOperations.create(
                context: context,
                input: .init(name: seed.name, category: .other),
                tracking: .init(recordsMarks: false, start: start),
                today: today
            )
            if seed.archived {
                try ItemOperations.archive(item, on: now, context: context)
            }
        }
    }
}
#endif
