import AppIntents
import StallyLibrary
import SwiftData

struct GetItemContentIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Item Content"
    static let description = IntentDescription(
        "Return the Item's name, note, and link as readable text. Photos, tags, Marks, and periods are not included."
    )
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Get Item Content") {
            \.$item
        }
    }

    @Dependency private var container: ModelContainer
    @Parameter(title: "Item")
    var item: ItemEntity

    @MainActor
    func perform() throws -> some IntentResult & ReturnsValue<String> {
        let text = try IntentAccess.read(container: container) { context in
            let record = try ItemOperations.item(context: context, uuid: item.id)
            return ItemOperations.shareText(for: record)
        }
        return .result(value: text)
    }
}
