/// Empty optional text in Shortcuts expresses an unknown period boundary.
enum IntentDateInput {
    static func optional(_ text: String?) -> String? {
        text.flatMap { $0.isEmpty ? nil : $0 }
    }
}
