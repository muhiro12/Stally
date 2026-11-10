import MHUI
import StallyLibrary
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct TransferView: View {
    @Environment(\.modelContext)
    private var context
    @Environment(\.dismiss)
    private var dismiss
    let initialURL: URL?
    @State private var importing = false
    @State private var exporting = false
    @State private var includingImages = true
    @State private var exportType = StallyExportDocument.contentType
    @State private var document: StallyExportDocument?
    @State private var archive: TransferArchive?
    @State private var review: TransferReview?
    @State private var task: Task<Void, Never>?
    @State private var busy = false
    @State private var errorMessage: String?
    @State private var completionMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                exportSection
                Section {
                    Button("Export Records as JSON", systemImage: "doc.text", action: prepareRecords)
                } header: {
                    Text("Export Records as JSON")
                } footer: {
                    Text("JSON includes all records and photo captions, but no image files.")
                }
                Section("Import") {
                    Button("Choose Stally File", systemImage: "square.and.arrow.down") { importing = true }
                    Text(
                        "Review before saving. Current records are kept unless you choose otherwise."
                    )
                    .mhRowSupporting()
                    if let archive {
                        Button("Review Again") { prepareReview(archive) }
                    }
                }
                if busy { ProgressView("Preparing File") }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
                if let completionMessage { Text(completionMessage) }
            }
            .disabled(busy)
            .navigationTitle("Import & Export")
            .toolbar { transferToolbar }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: importTypes) { result in
            do { load(try result.get()) } catch { errorMessage = error.localizedDescription }
        }
        .fileExporter(
            isPresented: $exporting,
            document: document,
            contentType: exportType,
            defaultFilename: StallyExportDocument.filename()
        ) { result in
            document = nil
            switch result {
            case .success:
                completionMessage = String(localized: "Export Completed")
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
        .sheet(item: $review) { review in
            ImportReviewView(review: review) { count in
                self.review = nil
                archive = nil
                completionMessage = String(localized: "Imported \(count) records.")
            }
        }
        .task {
            if let initialURL { load(initialURL) }
        }
        .onDisappear { task?.cancel() }
        .modifier(StallyUpdateRequiredModifier())
    }

    private var transferToolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Done", systemImage: "checkmark") {
                dismiss()
            }
        }
    }

    private var exportSection: some View {
        Section {
            Toggle("Include Photos", isOn: $includingImages)
            if includingImages {
                Text("Exported photos retain embedded metadata, including location when present.")
                    .mhRowSupporting()
            }
            Button("Export Library", systemImage: "square.and.arrow.up", action: prepareExport)
            Text("Exports all Items, including archived records and unused Tags.").mhRowSupporting()
        } header: {
            Text("Export")
        } footer: {
            VStack(alignment: .leading) {
                Text("Export records for use in other apps or transfer to another device.")
                Text(
                    """
                    For import into Stally, use the file promptly after export. \
                    Future versions may not support older files.
                    """
                )
            }
        }
    }

    private var importTypes: [UTType] { [StallyExportDocument.contentType, .json] }

    private func prepareExport() {
        completionMessage = nil
        do {
            exportType = StallyExportDocument.contentType
            document = try .init(archive: TransferOperations.export(context: context, includingImages: includingImages))
            exporting = true
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    private func prepareRecords() {
        completionMessage = nil
        do {
            exportType = .json
            document = try .init(records: TransferOperations.exportRecords(context: context))
            exporting = true
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    private func load(_ url: URL) {
        task?.cancel()
        busy = true
        errorMessage = nil
        completionMessage = nil
        archive = nil
        task = Task {
            defer { busy = false }
            do {
                let loaded = try await TransferFileOperations.read(url)
                try Task.checkCancellation()
                archive = loaded
                prepareReview(loaded)
            } catch is CancellationError {
                return
            } catch { errorMessage = error.localizedDescription }
        }
    }

    private func prepareReview(_ archive: TransferArchive) {
        do {
            review = try TransferOperations.review(archive, context: context)
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }
}
