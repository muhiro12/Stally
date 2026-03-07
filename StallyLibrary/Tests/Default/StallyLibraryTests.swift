import XCTest
@testable import StallyLibrary

final class StallyLibraryTests: XCTestCase {
    func testModuleAnchorIsAvailable() {
        XCTAssertEqual(StallyLibraryAnchor.moduleName, "StallyLibrary")
    }
}
