import MHUI
import SwiftUI

/// Saving and sharing use the same already validated, immutable snapshot.
struct BackupExportView: View {
    @Environment(\.dismiss)
    private var dismiss

    let document: StallyBackupDocument
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            exportForm
                .navigationTitle("Export Data")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
        .fileExporter(
            isPresented: $isSaving,
            document: document,
            contentType: .stallyBackup,
            defaultFilename: String(localized: "Stally Data")
        ) { result in
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                if (error as? CocoaError)?.code != .userCancelled {
                    errorMessage = error.localizedDescription
                }
            }
        }
        .alert("Data could not be saved.", isPresented: isShowingError) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var exportForm: some View {
        Form {
            Section {
                ShareLink(item: StallyExportFile(data: document.data), preview: SharePreview("Stally Data")) {
                    Label("Share Data", systemImage: "square.and.arrow.up")
                }
                Button {
                    isSaving = true
                } label: {
                    Label("Save to Files", systemImage: "folder")
                }
            } footer: {
                Text("This export includes every Item, note, photo, and Mark. Choose where to save or share it.")
            }
        }
    }

    private var isShowingError: Binding<Bool> {
        .init {
            errorMessage != nil
        } set: { isPresented in
            if !isPresented {
                errorMessage = nil
            }
        }
    }
}
