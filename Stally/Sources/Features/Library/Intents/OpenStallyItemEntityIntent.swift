import AppIntents
import SwiftData

/// The canonical system Open action; the older item-parameter adapter remains valid.
@AppIntent(schema: .system.open)
struct OpenStallyItemEntityIntent: OpenIntent {
    static let title: LocalizedStringResource = .init("Open Item", table: "AppIntents")
    static let supportedModes: IntentModes = .foreground
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresLocalDeviceAuthentication

    var target: StallyItemEntity

    @Dependency private var modelContainer: ModelContainer

    @MainActor
    func perform() async throws -> some IntentResult {
        let model = try target.model(in: modelContainer.mainContext)
        await StallyIntentRouteOpener.store(.item(model.uuid))
        return .result()
    }
}
