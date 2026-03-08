import Foundation

/// Derived collection health metrics used by high-level insight surfaces.
public struct CollectionHealthSummary: Equatable, Sendable {
    public let range: ItemInsightsRange
    public let totalItems: Int
    public let activeItems: Int
    public let archivedItems: Int
    public let itemsWithHistory: Int
    public let itemsWithNotes: Int
    public let itemsWithPhotos: Int
    public let historyCoverage: Double
    public let noteCoverage: Double
    public let photoCoverage: Double
    public let archivedShare: Double
    public let averageItemAgeDays: Double
    public let recentlyAddedCount: Int

    public init(
        range: ItemInsightsRange,
        totalItems: Int,
        activeItems: Int,
        archivedItems: Int,
        itemsWithHistory: Int,
        itemsWithNotes: Int,
        itemsWithPhotos: Int,
        historyCoverage: Double,
        noteCoverage: Double,
        photoCoverage: Double,
        archivedShare: Double,
        averageItemAgeDays: Double,
        recentlyAddedCount: Int
    ) {
        self.range = range
        self.totalItems = totalItems
        self.activeItems = activeItems
        self.archivedItems = archivedItems
        self.itemsWithHistory = itemsWithHistory
        self.itemsWithNotes = itemsWithNotes
        self.itemsWithPhotos = itemsWithPhotos
        self.historyCoverage = historyCoverage
        self.noteCoverage = noteCoverage
        self.photoCoverage = photoCoverage
        self.archivedShare = archivedShare
        self.averageItemAgeDays = averageItemAgeDays
        self.recentlyAddedCount = recentlyAddedCount
    }
}
