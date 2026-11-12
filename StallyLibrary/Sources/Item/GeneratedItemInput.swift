import FoundationModels

@Generable
struct GeneratedItemInput {
    @Guide(description: "A concise name copied exactly from the source; empty if no single Item is identifiable.")
    var name: String
    @Guide(description: "Descriptive context copied as one exact excerpt, without labels; empty if absent.")
    var note: String
    @Guide(description: "One complete website or app URL copied exactly from the source; empty if absent.")
    var representativeURL: String
}
