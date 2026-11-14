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
    @State private var dropTargeted = false

    var body: some View {
        NavigationStack {
            Form {
                exportSection
                Section {
                    StallyActionButton(.exportRecords, action: prepareRecords)
                } header: {
                    Text("Export Records as JSON")
                } footer: {
                    Text("JSON includes all records and photo captions, but no image files.")
                }
                importSection
                if busy { ProgressView("Preparing File") }
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
        } onCancellation: {
            document = nil
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
        .alert("Could Not Complete Transfer", isPresented: showingError) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .modifier(StallyUpdateRequiredModifier())
    }

    private var showingError: Binding<Bool> {
        .init(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private var importSection: some View {
        Section("Import") {
            StallyActionButton(.chooseImportFile) { importing = true }
            Text("Review before saving. Current records are kept unless you choose otherwise.")
                .mhRowSupporting()
            if let archive {
                Button("Review Again") { prepareReview(archive) }
            }
            dropTarget
        }
    }

    private var acceptsDrop: Bool {
        !busy && review == nil && !importing && !exporting
    }

    private var dropTarget: some View {
        let minimumHeight = 60.0
        let highlightOpacity = 0.15
        return Label("Drop one Stally or JSON file here", systemImage: "square.and.arrow.down")
            .frame(maxWidth: .infinity, minHeight: minimumHeight, alignment: .leading)
            .contentShape(Rectangle())
            .listRowBackground(dropTargeted ? Color.accentColor.opacity(highlightOpacity) : nil)
            .dropDestination(for: ImportedStallyFile.self, isEnabled: acceptsDrop) { files, session in
                guard acceptsDrop, session.itemsCount == 1, files.count == 1, let file = files.first else {
                    return
                }
                completionMessage = nil
                switch file.contents {
                case .archive(let loaded):
                    archive = loaded
                    prepareReview(loaded)
                case .failure(let message):
                    errorMessage = message
                }
            }
            .dropConfiguration { session in
                .init(operation: session.itemsCount == 1 && acceptsDrop ? .copy : .forbidden)
            }
            .onDropSessionUpdated { session in
                dropTargeted = session.phase == .entering || session.phase == .active
            }
    }

    private var transferToolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            StallyActionButton(.done) {
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
            StallyActionButton(.exportLibrary, action: prepareExport)
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

    private func prepareExport() { prepareExport(recordsOnly: false) }

    private func prepareRecords() { prepareExport(recordsOnly: true) }

    private func prepareExport(recordsOnly: Bool) {
        task?.cancel()
        busy = true
        completionMessage = nil
        errorMessage = nil
        task = Task {
            defer { busy = false }
            do {
                let prepared = try await TransferOperations.prepareExport(
                    context: context,
                    includingImages: !recordsOnly && includingImages
                )
                try Task.checkCancellation()
                exportType = recordsOnly ? .json : StallyExportDocument.contentType
                document = recordsOnly ? .init(records: prepared) : .init(archive: prepared)
                exporting = true
            } catch is CancellationError {
                return
            } catch { errorMessage = error.localizedDescription }
        }
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
                review = try await TransferOperations.prepareReview(loaded, context: context)
            } catch is CancellationError {
                return
            } catch { errorMessage = error.localizedDescription }
        }
    }

    private func prepareReview(_ archive: TransferArchive) {
        task?.cancel()
        busy = true
        errorMessage = nil
        task = Task {
            defer { busy = false }
            do {
                review = try await TransferOperations.prepareReview(archive, context: context)
            } catch is CancellationError {
                return
            } catch { errorMessage = error.localizedDescription }
        }
    }
}
