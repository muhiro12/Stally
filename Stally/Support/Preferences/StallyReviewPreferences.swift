import MHPlatform
import StallyLibrary

nonisolated struct StallyReviewPreferences: Codable, Equatable, Sendable {
    static let preferenceKey = MHCodablePreferenceKey<StallyReviewPreferences>(
        namespace: "com.muhiro12.stally.review",
        name: "preferences"
    )

    var untouchedGraceDays: Int
    var dormantAfterDays: Int
    var showCompletedSections: Bool

    init(
        untouchedGraceDays: Int = 14,
        dormantAfterDays: Int = 30,
        showCompletedSections: Bool = false
    ) {
        self.untouchedGraceDays = max(1, untouchedGraceDays)
        self.dormantAfterDays = max(1, dormantAfterDays)
        self.showCompletedSections = showCompletedSections
    }

    var policy: ItemReviewPolicy {
        .init(
            untouchedGraceDays: untouchedGraceDays,
            dormantAfterDays: dormantAfterDays
        )
    }

    static func load(
        from store: MHPreferenceStore
    ) -> Self {
        store.codable(for: preferenceKey) ?? .init()
    }

    func save(
        in store: MHPreferenceStore
    ) {
        store.setCodable(self, for: Self.preferenceKey)
    }
}
