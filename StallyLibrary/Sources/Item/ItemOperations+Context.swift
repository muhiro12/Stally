import Foundation

public extension ItemOperations {
    /// Captures context for native secondary actions; mutations recheck current models.
    static func contextSnapshot(for item: Item, today: LocalDay, locale: Locale = .current) -> ItemContextSnapshot {
        let timeReport: String?
        switch ItemTimeOperations.snapshot(for: item, today: today) {
        case .unknown, .invalidStart:
            timeReport = nil
        case .notStarted, .elapsed:
            timeReport = ItemTimeOperations.report(for: item, today: today, locale: locale)
        }
        return .init(
            itemID: item.uuid,
            name: item.name,
            capabilities: capabilities(for: item),
            isMarkedToday: isMarked(item, on: today),
            timeReport: timeReport
        )
    }
}
