//
//  StallyLinkOperationsTests.swift
//  StallyLibraryTests
//
//  Created by Codex on 2026/06/26.
//

import Foundation
import StallyLibrary
import Testing

struct StallyLinkOperationsTests {
    @Test
    func `builds and parses destination links`() {
        for destination in StallyLinkDestination.allCases {
            let url = StallyLinkOperations.url(for: .destination(destination))

            #expect(url.absoluteString == "stally://\(destination.rawValue)")
            #expect(StallyLinkOperations.parse(url) == .supported(.destination(destination)))
        }
    }

    @Test
    func `builds and parses item links`() throws {
        let itemID = try #require(UUID(uuidString: "12345678-1234-1234-1234-123456789ABC"))
        let url = StallyLinkOperations.url(for: .item(itemID))

        #expect(url.absoluteString == "stally://item/12345678-1234-1234-1234-123456789ABC")
        #expect(StallyLinkOperations.parse(url) == .supported(.item(itemID)))
    }

    @Test
    func `unsupported links are explicit`() throws {
        let unsupportedURLs = [
            try #require(URL(string: "https://example.com/library")),
            try #require(URL(string: "stally://unknown")),
            try #require(URL(string: "stally://item/not-a-uuid")),
            try #require(URL(string: "stally://library/extra"))
        ]

        for url in unsupportedURLs {
            #expect(StallyLinkOperations.parse(url) == .unsupported)
        }
    }
}
