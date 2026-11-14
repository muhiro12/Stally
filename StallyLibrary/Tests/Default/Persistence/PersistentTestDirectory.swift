import Foundation

enum PersistentTestDirectory {
    static func makeURL() -> URL {
        // Core Data can retain store handles beyond ModelContainer's lexical lifetime.
        // Leave these marked fixtures for cleanup only after the test process exits.
        let directory = FileManager.default.temporaryDirectory.appending(
            path: "StallyLibraryTests-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
        print("StallyLibrary persistent fixture directory: \(directory.path)")
        return directory
    }
}
