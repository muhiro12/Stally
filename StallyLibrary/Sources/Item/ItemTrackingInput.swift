/// Explicit tracking edits; nil start means the person chose to clear the start.
public struct ItemTrackingInput: Equatable, Sendable {
    public let markPolicy: ItemMarkPolicy
    public let start: ItemStart?

    public var recordsMarks: Bool {
        markPolicy.recordsMarks
    }

    public init(markPolicy: ItemMarkPolicy, start: ItemStart?) {
        self.markPolicy = markPolicy
        self.start = start
    }

    public init(recordsMarks: Bool, start: ItemStart?) {
        self.init(markPolicy: .init(recordsMarks: recordsMarks), start: start)
    }
}
