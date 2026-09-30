/// Whether an Item participates in daily choice history, independently of its start.
public enum ItemMarkPolicy: String, CaseIterable, Codable, Sendable {
    case enabled
    case disabled

    /// The scalar representation used by the current persisted and portable contract.
    public var recordsMarks: Bool {
        self == .enabled
    }

    public init(recordsMarks: Bool) {
        self = recordsMarks ? .enabled : .disabled
    }
}
