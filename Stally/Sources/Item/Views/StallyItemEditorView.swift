import PhotosUI
import StallyLibrary
import SwiftData
import SwiftUI

struct StallyItemEditorView: View {
    typealias Mode = StallyItemEditorModel.Mode

    @Environment(StallyAppModel.self)
    private var appModel
    @Environment(\.modelContext)
    private var context

    @State private var model: StallyItemEditorModel
    @State private var selectedPhotoItem: PhotosPickerItem?

    let navigationNamespace: Namespace.ID

    var body: some View {
        Form {
            overviewSection
            detailsSection
            photoSection
            noteSection

            if model.existingItem != nil {
                dangerZoneSection
            }
        }
        .navigationTitle(model.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    attemptDismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    save()
                }
                .bold()
                .disabled(!model.canSave)
            }
        }
        .interactiveDismissDisabled(model.hasChanges)
        .task(id: selectedPhotoItem) {
            guard let selectedPhotoItem else {
                return
            }

            await model.loadPhotoData {
                try await selectedPhotoItem.loadTransferable(type: Data.self)
            }
        }
        .alert(
            "Unable to Complete This Action",
            isPresented: errorPresentedBinding
        ) {
            Button("OK", role: .cancel) {
                model.dismissError()
            }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .confirmationDialog(
            "Discard changes?",
            isPresented: discardConfirmationBinding,
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive) {
                model.dismissDiscardConfirmation()
                appModel.dismissEditor()
            }
            Button("Keep Editing", role: .cancel) {
                model.dismissDiscardConfirmation()
            }
        }
        .confirmationDialog(
            "Delete Item",
            isPresented: deleteConfirmationBinding,
            titleVisibility: .visible
        ) {
            Button("Delete Item", role: .destructive) {
                deleteItem()
            }
            Button("Cancel", role: .cancel) {
                model.dismissDeleteConfirmation()
            }
        } message: {
            Text("This permanently removes the item and all of its marks.")
        }
        .background(StallyDesign.backgroundGradient.ignoresSafeArea())
    }

    init(
        mode: Mode,
        navigationNamespace: Namespace.ID
    ) {
        _model = State(
            initialValue: .init(mode: mode)
        )
        self.navigationNamespace = navigationNamespace
    }
}

private extension StallyItemEditorView {
    var nameBinding: Binding<String> {
        .init(
            get: {
                model.name
            },
            set: { newValue in
                model.name = newValue
            }
        )
    }

    var categoryBinding: Binding<ItemCategory> {
        .init(
            get: {
                model.category
            },
            set: { newValue in
                model.category = newValue
            }
        )
    }

    var noteBinding: Binding<String> {
        .init(
            get: {
                model.note
            },
            set: { newValue in
                model.note = newValue
            }
        )
    }

    var deleteConfirmationBinding: Binding<Bool> {
        .init(
            get: {
                model.isDeleteConfirmationPresented
            },
            set: { newValue in
                if newValue {
                    model.requestDeleteConfirmation()
                } else {
                    model.dismissDeleteConfirmation()
                }
            }
        )
    }

    var discardConfirmationBinding: Binding<Bool> {
        .init(
            get: {
                model.isDiscardConfirmationPresented
            },
            set: { newValue in
                if newValue {
                    _ = model.requestDiscardConfirmationIfNeeded()
                } else {
                    model.dismissDiscardConfirmation()
                }
            }
        )
    }

    var errorPresentedBinding: Binding<Bool> {
        .init(
            get: {
                model.errorMessage != nil
            },
            set: { isPresented in
                if !isPresented {
                    model.dismissError()
                }
            }
        )
    }

    var overviewSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(model.navigationTitle)
                    .font(StallyDesign.Typography.hero)
                    .foregroundStyle(StallyDesign.Palette.ink)

                Text(model.screenSubtitle)
                    .font(StallyDesign.Typography.body)
                    .foregroundStyle(StallyDesign.Palette.mutedInk)
            }
            .padding(.vertical, 8)
        }
    }

    var detailsSection: some View {
        Section("Item") {
            TextField("Name", text: nameBinding)

            Picker("Category", selection: categoryBinding) {
                ForEach(ItemCategory.allCases, id: \.self) { category in
                    Text(category.title)
                        .tag(category)
                }
            }

            if model.trimmedName.isEmpty {
                Text("Name is required.")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    var photoSection: some View {
        let photoButtonTitle = model.photoButtonTitle

        return Section("Photo") {
            HStack(spacing: 16) {
                StallyItemArtworkView(
                    photoData: model.photoData,
                    category: model.category,
                    width: 96,
                    height: 118
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
                    .buttonStyle(StallySecondaryButtonStyle())

                    if model.photoData != nil {
                        Button("Remove Photo", role: .destructive) {
                            model.removePhoto()
                            selectedPhotoItem = nil
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    var noteSection: some View {
        Section("Note") {
            TextEditor(text: noteBinding)
                .frame(minHeight: 180)
        }
    }

    var dangerZoneSection: some View {
        Section("Danger Zone") {
            Button("Delete Item", role: .destructive) {
                model.requestDeleteConfirmation()
            }
        }
    }

    func attemptDismiss() {
        if model.requestDiscardConfirmationIfNeeded() {
            appModel.dismissEditor()
        }
    }

    func save() {
        do {
            let itemID = try model.save(
                context: context
            )

            appModel.dismissEditor()

            switch model.mode {
            case .create:
                appModel.openItem(
                    itemID,
                    in: .library
                )
            case .edit:
                break
            }
        } catch {
            model.presentSaveError(error)
        }
    }

    func deleteItem() {
        do {
            let deletedItemID = try model.delete(
                context: context
            )

            appModel.dismissEditor()
            appModel.removeItemDestination(deletedItemID)
        } catch {
            model.presentDeleteError(error)
        }
    }
}

@available(iOS 26.0, *)
#Preview("Create Item", traits: .modifier(StallySampleData())) {
    @Previewable @Namespace var namespace

    NavigationStack {
        StallyItemEditorView(
            mode: .create,
            navigationNamespace: namespace
        )
    }
}

@available(iOS 26.0, *)
#Preview("Edit Item", traits: .modifier(StallySampleData())) {
    @Previewable @Query var items: [Item]
    @Previewable @Namespace var namespace

    NavigationStack {
        if let item = items.first {
            StallyItemEditorView(
                mode: .edit(item),
                navigationNamespace: namespace
            )
        }
    }
}
