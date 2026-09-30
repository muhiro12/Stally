import Foundation

public extension ReviewOperations {
    /// Captures lane identities using the same authoritative reading as the app.
    /// Consumers resolve IDs in their own context and recheck eligibility before writing.
    static func identifiersSnapshot(
        for items: [Item],
        settings: ReviewSettings = .default,
        timeZone: TimeZone = .current,
        now: Date = .now
    ) -> ReviewIdentifiersSnapshot {
        .init(snapshot: snapshot(for: items, settings: settings, timeZone: timeZone, now: now))
    }
}
