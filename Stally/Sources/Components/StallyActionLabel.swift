import SwiftUI

enum StallyActionLabel: View {
    case addItem
    case editItem
    case addMark
    case recordToday
    case recordNow
    case undoAddition
    case addPeriod
    case endPeriod
    case resumePeriod
    case addTag
    case chooseTags
    case consolidateTags
    case removeTag
    case deleteTag
    case addFavorite
    case removeFavorite
    case archiveItem
    case restoreItem
    case deleteItem
    case deleteRecord
    case shareItemLink
    case shareItemContent
    case copyItemContent
    case addPhotos
    case movePhotoUp
    case movePhotoDown
    case removePhoto
    case exportLibrary
    case exportRecords
    case chooseImportFile
    case importSelected
    case cancel
    case save
    case done

    var body: some View {
        switch self {
        case .addItem:
            Label("Add Item", systemImage: "rectangle.stack.badge.plus")
        case .editItem:
            Label("Edit Item", systemImage: "square.and.pencil")
        case .addMark:
            Label("Add Mark", systemImage: "checkmark.circle.badge.plus")
        case .recordToday:
            Label("Record Today", systemImage: "checkmark.circle")
        case .recordNow:
            Label("Record Now with Time", systemImage: "clock")
        case .undoAddition:
            Label("Undo Last Addition", systemImage: "arrow.uturn.backward")
        case .addPeriod:
            Label("Add Period", systemImage: "calendar.badge.plus")
        case .endPeriod:
            Label("End Period", systemImage: "calendar.badge.checkmark")
        case .resumePeriod:
            Label("Resume with a new period", systemImage: "arrow.clockwise")
        case .addTag:
            Label("Add Tag", systemImage: "plus")
        case .chooseTags:
            Label("Choose Tags", systemImage: "tag")
        case .consolidateTags:
            Label("Consolidate Tags", systemImage: "arrow.triangle.merge")
        case .removeTag:
            Label("Remove Tag", systemImage: "minus.circle")
        case .deleteTag:
            Label("Delete Tag", systemImage: "trash")
        case .addFavorite:
            Label("Add to Favorites", systemImage: "star")
        case .removeFavorite:
            Label("Remove Favorite", systemImage: "star.slash")
        case .archiveItem:
            Label("Archive Item", systemImage: "archivebox")
        case .restoreItem:
            Label("Move to Library", systemImage: "tray.and.arrow.up")
        case .deleteItem:
            Label("Delete Item", systemImage: "trash")
        case .deleteRecord:
            Label("Delete Record", systemImage: "trash")
        case .shareItemLink:
            Label("Share Item Link", systemImage: "square.and.arrow.up")
        case .shareItemContent:
            Label("Share Item Content", systemImage: "square.and.arrow.up")
        case .copyItemContent:
            Label("Copy Item Content", systemImage: "doc.on.doc")
        case .addPhotos:
            Label("Add Photos", systemImage: "photo.badge.plus")
        case .movePhotoUp:
            Label("Move Photo Up", systemImage: "arrow.up")
        case .movePhotoDown:
            Label("Move Photo Down", systemImage: "arrow.down")
        case .removePhoto:
            Label("Remove Photo", systemImage: "trash")
        case .exportLibrary:
            Label("Export Library", systemImage: "square.and.arrow.up")
        case .exportRecords:
            Label("Export Records as JSON", systemImage: "doc.text")
        case .chooseImportFile:
            Label("Choose Stally File", systemImage: "square.and.arrow.down")
        case .importSelected:
            Label("Import Selected", systemImage: "square.and.arrow.down")
        case .cancel:
            Label("Cancel", systemImage: "xmark")
        case .save:
            Label("Save", systemImage: "checkmark")
        case .done:
            Label("Done", systemImage: "checkmark")
        }
    }
}
