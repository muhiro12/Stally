import MHUI
import StallyLibrary
import SwiftData
import SwiftUI

struct DiagnosticsView: View {
    @Environment(\.dismiss)
    private var dismiss

    #if DEBUG
    @AppStorage(StallyDevelopmentPreferences.automaticallySeedRecordsKey)
    private var automaticallySeedRecords = true
    @AppStorage(StallyDevelopmentPreferences.useSharedStoreKey)
    private var useSharedStore = false
    @State private var confirmingSharedStore = false
    #endif

    @State private var snapshot: DiagnosticsOperations.Snapshot?
    @State private var diagnosticsError: String?
    let container: ModelContainer?
    let startupError: String?

    var body: some View {
        NavigationStack {
            diagnosticsForm
                .navigationTitle("Diagnostics")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", systemImage: "checkmark") {
                            dismiss()
                        }
                    }
                }
                .task { refresh() }
                #if DEBUG
                .confirmationDialog("Use the shared store on next launch?", isPresented: $confirmingSharedStore) {
                    Button("Use Shared Store") {
                        useSharedStore = true
                    }
                } message: {
                    Text("Writes in the shared store may sync with iCloud. Development records will not be copied.")
                }
            #endif
        }
        .mhTheme(.standard)
    }

    private var diagnosticsForm: some View {
        Form {
            MHContainerContent {
                storageSection
                if let snapshot {
                    countsSection(snapshot)
                }
                #if DEBUG
                launchSection
                #endif
                Section {
                    LabeledContent("Version", value: version)
                    LabeledContent("Schema", value: StallyDataContract.schemaVersion)
                } header: {
                    MHSectionHeader("App")
                } footer: {
                    MHSectionFooter("Diagnostics do not change your saved records.")
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
                #if DEBUG
                if !snapshot.isInMemory {
                    ForEach(snapshot.storeLocations, id: \.self) { location in
                        Text(location.path).mhTextStyle(.caption, colorRole: .secondaryText).textSelection(.enabled)
                    }
                }
                #endif
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

    #if DEBUG
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
    #endif

    private var version: String {
        let info = Bundle.main.infoDictionary ?? [:]
        return "\(info["CFBundleShortVersionString"] as? String ?? "—") (\(info["CFBundleVersion"] as? String ?? "—"))"
    }

    private func countsSection(_ snapshot: DiagnosticsOperations.Snapshot) -> some View {
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

    #if DEBUG
    private func isOverridden(_ key: String) -> Bool {
        UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)[key] != nil
    }

    #endif

    private func refresh() {
        guard let container else {
            return
        }
        do {
            snapshot = try DiagnosticsOperations.snapshot(context: container.mainContext)
            diagnosticsError = nil
        } catch {
            snapshot = nil
            diagnosticsError = error.localizedDescription
        }
    }
}
