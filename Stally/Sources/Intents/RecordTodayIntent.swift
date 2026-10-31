import AppIntents
import Foundation
import StallyLibrary
import SwiftData

struct RecordTodayIntent: AppIntent {
    static let title: LocalizedStringResource = "Record Today"
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes { .background }
    static var parameterSummary: some ParameterSummary {
        Summary("Record Today") {
            \.$item
        }
    }

    @Dependency private var container: ModelContainer
    @Dependency private var updates: RemoteUpdateOperations
    @Parameter(title: "Item")
    var item: ItemEntity

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<MarkEntity> {
        let value = try await IntentAccess.write(container: container, updates: updates) { context in
            let record = try ItemOperations.item(context: context, uuid: item.id)
            let mark = try MarkOperations.add(
                to: record,
                localDateTime: MarkOperations.localDateTime(at: .now, includesTime: false),
                context: context
            )
            return MarkEntity(mark)
        }
        return .result(value: value)
    }
}
