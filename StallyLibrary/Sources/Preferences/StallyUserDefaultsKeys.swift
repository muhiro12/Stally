/// Central catalog of app-owned UserDefaults keys.
public enum StallyUserDefaultsKeys {
    public enum Standard: String, CaseIterable {
        case defaultInsightsRange = "stally.defaultInsightsRange"
        case dormantAfterDays = "stally.dormantAfterDays"
        case includesArchivedItemsInInsights = "stally.includesArchivedItemsInInsights"
        case isSubscribeOn = "stally.isSubscribeOn"
        case isICloudOn = "stally.isICloudOn"
        case needsFirstMarkAfterDays = "stally.needsFirstMarkAfterDays"
        case showsCompletedReviewSections = "stally.showsCompletedReviewSections"
    }
}
