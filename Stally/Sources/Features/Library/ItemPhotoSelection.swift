//
//  ItemPhotoSelection.swift
//  Stally
//
//  Created by Codex on 2026/07/13.
//

import CoreTransferable
import Foundation
import UniformTypeIdentifiers

struct ItemPhotoSelection: Transferable, Sendable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            .init(data: data)
        }
    }

    let data: Data
}
