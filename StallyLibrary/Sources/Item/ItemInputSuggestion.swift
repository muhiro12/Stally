import Foundation

/// Unsaved text and period candidates extracted from one description. No history is saved automatically.
public struct ItemInputSuggestion: Equatable, Sendable {
    public var name: String
    public var note: String
    public var representativeURL: String
    public var periods: [ItemPeriodSuggestion]

    public init(
        name: String = "", note: String = "", representativeURL: String = "", periods: [ItemPeriodSuggestion] = []
    ) {
        self.name = name
        self.note = note
        self.representativeURL = representativeURL
        self.periods = periods
    }
}
