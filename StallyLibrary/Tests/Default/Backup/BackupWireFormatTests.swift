//
//  BackupWireFormatTests.swift
//  StallyLibraryTests
//
//  Created by Codex on 2026/07/12.
//

import Foundation
import StallyLibrary
import Testing

@Suite
struct BackupWireFormatTests {
    @Test
    func `version two golden JSON round trips with a canonical local day`() throws {
        let goldenData = Data(versionTwoGoldenJSON().utf8)
        let snapshot = try JSONDecoder().decode(BackupSnapshot.self, from: goldenData)
        let item = try #require(snapshot.items.first)
        let mark = try #require(item.marks.first)
        let expectedDay = try #require(LocalDay(year: 2_026, month: 6, day: 26))

        #expect(snapshot.schemaVersion == 2)
        #expect(mark.day == expectedDay)

        let encodedData = try JSONEncoder().encode(snapshot)
        let roundTrippedSnapshot = try JSONDecoder().decode(BackupSnapshot.self, from: encodedData)

        #expect(roundTrippedSnapshot == snapshot)
        #expect(try normalizedJSON(encodedData) == normalizedJSON(goldenData))
    }

    @Test
    func `version one date based marks are explicitly unsupported`() {
        let legacyData = Data(versionOneLegacyJSON().utf8)
        let preview = BackupOperations.preview(data: legacyData, currentItems: [])

        #expect(
            preview.validationIssues == [
                .init(kind: .unsupportedSchemaVersion, value: "1")
            ]
        )
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(BackupSnapshot.self, from: legacyData)
        }
    }

    private func normalizedJSON(_ data: Data) throws -> Data {
        let object = try JSONSerialization.jsonObject(with: data)
        return try JSONSerialization.data(withJSONObject: object, options: .sortedKeys)
    }

    private func versionTwoGoldenJSON() -> String {
        """
        {
          "schemaVersion": 2,
          "exportedAt": 100,
          "items": [
            {
              "id": "00000000-0000-0000-0000-000000000001",
              "name": "Canvas Tote",
              "categoryRawValue": "Bags",
              "note": "Golden note",
              "photoData": "AQID",
              "createdAt": 200,
              "archivedAt": 300,
              "marks": [
                {
                  "id": "00000000-0000-0000-0000-000000000002",
                  "day": "2026-06-26",
                  "createdAt": 400
                }
              ]
            }
          ]
        }
        """
    }

    private func versionOneLegacyJSON() -> String {
        """
        {
          "schemaVersion": 1,
          "exportedAt": 100,
          "items": [
            {
              "id": "00000000-0000-0000-0000-000000000001",
              "name": "Canvas Tote",
              "categoryRawValue": "Bags",
              "note": "Legacy note",
              "photoData": null,
              "createdAt": 200,
              "archivedAt": null,
              "marks": [
                {
                  "id": "00000000-0000-0000-0000-000000000002",
                  "day": 300,
                  "createdAt": 400
                }
              ]
            }
          ]
        }
        """
    }
}
