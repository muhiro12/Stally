import MHPlatformCore
@testable import StallyLibrary
import XCTest

final class StallyRouteTests: XCTestCase {
    func testPreferredURLUsesCustomSchemeForAllStaticRoutes() throws {
        let codec = StallyDeepLinking.codec()
        let cases: [(route: StallyRoute, expectedURL: String)] = [
            (.home, "stally://home"),
            (.archive, "stally://archive"),
            (.backup, "stally://backup"),
            (.insights, "stally://insights"),
            (.review, "stally://review"),
            (.settings, "stally://settings"),
            (.createItem, "stally://create")
        ]

        for testCase in cases {
            let url = try XCTUnwrap(
                URL(string: testCase.expectedURL)
            )

            XCTAssertEqual(
                codec.preferredURL(for: testCase.route)?.absoluteString,
                testCase.expectedURL
            )
            XCTAssertEqual(
                codec.parse(url),
                testCase.route
            )
        }
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

    func testItemRouteRoundTripsThroughUniversalLinkURL() throws {
        let codec = StallyDeepLinking.codec()
        let itemID = try XCTUnwrap(
            UUID(uuidString: "D1C0A8D1-0E8F-4B61-B915-8A1257B5AD4D")
        )
        let route = StallyRoute.item(itemID)

        let url = try XCTUnwrap(
            codec.url(
                for: route,
                transport: .universalLink
            )
        )

        XCTAssertEqual(
            url.absoluteString,
            "https://stally.muhiro12.com/app/item?id=d1c0a8d1-0e8f-4b61-b915-8a1257b5ad4d"
        )
        XCTAssertEqual(
            codec.parse(url),
            route
        )
    }

    func testUniversalLinksRoundTripForAllStaticRoutes() throws {
        let codec = StallyDeepLinking.codec()
        let cases: [(route: StallyRoute, expectedURL: String)] = [
            (.home, "https://stally.muhiro12.com/app/home"),
            (.archive, "https://stally.muhiro12.com/app/archive"),
            (.backup, "https://stally.muhiro12.com/app/backup"),
            (.insights, "https://stally.muhiro12.com/app/insights"),
            (.review, "https://stally.muhiro12.com/app/review"),
            (.settings, "https://stally.muhiro12.com/app/settings"),
            (.createItem, "https://stally.muhiro12.com/app/create")
        ]

        for testCase in cases {
            let url = try XCTUnwrap(
                codec.url(
                    for: testCase.route,
                    transport: .universalLink
                )
            )

            XCTAssertEqual(
                url.absoluteString,
                testCase.expectedURL
            )
            XCTAssertEqual(
                codec.parse(url),
                testCase.route
            )
        }
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

    func testUniversalLinkFromUnexpectedHostIsRejected() throws {
        let codec = StallyDeepLinking.codec()
        let url = try XCTUnwrap(
            URL(string: "https://example.com/app/home")
        )

        XCTAssertNil(
            codec.parse(url)
        )
    }
}
