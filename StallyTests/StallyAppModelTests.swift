@testable import Stally
import XCTest

final class StallyAppModelTests: XCTestCase {
    func testPresentUnsupportedDeepLinkErrorShowsReadableMessage() async {
        await MainActor.run {
            let appModel = StallyAppModel()

            appModel.presentUnsupportedDeepLinkError()

            XCTAssertEqual(
                appModel.operationErrorMessage,
                StallyLocalization.string(
                    "This link isn't supported by this version of Stally."
                )
            )
        }
    }

    func testOpenBackupDefaultsToLibraryWorkspace() async {
        await MainActor.run {
            let appModel = StallyAppModel()
            let itemID = UUID()
            appModel.selectedTab = .review
            appModel.libraryPath = [
                .item(itemID)
            ]
            appModel.reviewPath = [
                .settings
            ]

            appModel.openBackup()

            XCTAssertEqual(appModel.selectedTab, .library)
            XCTAssertEqual(
                appModel.libraryPath,
                [
                    .settings,
                    .backup
                ]
            )
            XCTAssertEqual(
                appModel.reviewPath,
                [
                    .settings
                ]
            )
        }
    }
}
