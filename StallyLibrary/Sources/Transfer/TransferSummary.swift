import Foundation

/// Localized values for a review; registration metadata is visible but never selects a winner.
enum TransferSummary {
    static func item(_ item: TransferItem, tags: [TransferTag]) -> String {
        let tagNames = tags.filter { item.tagUUIDs.contains($0.uuid) }.map(\.name).joined(separator: ", ")
        let placement =
            item.isArchived
            ? String(localized: "Archived", bundle: .module)
            : String(localized: "In Library", bundle: .module)
        let favorite =
            item.isFavorite
            ? String(localized: "Favorite", bundle: .module)
            : String(localized: "Not a Favorite", bundle: .module)
        let recording =
            item.isMarkRecordingEnabled
            ? String(localized: "Recording Enabled", bundle: .module)
            : String(localized: "Recording Paused", bundle: .module)
        return [
            item.name, item.note, item.representativeURL ?? "—", tagNames, placement, favorite, recording,
            registered(item.createdAt)
        ].joined(separator: "\n")
    }

    static func mark(_ mark: TransferMark) -> String {
        [mark.localDateTime, registered(mark.createdAt)].joined(separator: "\n")
    }

    static func period(_ period: TransferPeriod) -> String {
        let unknown = String(localized: "Unknown", bundle: .module)
        let end = period.isOngoing ? String(localized: "Ongoing", bundle: .module) : period.endLocalDate ?? unknown
        return ["\(period.startLocalDate ?? unknown) → \(end)", registered(period.createdAt)].joined(separator: "\n")
    }

    static func photo(_ photo: TransferPhoto) -> String {
        let availability =
            photo.image.state == .included
            ? String(localized: "Image Included", bundle: .module)
            : String(localized: "No Image Supplied; Keep Any Local Image", bundle: .module)
        return [
            photo.caption, String(localized: "Position: \(UInt(photo.sortOrder) + 1)", bundle: .module),
            availability, registered(photo.createdAt)
        ].joined(separator: "\n")
    }

    private static func registered(_ date: Date) -> String {
        String(localized: "Registered: \(date.formatted(date: .numeric, time: .standard))", bundle: .module)
    }
}
