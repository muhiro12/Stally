#if DEBUG
// Explicit profile sizes and expected timeline values describe the fixtures.
import Foundation
import StallyLibrary
import SwiftData
import Testing

extension SwiftDataOperationsTests {
    @Suite
    struct StallyFixtureOperationsTests {
        @Test(arguments: StallyFixtureProfile.allCases.filter { $0 != .stress })
        func `profiles repeat complete values and restore through the current contract`(
            profile: StallyFixtureProfile
        ) throws {
            let first = try context()
            let second = try context()
            let photo = try TestPhotoFixtures.preparedData()
            let firstItems = try StallyFixtureOperations.seed(profile, in: first, photoData: photo)
            let secondItems = try StallyFixtureOperations.seed(profile, in: second, photoData: photo)
            let date = StallyFixtureOperations.referenceDate
            let firstSnapshot = BackupOperations.snapshot(for: firstItems, exportedAt: date)
            #expect(firstSnapshot == BackupOperations.snapshot(for: secondItems, exportedAt: date))
            #expect(BackupOperations.preview(snapshot: firstSnapshot, currentItems: []).canImport)
            let restored = try context()
            let data = try BackupOperations.exportData(for: firstItems, exportedAt: date)
            try BackupOperations.replaceLibrary(data: data, context: restored)
            #expect(firstSnapshot == BackupOperations.snapshot(
                for: try ItemOperations.items(context: restored),
                exportedAt: date
            ))
            let identifiers = firstItems.map(\.uuid) + firstItems.flatMap { $0.marks.map(\.uuid) }
            #expect(Set(identifiers).count == identifiers.count)
        }

        @Test
        func `semantic samples share values while retaining separate removal identities`() throws {
            let sampleContext = try context()
            let fixtureContext = try context()
            let samples = try SampleDataOperations.createItemsIfLibraryIsEmpty(
                in: sampleContext,
                locale: .init(identifier: "ja"),
                timeZone: StallyFixtureOperations.timeZone,
                createdAt: StallyFixtureOperations.referenceDate
            )
            let fixtures = try StallyFixtureOperations.seed(
                .typical, in: fixtureContext, locale: .init(identifier: "ja")
            )
            #expect(samples.map(\.name) == fixtures.map(\.name))
            #expect(samples.map(\.note) == fixtures.map(\.note))
            #expect(samples.map(\.createdAt) == fixtures.map(\.createdAt))
            #expect(samples.map(\.archivedAt) == fixtures.map(\.archivedAt))
            #expect(samples.map { $0.marks.map(\.day).sorted() } == fixtures.map { $0.marks.map(\.day).sorted() })
            #expect(Set(samples.map(\.uuid)).isDisjoint(with: fixtures.map(\.uuid)))
            #expect(SampleDataOperations.summary(for: fixtures).isEmpty)
            #expect(try SampleDataOperations.removeSampleItems(in: fixtureContext).isEmpty)
            #expect(try ItemOperations.items(context: fixtureContext).count == 5)
        }

        @Test
        func `combined profile preserves every start precision and localized stable selection`() throws {
            let english = try context()
            let japanese = try context()
            let items = try StallyFixtureOperations.seed(.integration, in: english)
            let japaneseItems = try StallyFixtureOperations.seed(
                .integration, in: japanese, locale: .init(identifier: "ja")
            )
            #expect(items.count == 8)
            #expect(items.filter(\.recordsMarks).count == 5)
            #expect(items.filter(\.isArchived).count == 2)
            #expect(items.reduce(0) { $0 + $1.marks.count } == 23)
            #expect(Set(items.map(\.startRawValue)) == [nil, "2020", "2020-09", "2020-09-13"])
            #expect(items.map(\.uuid) == japaneseItems.map(\.uuid))
            #expect(japaneseItems.first { $0.uuid == StallyFixtureItem.home.id }?.name == "自宅")
            #expect(japaneseItems.first { $0.uuid == StallyFixtureItem.windowPlant.id }?.name == "窓辺の植物")
            let dense = try context()
            let denseItems = try StallyFixtureOperations.seed(.dense, in: dense, locale: .init(identifier: "ja"))
            let sweater = try #require(denseItems.first { $0.uuid == StallyFixtureItem.longNameSweater.id })
            #expect(sweater.name == "長くなじみのある名前のやわらかな紺色セーター")
            #expect(sweater.note == "ゆっくりした朝や、なじみのあるものがほしい日に。\n長いメモで、情報が多い画面や文字を大きくした表示を確認できます。")
        }

        @Test
        func `fixtures refuse nonempty and persistent containers without mutation`() throws {
            let occupied = try context()
            let existing = try ItemOperations.create(context: occupied, input: .init(name: "Kept", category: .other))
            #expect(throws: CocoaError.self) {
                try StallyFixtureOperations.seed(.integration, in: occupied)
            }
            #expect(try ItemOperations.items(context: occupied).map(\.uuid) == [existing.uuid])

            let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: directory) }
            let schema = StallyModelContainerFactory.schema
            let configuration = ModelConfiguration(
                schema: schema,
                url: directory.appending(path: "Fixture.store"),
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(
                for: schema,
                migrationPlan: StallyMigrationPlan.self,
                configurations: [configuration]
            )
            let persistent = ModelContext(container)
            #expect(throws: CocoaError.self) {
                try StallyFixtureOperations.seed(.typical, in: persistent)
            }
            #expect(try ItemOperations.items(context: persistent).isEmpty)
            #expect(!persistent.hasChanges)
        }

        @Test
        func `personal scale profile supports queries readings and restorable export`() throws {
            let modelContext = try context()
            let clock = ContinuousClock()
            let beginning = clock.now
            try StallyFixtureOperations.seed(.stress, in: modelContext)
            let seeded = clock.now
            let descriptor = FetchDescriptor<Item>(
                predicate: #Predicate { $0.archivedAt == nil },
                sortBy: [.init(\.createdAt, order: .reverse)]
            )
            let active = try modelContext.fetch(descriptor)
            let items = try ItemOperations.items(context: modelContext)
            let fetched = clock.now
            let date = StallyFixtureOperations.referenceDate
            let timeZone = StallyFixtureOperations.timeZone
            let today = try #require(LocalDay(containing: date, in: timeZone))
            let collection = ItemCollectionOperations.items(
                from: active, options: .init(filter: .withoutMarks, sort: .earliestStart), today: today
            )
            let review = ReviewOperations.snapshot(for: items, timeZone: timeZone, now: date)
            let insights = InsightsOperations.snapshot(
                for: items,
                options: .init(range: .allTime, includesArchivedItems: true),
                timeZone: timeZone,
                now: date
            )
            let read = clock.now
            let data = try BackupOperations.exportData(for: items, exportedAt: date)
            let exported = clock.now
            #expect(items.count == 500)
            #expect(active.count == 400)
            #expect(items.reduce(0) { $0 + $1.marks.count } == 6_250)
            #expect(collection.count == 200)
            #expect(review.needsFirstMark.isEmpty && review.dormant.isEmpty)
            #expect(insights.choiceItemCount == 250 && insights.totalMarks == 6_250)
            #expect(BackupOperations.preview(data: data, currentItems: []).canImport)
            print("Fixture scale: items=500 marks=6250 bytes=\(data.count) seed=\(beginning.duration(to: seeded)) "
                    + "fetch=\(seeded.duration(to: fetched)) readings=\(fetched.duration(to: read)) "
                    + "export=\(read.duration(to: exported))")
        }

        private func context() throws -> ModelContext {
            .init(try StallyModelContainerFactory.inMemory())
        }
    }
}
#endif
