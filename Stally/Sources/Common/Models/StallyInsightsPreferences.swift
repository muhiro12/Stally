import MHPreferences
import StallyLibrary

nonisolated struct StallyInsightsPreferences: Codable, Equatable, Sendable {
    static let preferenceKey = MHCodablePreferenceKey<Self>(
        namespace: "com.muhiro12.stally.insights",
        name: "preferences"
    )

    var defaultRange: ItemInsightsRange
    var includesArchivedItems: Bool

    init(
        defaultRange: ItemInsightsRange = .last30Days,
        includesArchivedItems: Bool = true
    ) {
        self.defaultRange = defaultRange
        self.includesArchivedItems = includesArchivedItems
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
