import CoreData
import Foundation
@testable import StallyLibrary
import SwiftData
import Testing

extension SwiftDataOperationsTests {
    @Suite
    struct StallyFirstReleaseModelTests {
        @Test
        func `selected schema keeps queryable scalars and CloudKit compatible relationships`() throws {
            let model = try #require(NSManagedObjectModel.makeManagedObjectModel(for: [Item.self, ItemMark.self]))
            let item = try #require(model.entitiesByName["Item"])
            #expect(Set(item.attributesByName.keys) == [
                "uuid", "name", "categoryRawValue", "note", "photoData", "createdAt",
                "archivedAt", "recordsMarks", "startRawValue"
            ])
            #expect(item.attributesByName["recordsMarks"]?.attributeType == .booleanAttributeType)
            #expect(item.attributesByName["startRawValue"]?.attributeType == .stringAttributeType)
            #expect(item.attributesByName["photoData"]?.allowsExternalBinaryDataStorage == true)
            for entity in model.entities {
                #expect(entity.uniquenessConstraints.isEmpty)
                for attribute in entity.attributesByName.values {
                    #expect(attribute.isOptional || attribute.defaultValue != nil)
                }
                for relationship in entity.relationshipsByName.values {
                    #expect(relationship.isOptional)
                    #expect(relationship.inverseRelationship != nil)
                    #expect(relationship.deleteRule != .denyDeleteRule)
                }
            }
            #expect(item.relationshipsByName["markRecords"]?.deleteRule == .cascadeDeleteRule)
        }

        @Test
        func `combined subjects reopen every policy and start precision without changing portable meaning`() throws {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defer {
                try? FileManager.default.removeItem(at: directory)
            }
            let storeURL = directory.appendingPathComponent("Stally.store")
            let today = try #require(LocalDay(year: 2_026, month: 9, day: 30))
            let photo = try TestPhotoFixtures.preparedData()
            let expected = try autoreleasepool {
                try writeFixture(to: storeURL, today: today, photo: photo)
            }
            let snapshot = try JSONDecoder().decode(BackupSnapshot.self, from: expected)
            for _ in 0..<2 {
                try autoreleasepool {
                    let context = try makeContext(at: storeURL)
                    let items = try ItemOperations.items(context: context)
                    let reopened = BackupOperations.snapshot(for: items, exportedAt: snapshot.exportedAt)
                    #expect(reopened == snapshot)
                    for item in items {
                        let tracking = try ItemOperations.trackingInput(for: item)
                        #expect(tracking.markPolicy == item.markPolicy)
                        #expect(item.photoData == photo)
                        #expect(item.marks.allSatisfy { mark in
                            mark.item?.uuid == item.uuid && mark.day == today
                        })
                        let link = StallyLinkOperations.url(for: .item(item.uuid))
                        #expect(StallyLinkOperations.parse(link) == .supported(.item(item.uuid)))
                    }
                }
            }
        }

        @Test
        func `portable versions identify the corresponding durable schema explicitly`() {
            #expect(StallyDataContract.persistenceVersion(forInterchangeVersion: 2) == 1)
            #expect(StallyDataContract.persistenceVersion(forInterchangeVersion: 3) == 2)
            #expect(StallyDataContract.persistenceVersion(forInterchangeVersion: 1) == nil)
            #expect(StallyDataContract.persistenceVersion(forInterchangeVersion: 4) == nil)
            #expect(BackupSnapshot.currentSchemaVersion == StallyDataContract.interchangeVersion)
            #expect(StallyModelContainerFactory.schema.version == .init(StallyDataContract.persistenceVersion, 0, 0))
        }

        private func makeContext(at storeURL: URL) throws -> ModelContext {
            let schema = StallyModelContainerFactory.schema
            let container = try ModelContainer(
                for: schema,
                migrationPlan: StallyMigrationPlan.self,
                configurations: [ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)]
            )
            return .init(container)
        }

        private func writeFixture(to storeURL: URL, today: LocalDay, photo: Data) throws -> Data {
            let context = try makeContext(at: storeURL)
            let starts: [ItemStart?] = [
                nil,
                .init(rawValue: "2020"),
                .init(rawValue: "2020-09"),
                .init(rawValue: "2020-09-12")
            ]
            for policy in ItemMarkPolicy.allCases {
                for (index, start) in starts.enumerated() {
                    let item = try ItemOperations.create(
                        context: context,
                        input: .init(
                            name: "Subject \(policy.rawValue) \(index)",
                            category: .other,
                            note: "A meaningful thing or place",
                            photoData: photo
                        ),
                        tracking: .init(markPolicy: policy, start: start),
                        today: today
                    )
                    if policy == .enabled {
                        try ItemOperations.mark(item, on: today, today: today, context: context)
                    }
                    if start?.precision == .month {
                        try ItemOperations.archive(item, on: .now, context: context)
                    }
                }
            }
            return try BackupOperations.exportData(for: ItemOperations.items(context: context))
        }
    }
}
