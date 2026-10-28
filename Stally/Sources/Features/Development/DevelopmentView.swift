#if DEBUG
import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct DevelopmentView: View {
    @Environment(\.dismiss)
    private var dismiss
    @AppStorage(StallyDevelopmentPreferences.automaticallySeedRecordsKey)
    private var automaticallySeedRecords = true
    @AppStorage(StallyDevelopmentPreferences.useSharedStoreKey)
    private var useSharedStore = false
    @State private var confirmingSharedStore = false
    @State private var snapshot: DevelopmentOperations.Snapshot?
    @State private var diagnosticsError: String?
    let container: ModelContainer?
    let startupError: String?

    var body: some View {
        NavigationStack {
            developmentForm
                .navigationTitle("Developer Tools")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", systemImage: "checkmark") {
                            dismiss()
                        }
                    }
                }
                .task { refresh() }
                .confirmationDialog("Use the shared store on next launch?", isPresented: $confirmingSharedStore) {
                    Button("Use Shared Store") {
                        useSharedStore = true
                    }
                } message: {
                    Text("Writes in the shared store may sync with iCloud. Development records will not be copied.")
                }
        }
        .mhTheme(.standard)
    }

    private var developmentForm: some View {
        Form {
            MHContainerContent {
                storageSection
                if let snapshot {
                    countsSection(snapshot)
                }
                launchSection
                Section {
                    LabeledContent("Version", value: version)
                    LabeledContent("Schema", value: StallyDataContract.schemaVersion)
                } header: {
                    MHSectionHeader("App")
                } footer: {
                    MHSectionFooter("These tools are available only in DEBUG builds.")
                }
            }
        }
        .mhFormChrome(.content)
    }

    private var storageSection: some View {
        Section {
            if let snapshot {
                LabeledContent("Storage") {
                    Text(snapshot.isInMemory ? "In Memory" : "On Disk")
                }
                LabeledContent("CloudKit Configuration") {
                    Text(snapshot.cloudKitContainers.isEmpty ? "Disabled" : "Configured")
                }
                if !snapshot.isInMemory {
                    ForEach(snapshot.storeLocations, id: \.self) { location in
                        Text(location.path).mhTextStyle(.caption, colorRole: .secondaryText).textSelection(.enabled)
                    }
                }
            }
            if let error = startupError ?? diagnosticsError {
                Text(error).mhTextStyle(.supporting, colorRole: .destructive).textSelection(.enabled)
            }
            Button("Refresh Diagnostics", systemImage: "arrow.clockwise", action: refresh)
                .disabled(container == nil)
        } header: {
            MHSectionHeader("Current Storage")
        } footer: {
            MHSectionFooter("This shows the open store's configuration, not iCloud sync progress.")
        }
    }

    private var launchSection: some View {
        Section {
            Toggle("Use Shared Store", isOn: sharedStoreSelection)
                .disabled(isOverridden(StallyDevelopmentPreferences.useSharedStoreKey))
            Toggle("Add Samples on Initial Setup", isOn: $automaticallySeedRecords)
                .disabled(isOverridden(StallyDevelopmentPreferences.automaticallySeedRecordsKey))
        } header: {
            MHSectionHeader("Next Launch")
        } footer: {
            MHSectionFooter(Text(verbatim: launchExplanation))
        }
    }

    private var launchExplanation: String {
        var messages = [
            String(localized: "Store changes apply after relaunch. Existing records stay."),
            String(localized: "Samples are added only when the local development store is first created.")
        ]
        if isOverridden(StallyDevelopmentPreferences.useSharedStoreKey)
            || isOverridden(StallyDevelopmentPreferences.automaticallySeedRecordsKey) {
            messages.append(String(localized: "A launch argument overrides the disabled setting for this run."))
        }
        return messages.joined(separator: "\n")
    }

    private var sharedStoreSelection: Binding<Bool> {
        .init(
            get: { useSharedStore },
            set: { selected in
                if selected {
                    confirmingSharedStore = true
                } else {
                    useSharedStore = false
                }
            }
        )
    }
    private var version: String {
        let info = Bundle.main.infoDictionary ?? [:]
        return "\(info["CFBundleShortVersionString"] as? String ?? "—") (\(info["CFBundleVersion"] as? String ?? "—"))"
    }

    private func countsSection(_ snapshot: DevelopmentOperations.Snapshot) -> some View {
        Section {
            count("Items", value: snapshot.items)
            count("Marks", value: snapshot.marks)
            count("Periods", value: snapshot.periods)
            count("Photos", value: snapshot.photos)
            count("Tags", value: snapshot.tags)
        } header: {
            MHSectionHeader("Record Counts")
        }
    }

    private func count(_ title: LocalizedStringKey, value: Int) -> some View {
        LabeledContent(title) {
            Text(value, format: .number)
        }
    }

    private func isOverridden(_ key: String) -> Bool {
        UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)[key] != nil
    }

    private func refresh() {
        guard let container else {
            return
        }
        do {
            snapshot = try DevelopmentOperations.snapshot(context: container.mainContext)
            diagnosticsError = nil
        } catch {
            snapshot = nil
            diagnosticsError = error.localizedDescription
        }
    }
}
#endif
