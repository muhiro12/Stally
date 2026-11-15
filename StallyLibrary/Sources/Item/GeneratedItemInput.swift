import FoundationModels

@Generable
struct GeneratedItemInput {
    @Guide(description: """
        The complete identifying name, including brand and model, copied from the source without labels.
        """)
    var name: String
    @Guide(description: """
        The full descriptive passage, including every detail and line break; no summary. Empty if absent.
        """)
    var note: String
    @Guide(description: "A literal URL copied from the source. Empty if absent; never infer a website from a name.")
    var representativeURL: String
}
