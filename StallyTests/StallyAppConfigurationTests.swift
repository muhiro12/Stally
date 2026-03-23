import MHPlatform
@testable import Stally
import XCTest

final class StallyAppConfigurationTests: XCTestCase {
    @MainActor
    func testRuntimeConfigurationUsesStandardDefaultsStore() {
        XCTAssertNil(
            StallyAppConfiguration.runtimeConfiguration.preferencesSuiteName
        )
    }
}
