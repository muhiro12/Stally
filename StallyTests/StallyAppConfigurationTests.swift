import MHPlatform
@testable import Stally
import XCTest

final class StallyAppConfigurationTests: XCTestCase {
    @MainActor
    func testRuntimeConfigurationUsesLicenses() {
        XCTAssertTrue(
            StallyAppConfiguration.runtimeConfiguration.showsLicenses
        )
    }

    @MainActor
    func testPreviewConfigurationDisablesAds() {
        XCTAssertNil(
            StallyAppConfiguration.previewConfiguration.nativeAdUnitID
        )
    }
}
