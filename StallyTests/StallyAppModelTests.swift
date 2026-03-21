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
}
