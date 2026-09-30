import AppIntents
import SwiftData

struct CreateStallyItemIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Create Item", table: "AppIntents")
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static let description = IntentDescription(
        .init("Create a Stally item without opening the app.", table: "AppIntents")
    )

    static var parameterSummary: some ParameterSummary {
        Summary("Create item \(\.$name)") {
            \.$category
            \.$recordsMarks
            \.$start
            \.$note
        }
    }

    @Parameter(title: .init("Name", table: "AppIntents"))
    private var name: String
    @Parameter(title: .init("Category", table: "AppIntents"), default: .other)
    private var category: StallyItemCategoryIntentValue
    @Parameter(title: .init("Note", table: "AppIntents"))
    private var note: String?
    @Parameter(title: .init("Record Marks", table: "AppIntents"), default: true)
    private var recordsMarks: Bool
    @Parameter(
        title: .init("Start", table: "AppIntents"),
        description: .init("Optional start as YYYY, YYYY-MM, or YYYY-MM-DD.", table: "AppIntents")
    )
    private var start: String?

    @Dependency private var modelContainer: ModelContainer

    @MainActor
    func perform() throws -> some ReturnsValue<StallyItemEntity> & ProvidesDialog {
        guard let today = LocalDay(containing: .now, in: .current) else {
            throw StallyIntentError.currentDayUnavailable
        }
        let knownStart: ItemStart?
        if let start, !start.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            guard let parsed = ItemStart(rawValue: start) else {
                throw StallyIntentError.invalidStartInput
            }
            knownStart = parsed
        } else {
            knownStart = nil
        }
        let model = try ItemOperations.create(
            context: modelContainer.mainContext,
            input: .init(name: name, category: category.itemCategory, note: note ?? ""),
            tracking: .init(recordsMarks: recordsMarks, start: knownStart),
            today: today
        )
        return .result(value: .init(model), dialog: .init(.init("Created item.", table: "AppIntents")))
    }
}
