/// Canonical optional text and explicit partial-edit semantics shared by input surfaces.
public enum TextInput {
    /// Empty input means absence. Nonempty text, including whitespace, is preserved exactly.
    public static func optional(_ text: String?) -> String? {
        text.flatMap { $0.isEmpty ? nil : $0 }
    }

    /// Omission preserves the current value; supplied empty text or Clear removes it.
    /// A nonempty replacement combined with Clear is rejected before mutation.
    public static func edited(_ text: String?, clearing: Bool, current: String?) throws -> String? {
        let replacement = optional(text)
        guard !clearing || replacement == nil else {
            throw RecordError.conflictingTextEdit
        }
        if clearing || text != nil {
            return replacement
        }
        return optional(current)
    }
}
