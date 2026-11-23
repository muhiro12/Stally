import Foundation
import StallyLibrary
import Synchronization
import Testing

@MainActor
struct AnnouncementRefreshTests {
    private static let policy = #""remoteUpdate":{"schemaVersion":1,"revision":1,"requirement":null}"#
    private static let item = #"""
        {"id":"scheduled","minimumVersion":"1.0","maximumVersion":"1.0","startsAt":"2026-12-01T00:00:00Z",
        "endsAt":"2026-12-02T00:00:00Z","localizations":{"en":{"title":"News","body":"Details"},
        "ja":{"title":"お知らせ","body":"詳細"}}}
        """#

    private static func notices(_ items: String) -> String {
        #""announcements":{"schemaVersion":1,"defaultLanguage":"en","items":[\#(items)]}"#
    }

    @Test
    func foregroundRefreshPublishesAndWithdrawsNoticesIndependentlyOfUpdates() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AnnouncementURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer {
            session.invalidateAndCancel()
            try? FileManager.default.removeItem(at: directory)
        }
        let operations = try RemoteUpdateOperations(
            appStoreID: 1,
            configurationURL: #require(URL(string: "https://example.com/config")),
            storageDirectory: directory,
            session: session
        )
        let now = try Date("2026-12-01T12:00:00Z", strategy: .iso8601)
        func refresh(_ features: String?) async throws {
            try AnnouncementURLProtocol.setFeatures(features)
            try await operations.prepare()
        }
        func titles(version: String = "1.0", date: Date? = nil, language: String = "ja-JP") -> [String] {
            let announcements = operations.announcementFeed?.visibleAnnouncements(
                installedVersion: .init(version),
                at: date ?? now,
                preferredLanguages: [language]
            )
            return announcements?.map(\.title) ?? []
        }

        let unversionedPolicy = #""remoteUpdate":{"revision":1,"requirement":null}"#
        try await refresh([unversionedPolicy, Self.notices(Self.item)].joined(separator: ","))
        #expect(operations.decision == .unavailable)
        #expect(titles() == ["お知らせ"])

        try await refresh(Self.policy)
        #expect(operations.decision == .notRequired)
        #expect(operations.announcementFeed == nil)
        try await refresh(Self.notices(Self.item))
        #expect(titles() == ["お知らせ"])
        #expect(titles(language: "fr") == ["News"])
        #expect(titles(version: "1.1").isEmpty)
        #expect(titles(date: .distantFuture).isEmpty)

        try await refresh(nil)
        #expect(titles() == ["お知らせ"])
        for withdrawal in [Self.notices(""), #""announcements":null"#, ""] {
            try await refresh([Self.policy, withdrawal].filter { !$0.isEmpty }.joined(separator: ","))
            #expect(titles().isEmpty)
            #expect(operations.decision == .notRequired)
            #expect(operations.evaluation?.refreshError == nil)
            try await refresh([Self.policy, Self.notices(Self.item)].joined(separator: ","))
            #expect(titles() == ["お知らせ"])
        }
    }
}

private extension AnnouncementRefreshTests {
    final class AnnouncementURLProtocol: URLProtocol {
        private static let successStatusCode = 200
        private static let payload = Mutex<Data?>(nil)

        static func setFeatures(_ features: String?) throws {
            let bundleID = try #require(Bundle.main.bundleIdentifier)
            payload.withLock { payload in
                payload = features.map { sections in
                    Data(#"{"schemaVersion":1,"bundleIdentifier":"\#(bundleID)","features":{\#(sections)}}"#.utf8)
                }
            }
        }

        override static func canInit(with _: URLRequest) -> Bool {
            true
        }

        override static func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }

        override func startLoading() {
            guard let data = Self.payload.withLock({ $0 }), let url = request.url,
                  let response = HTTPURLResponse(
                    url: url, statusCode: Self.successStatusCode, httpVersion: nil, headerFields: nil
                  ) else {
                client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
                return
            }
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {
            // The in-memory response completes synchronously.
        }
    }
}
