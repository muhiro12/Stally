import MHDeepLinking
@testable import StallyLibrary
import XCTest

final class StallyRouteTests: XCTestCase {
    func testPreferredURLUsesCustomSchemeForStaticRoutes() {
        let codec = StallyDeepLinking.codec()

        XCTAssertEqual(
            codec.preferredURL(for: .review)?.absoluteString,
            "stally://review"
        )
        XCTAssertEqual(
            codec.preferredURL(for: .archive)?.absoluteString,
            "stally://archive"
        )
    }

    func testItemRouteRoundTripsThroughCustomSchemeURL() throws {
        let codec = StallyDeepLinking.codec()
        let itemID = try XCTUnwrap(
            UUID(uuidString: "D1C0A8D1-0E8F-4B61-B915-8A1257B5AD4D")
        )
        let route = StallyRoute.item(itemID)

        let url = try XCTUnwrap(
            codec.preferredURL(for: route)
        )

        XCTAssertEqual(
            url.absoluteString,
            "stally://item?id=d1c0a8d1-0e8f-4b61-b915-8a1257b5ad4d"
        )
        XCTAssertEqual(
            codec.parse(url),
            route
        )
    }

    func testUniversalLinkRoundTripsWhenRequested() throws {
        let codec = StallyDeepLinking.codec()
        let url = try XCTUnwrap(
            codec.url(
                for: .settings,
                transport: .universalLink
            )
        )

        XCTAssertEqual(
            url.absoluteString,
            "https://stally.muhiro12.com/app/settings"
        )
        XCTAssertEqual(
            codec.parse(url),
            .settings
        )
    }

    func testHomeRouteAcceptsBareSchemeAndExplicitHomePath() throws {
        let codec = StallyDeepLinking.codec()

        let bareURL = try XCTUnwrap(URL(string: "stally://"))
        let homeURL = try XCTUnwrap(URL(string: "stally://home"))

        XCTAssertEqual(
            codec.parse(bareURL),
            .home
        )
        XCTAssertEqual(
            codec.parse(homeURL),
            .home
        )
    }

    func testInvalidItemRouteWithoutUUIDIsRejected() throws {
        let codec = StallyDeepLinking.codec()
        let invalidUUIDURL = try XCTUnwrap(
            URL(string: "stally://item?id=not-a-uuid")
        )
        let missingUUIDURL = try XCTUnwrap(
            URL(string: "stally://item")
        )

        XCTAssertNil(
            codec.parse(invalidUUIDURL)
        )
        XCTAssertNil(
            codec.parse(missingUUIDURL)
        )
    }
}
