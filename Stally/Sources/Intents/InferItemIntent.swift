import AppIntents
import StallyLibrary

struct InferItemIntent: AppIntent {
    static let title: LocalizedStringResource = "Prepare Item from Text"
    static let description = IntentDescription(
        """
        Use on-device Apple Intelligence to extract an Item name, note, and link as readable text. \
        No Item, Mark, or period is saved.
        """
    )
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Prepare Item from \(\.$text)")
    }

    @Parameter(title: "Description")
    var text: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let suggestion = try await ItemInputOperations.infer(text: text)
        return .result(value: ItemInputOperations.text(for: suggestion))
    }
}
