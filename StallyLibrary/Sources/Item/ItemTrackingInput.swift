/// Explicit tracking edits; nil start means the person chose to clear the start.
public struct ItemTrackingInput: Equatable, Sendable {
    public let recordsMarks: Bool
    public let start: ItemStart?

    public init(recordsMarks: Bool, start: ItemStart?) {
        self.recordsMarks = recordsMarks
        self.start = start
    }
}
