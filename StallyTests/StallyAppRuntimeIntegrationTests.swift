import MHAppRuntimeCore
import MHDeepLinking
import MHRouteExecution
import SwiftUI
@testable import Stally
@testable import StallyLibrary
import XCTest

final class StallyAppRuntimeIntegrationTests: XCTestCase {
    @MainActor
    func testPreviewAssemblySynchronizesBackupRouteThroughPipeline() async throws {
        let assembly = try StallyAppAssemblyFactory.makePreview(
            seedSampleData: false
        )
        let routeURL = try XCTUnwrap(
            StallyDeepLinking.codec().preferredURL(for: .backup)
        )

        assembly.routeInbox.registerHandler { route in
            StallyAppRouteService.apply(
                route: route,
                to: assembly.appModel,
                items: []
            )
        }
        defer {
            assembly.routeInbox.unregisterHandler()
        }

        await assembly.routePipeline.ingest(routeURL)
        _ = await assembly.routePipeline.synchronizePendingRoutesIfPossible()

        XCTAssertEqual(assembly.appModel.selectedTab, .library)
        XCTAssertEqual(
            assembly.appModel.libraryPath,
            [
                .settings,
                .backup
            ]
        )
        XCTAssertNil(assembly.routePipeline.lastParseFailureURL)
    }
}
