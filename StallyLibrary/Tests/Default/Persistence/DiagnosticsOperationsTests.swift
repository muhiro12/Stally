import Foundation
import SwiftData
import Testing

@testable import StallyLibrary

@MainActor
struct DiagnosticsOperationsTests {
    @Test
    func snapshotReportsActualRecordsWithoutSavingPendingEdits() throws {
        let container = try StallyModelContainerFactory.inMemory()
        let context = container.mainContext
        context.autosaveEnabled = false
        let item = try ItemOperations.create(context: context, name: "Saved record")
        try ItemOperations.setArchived(item, to: true, context: context)
        try MarkOperations.add(to: item, localDateTime: "2026-10-28", context: context)
        try PeriodOperations.add(to: item, input: .init(), today: "2026-10-28", context: context)
        let tag = try TagOperations.create(name: "Shared", context: context)
        try TagOperations.assign([tag], to: item, context: context)
        let savedNote = item.note
        item.note = "Unsaved diagnostic check"
        let snapshot = try DiagnosticsOperations.snapshot(context: context)
        #expect(snapshot.items == 1 && snapshot.marks == 1 && snapshot.periods == 1)
        #expect(snapshot.tags == 1 && snapshot.photos == 0)
        #expect(snapshot.isInMemory && snapshot.cloudKitContainers.isEmpty)
        #expect(context.hasChanges && item.note == "Unsaved diagnostic check")
        let reader = ModelContext(container)
        #expect(try ItemOperations.item(context: reader, uuid: item.uuid).note == savedNote)
    }

    @Test
    func refreshUsesTheOpenDiskStoreAndCurrentCounts() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let container = try StallyModelContainerFactory.disk(at: directory.appending(path: "test.store"))
        let context = container.mainContext
        let initial = try DiagnosticsOperations.snapshot(context: context)
        #expect(!initial.isInMemory && initial.cloudKitContainers.isEmpty && initial.items == 0)
        #expect(initial.storeLocations == [directory.appending(path: "test.store")])
        let item = try ItemOperations.create(context: context, name: "A local record")
        try MarkOperations.add(to: item, localDateTime: "2026-10-28", context: context)
        let updated = try DiagnosticsOperations.snapshot(context: context)
        #expect(updated.items == 1 && updated.marks == 1 && updated.periods == 0)
    }

    #if DEBUG
    @Test
    func registrationPreservesExplicitPreferencesAndLaunchOverrides() throws {
        let suite = UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer {
            defaults.removeVolatileDomain(forName: UserDefaults.argumentDomain)
            defaults.removePersistentDomain(forName: suite)
        }
        StallyDevelopmentPreferences.register(in: defaults)
        #expect(defaults.bool(forKey: StallyDevelopmentPreferences.automaticallySeedRecordsKey))
        #expect(!defaults.bool(forKey: StallyDevelopmentPreferences.useSharedStoreKey))
        defaults.set(false, forKey: StallyDevelopmentPreferences.automaticallySeedRecordsKey)
        defaults.set(true, forKey: StallyDevelopmentPreferences.useSharedStoreKey)
        StallyDevelopmentPreferences.register(in: defaults)
        #expect(!defaults.bool(forKey: StallyDevelopmentPreferences.automaticallySeedRecordsKey))
        #expect(defaults.bool(forKey: StallyDevelopmentPreferences.useSharedStoreKey))
        defaults.setVolatileDomain(
            [StallyDevelopmentPreferences.useSharedStoreKey: false],
            forName: UserDefaults.argumentDomain
        )
        #expect(!defaults.bool(forKey: StallyDevelopmentPreferences.useSharedStoreKey))
        let saved = defaults.persistentDomain(forName: suite)
        #expect(saved?[StallyDevelopmentPreferences.useSharedStoreKey] as? Bool == true)
    }
    #endif
}
