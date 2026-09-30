#if DEBUG
import Foundation

/// Stable semantic identity for selecting synthetic records across locales.
public enum StallyFixtureItem: UInt16, CaseIterable, Sendable {
    case blackWoolCoat = 1
    case whiteEverydaySneakers
    case canvasTote
    case dailyFieldNotes
    case travelWeekender
    case longNameSweater
    case smallNotebook
    case rainShell
    case cardCase
    case winterScarf
    case home
    case windowPlant
    case archivedPlant

    public var id: UUID {
        StallyFixtureOperations.identifier(item: rawValue, mark: 0)
    }
}
#endif
