import Foundation
@testable import Stally
@testable import StallyLibrary
import XCTest

final class StallyAppRouteServiceTests: XCTestCase {
    func testHomeRouteSelectsLibraryAndClearsNavigation() async {
        await MainActor.run {
            let appModel = StallyAppModel()
            appModel.archivePath = [.settings, .backup]

            StallyAppRouteService.apply(
                route: .home,
                to: appModel,
                items: []
            )

            XCTAssertEqual(appModel.selectedTab, .library)
            XCTAssertTrue(appModel.libraryPath.isEmpty)
            XCTAssertTrue(appModel.archivePath.isEmpty)
        }
    }

    func testArchiveRouteSelectsArchive() async {
        await MainActor.run {
            let appModel = StallyAppModel()

            StallyAppRouteService.apply(
                route: .archive,
                to: appModel,
                items: []
            )

            XCTAssertEqual(appModel.selectedTab, .archive)
            XCTAssertEqual(appModel.archivePath, [])
        }
    }

    func testReviewAndInsightsRoutesSelectMatchingTabs() async {
        await MainActor.run {
            let appModel = StallyAppModel()

            StallyAppRouteService.apply(
                route: .review,
                to: appModel,
                items: []
            )
            XCTAssertEqual(appModel.selectedTab, .review)

            StallyAppRouteService.apply(
                route: .insights,
                to: appModel,
                items: []
            )
            XCTAssertEqual(appModel.selectedTab, .insights)
        }
    }

    func testSettingsRouteShowsSettingsOnLibraryStack() async {
        await MainActor.run {
            let appModel = StallyAppModel()

            StallyAppRouteService.apply(
                route: .settings,
                to: appModel,
                items: []
            )

            XCTAssertEqual(appModel.selectedTab, .library)
            XCTAssertEqual(appModel.libraryPath, [.settings])
        }
    }

    func testBackupRouteShowsSettingsAndBackupOnLibraryStack() async {
        await MainActor.run {
            let appModel = StallyAppModel()

            StallyAppRouteService.apply(
                route: .backup,
                to: appModel,
                items: []
            )

            XCTAssertEqual(appModel.selectedTab, .library)
            XCTAssertEqual(appModel.libraryPath, [.settings, .backup])
        }
    }

    func testCreateItemRoutePresentsCreateEditorAndResetsNavigation() async {
        await MainActor.run {
            let appModel = StallyAppModel()
            appModel.reviewPath = [.settings]

            StallyAppRouteService.apply(
                route: .createItem,
                to: appModel,
                items: []
            )

            XCTAssertEqual(appModel.selectedTab, .library)
            XCTAssertEqual(appModel.editorRoute?.mode, .create)
            XCTAssertTrue(appModel.reviewPath.isEmpty)
        }
    }

    func testActiveItemRouteOpensOnLibraryTab() async throws {
        try await MainActor.run {
            let appModel = StallyAppModel()
            let context = testContext()
            let item = try createTestItem(
                context: context,
                name: "Notebook",
                category: .notebooks,
                )

            StallyAppRouteService.apply(
                route: .item(item.id),
                to: appModel,
                items: [item]
            )

            XCTAssertEqual(appModel.selectedTab, .library)
            XCTAssertEqual(appModel.libraryPath, [.item(item.id)])
        }
    }

    func testArchivedItemRouteOpensOnArchiveTab() async throws {
        try await MainActor.run {
            let appModel = StallyAppModel()
            let context = testContext()
            let item = try createTestItem(
                context: context,
                name: "Camera",
                category: .bags,
                createdAt: localDate(year: 2_026, month: 3, day: 1),
                )
            try archiveTestItem(
                context: context,
                item: item,
                at: localDate(year: 2_026, month: 3, day: 10)
            )

            StallyAppRouteService.apply(
                route: .item(item.id),
                to: appModel,
                items: [item]
            )

            XCTAssertEqual(appModel.selectedTab, .archive)
            XCTAssertEqual(appModel.archivePath, [.item(item.id)])
        }
    }

    func testMissingItemRouteDefaultsToLibrary() async throws {
        let missingID = try testUUID("00000000-0000-0000-0000-000000000099")

        await MainActor.run {
            let appModel = StallyAppModel()

            StallyAppRouteService.apply(
                route: .item(missingID),
                to: appModel,
                items: []
            )

            XCTAssertEqual(appModel.selectedTab, .library)
            XCTAssertEqual(appModel.libraryPath, [.item(missingID)])
        }
    }
}

private extension StallyAppRouteServiceTests {
    func testUUID(
        _ value: String
    ) throws -> UUID {
        try XCTUnwrap(UUID(uuidString: value))
    }
}
