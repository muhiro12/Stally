import PhotosUI
import StallyLibrary
import SwiftData
import SwiftUI

struct StallyItemEditorView: View {
    enum Mode {
        case create
        case edit(Item)
    }

    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.modelContext)
    private var context

    @State private var name: String
    @State private var category: ItemCategory
    @State private var note: String
    @State private var photoData: Data?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var errorMessage: String?
    @State private var isDeleteConfirmationPresented = false

    private let mode: Mode
    private let onComplete: (UUID?) -> Void
    private let onDelete: (UUID) -> Void

    init(
        mode: Mode,
        onComplete: @escaping (UUID?) -> Void,
        onDelete: @escaping (UUID) -> Void
    ) {
        self.mode = mode
        self.onComplete = onComplete
        self.onDelete = onDelete

        switch mode {
        case .create:
            _name = State(initialValue: "")
            _category = State(initialValue: .other)
            _note = State(initialValue: "")
            _photoData = State(initialValue: nil)
        case .edit(let item):
            _name = State(initialValue: item.name)
            _category = State(initialValue: item.category)
            _note = State(initialValue: item.note ?? "")
            _photoData = State(initialValue: item.photoData)
        }
    }

    var body: some View {
        let photoButtonTitle = photoData == nil ? "Choose Photo" : "Replace Photo"

        Form {
            Section("Item") {
                TextField("Name", text: $name)

                Picker("Category", selection: $category) {
                    ForEach(ItemCategory.allCases, id: \.self) { category in
                        Text(category.title)
                            .tag(category)
                    }
                }

                if trimmedName.isEmpty {
                    Text("Name is required.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            Section("Photo") {
                HStack(spacing: 16) {
                    StallyItemArtworkView(
                        photoData: photoData,
                        category: category,
                        width: 92,
                        height: 112
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        PhotosPicker(
                            selection: $selectedPhotoItem,
                            matching: .images,
                            preferredItemEncoding: .compatible
                        ) {
                            Label(
                                photoButtonTitle,
                                systemImage: "photo.on.rectangle"
                            )
                        }

                        if photoData != nil {
                            Button("Remove Photo", role: .destructive) {
                                photoData = nil
                                selectedPhotoItem = nil
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Note") {
                TextEditor(text: $note)
                    .frame(minHeight: 160)
            }

            if existingItem != nil {
                Section("Danger Zone") {
                    Button("Delete Item", role: .destructive) {
                        isDeleteConfirmationPresented = true
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(saveButtonTitle) {
                    save()
                }
                .bold()
                .disabled(trimmedName.isEmpty)
            }
        }
        .task(id: selectedPhotoItem) {
            await loadSelectedPhoto()
        }
        .alert(
            "Unable to Complete This Action",
            isPresented: isErrorPresented
        ) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .confirmationDialog(
            "Delete Item",
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Delete Item", role: .destructive) {
                deleteItem()
            }
            Button("Cancel", role: .cancel) {
                // no-op
            }
        } message: {
            Text("This permanently removes the item and all of its marks.")
        }
        .stallyScreenBackground()
    }
}

private extension StallyItemEditorView {
    var existingItem: Item? {
        switch mode {
        case .create:
            nil
        case .edit(let item):
            item
        }
    }

    var navigationTitle: String {
        switch mode {
        case .create:
            "Add Item"
        case .edit:
            "Edit Item"
        }
    }

    var saveButtonTitle: String {
        switch mode {
        case .create:
            "Save"
        case .edit:
            "Save"
        }
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isErrorPresented: Binding<Bool> {
        .init(
            get: {
                errorMessage != nil
            },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    var formInput: ItemFormInput {
        .init(
            name: name,
            category: category,
            photoData: photoData,
            note: note
        )
    }

    func loadSelectedPhoto() async {
        guard let selectedPhotoItem else {
            return
        }

        do {
            photoData = try await selectedPhotoItem.loadTransferable(type: Data.self)
        } catch {
            errorMessage = "Failed to load the selected photo."
        }
    }

    func save() {
        do {
            switch mode {
            case .create:
                let item = try ItemService.create(
                    context: context,
                    input: formInput
                )
                onComplete(item.id)
            case .edit(let item):
                try ItemService.update(
                    context: context,
                    item: item,
                    input: formInput
                )
                onComplete(item.id)
            }

            dismiss()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Failed to save this item."
        }
    }

    func deleteItem() {
        guard let existingItem else {
            return
        }

        do {
            try ItemService.delete(
                context: context,
                item: existingItem
            )
            onDelete(existingItem.id)
            dismiss()
        } catch {
            errorMessage = "Failed to delete this item."
        }
    }
}

@available(iOS 18.0, *)
#Preview("Create Item", traits: .modifier(StallySampleData())) {
    NavigationStack {
        StallyItemEditorView(mode: .create) { _ in
            // no-op
        } onDelete: { _ in
            // no-op
        }
    }
}

@available(iOS 18.0, *)
#Preview("Edit Item", traits: .modifier(StallySampleData())) {
    @Previewable @Query var items: [Item]

    NavigationStack {
        if let item = items.first {
            StallyItemEditorView(mode: .edit(item)) { _ in
                // no-op
            } onDelete: { _ in
                // no-op
            }
        } else {
            EmptyView()
        }
    }
}
