#if DEBUG
// Fixed epoch and UUID namespace bytes are fixture identity constants.
// swiftlint:disable no_magic_numbers
import Foundation
import SwiftData

/// Deterministic, opt-in data for previews, tests, and synthetic launch captures.
public enum StallyFixtureOperations {
    /// September 30, 2026 at noon UTC; never derived from the host clock.
    public static let referenceDate = Date(timeIntervalSince1970: 1_790_769_600)
    /// Calendar-day calculations use UTC in every synthetic consumer.
    public static let timeZone = TimeZone.gmt

    /// Refuses persistent or nonempty containers before changing any records.
    @discardableResult
    public static func seed(
        _ profile: StallyFixtureProfile,
        in context: ModelContext,
        locale: Locale = .init(identifier: "en"),
        photoData: Data? = nil
    ) throws -> [Item] {
        guard context.container.configurations.allSatisfy(\.isStoredInMemoryOnly),
              try ItemOperations.items(context: context).isEmpty else {
            throw CocoaError(.coderInvalidValue)
        }
        let calendar = ItemSeedBuilder.calendar(in: timeZone)
        do {
            let items = try seeds(for: profile, locale: locale, photoData: photoData).map { seed in
                try ItemSeedBuilder.makeItem(
                    from: seed,
                    referenceDate: referenceDate,
                    calendar: calendar,
                    context: context
                ) { offset in
                    markIdentifier(item: seed.uuid, offset: offset)
                }
            }
            try ItemOperations.saveOrRollback(context)
            return items
        } catch {
            context.rollback()
            throw error
        }
    }
}

extension StallyFixtureOperations {
    // A separate namespace keeps user-facing sample removal away from fixtures.
    static func identifier(item: UInt16, mark: UInt16) -> UUID {
        .init(uuid: (
            0x53, 0x54, 0x41, 0x4C, 0x4C, 0x59, 0x44, 0x01,
            0x80, 0x00, 0x00, 0x00,
            UInt8(truncatingIfNeeded: item >> 8), UInt8(truncatingIfNeeded: item),
            UInt8(truncatingIfNeeded: mark >> 8), UInt8(truncatingIfNeeded: mark)
        ))
    }

    private static func markIdentifier(item: UUID, offset: Int) -> UUID {
        let bytes = item.uuid
        let ordinal = (UInt16(bytes.12) << 8) | UInt16(bytes.13)
        return identifier(item: ordinal, mark: UInt16(offset + 1))
    }
}
// swiftlint:enable no_magic_numbers
#endif
