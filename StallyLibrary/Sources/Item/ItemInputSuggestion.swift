import Foundation

/// Unsaved, editable text extracted from one description. No history is inferred.
public struct ItemInputSuggestion: Equatable, Sendable {
    public var name: String
    public var note: String
    public var representativeURL: String

    public init(name: String = "", note: String = "", representativeURL: String = "") {
        self.name = name
        self.note = note
        self.representativeURL = representativeURL
    }
}
