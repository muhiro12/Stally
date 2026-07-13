//
//  ItemPhotoSelectionLoader.swift
//  Stally
//
//  Created by Codex on 2026/07/13.
//

import Foundation
import PhotosUI
import SwiftUI

enum ItemPhotoSelectionLoader {
    nonisolated static func load(_ photoItem: PhotosPickerItem) async throws -> Data {
        guard let selection = try await photoItem.loadTransferable(type: ItemPhotoSelection.self) else {
            throw ItemValidationError.photoUnreadable
        }

        try Task.checkCancellation()
        return try await prepare(selection.data)
    }

    nonisolated private static func prepare(_ data: Data) async throws -> Data {
        let preparationTask = Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            return try ItemPhotoOperations.prepare(data)
        }

        return try await withTaskCancellationHandler {
            try await preparationTask.value
        } onCancel: {
            preparationTask.cancel()
        }
    }
}
