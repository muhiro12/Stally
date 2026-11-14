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
    @Test(arguments: [
        (StallyLinkDestination.library, "stally://library"),
        (.archive, "stally://archive"),
        (.importExport, "stally://import-export"),
        (.createItem, "stally://create-item")
    ])
    func `builds and opens the first release destination URLs`(
        destination: StallyLinkDestination,
        absoluteString: String
    ) throws {
        let savedURL = try #require(URL(string: absoluteString))

        let sharedURL = StallyLinkOperations.url(for: .destination(destination))
        #expect(sharedURL.absoluteString == "https://muhiro12.github.io/Stally/" + destination.rawValue)
        #expect(StallyLinkOperations.parse(savedURL) == .supported(.destination(destination)))
    }

    @Test
    func `builds and parses item links`() throws {
        let itemID = try #require(UUID(uuidString: "12345678-1234-1234-1234-123456789ABC"))
        let url = StallyLinkOperations.url(for: .item(itemID))

        #expect(url.absoluteString == "https://muhiro12.github.io/Stally/item/12345678-1234-1234-1234-123456789ABC")
        #expect(StallyLinkOperations.parse(url) == .supported(.item(itemID)))
    }

    @Test
    func universalLinksAreScopedToTheOwnedHostAndAppPath() throws {
        let uuid = UUID()
        let url = try #require(URL(string: "https://muhiro12.github.io/Stally/item/\(uuid.uuidString)"))
        #expect(StallyLinkOperations.parse(url) == .supported(.item(uuid)))
        for text in [
            "https://muhiro12.github.io/Cookle/library", "https://example.com/Stally/library",
            "https://muhiro12.github.io/library",
            "http://muhiro12.github.io/Stally/library"
        ] {
            let unsupported = try #require(URL(string: text))
            #expect(StallyLinkOperations.parse(unsupported) == .unsupported)
        }
    }

    @Test(arguments: ["stally://item", "https://muhiro12.github.io/Stally/item"])
    func itemRoutesRequireOneUUIDPathSegment(base: String) throws {
        let itemID = UUID()
        let uuid = itemID.uuidString
        let valid = try #require(URL(string: base + "/" + uuid))
        #expect(StallyLinkOperations.parse(valid) == .supported(.item(itemID)))
        for suffix in ["", "?id=\(uuid)", "/invalid", "/\(uuid)/extra", "/\(uuid)?id=\(uuid)"] {
            let url = try #require(URL(string: base + suffix))
            #expect(StallyLinkOperations.parse(url) == .unsupported)
        }
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
