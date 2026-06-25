//
//  EmptyArchiveView.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import SwiftUI

struct EmptyArchiveView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No Archived Items", systemImage: "archivebox")
        } description: {
            Text("Past favorites can stay nearby without crowding the main list.")
        }
    }
}
