//
//  ReviewLaneList.swift
//  Stally
//
//  Created by Codex on 2026/06/26.
//

import MHUI
import SwiftData
import SwiftUI
import TipKit

struct ReviewLaneList: View {
    @Environment(\.modelContext)
    private var modelContext
    @Environment(\.mhTheme)
    private var theme

    @State private var actionErrorMessage: String?
    @State private var selectedItemIDs = Set<UUID>()

    private let overviewTip = ReviewOverviewTip()

    let snapshot: ReviewSnapshot
    let showsCompletedSections: Bool

    private var visibleLanes: [ReviewLane] {
        ReviewLane.allCases.filter { lane in
            showsCompletedSections || !snapshot.items(in: lane).isEmpty
        }
    }

    private var selectedRequests: [ReviewActionRequest] {
        ReviewLane.allCases.flatMap { lane in
            snapshot.items(in: lane).compactMap { item in
                guard selectedItemIDs.contains(item.uuid) else {
                    return nil
                }

                return .init(item: item, lane: lane)
            }
        }
    }

    private var bulkActionTitle: LocalizedStringResource {
        let lanes = Set(selectedRequests.map(\.lane))

        if lanes == [.recoveryCandidates] {
            return "Move Selected Back to Library"
        }
        if lanes.isSubset(of: [.dormant, .needsFirstMark]) {
            return "Archive Selected"
        }
        return "Update Selected"
    }

    private var isShowingActionError: Binding<Bool> {
        .init(
            get: { actionErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    actionErrorMessage = nil
                }
            }
        )
    }

    var body: some View {
        List(selection: $selectedItemIDs) {
            TipView(overviewTip)
                .listRowSeparator(.hidden)

            ForEach(visibleLanes) { lane in
                ReviewLaneSection(
                    lane: lane,
                    items: snapshot.items(in: lane)
                ) { item in
                    performPrimaryAction(for: item, in: lane)
                }
            }
        }
        .scrollEdgeEffectStyle(.soft, for: .bottom)
        .safeAreaBar(edge: .bottom) {
            if !selectedRequests.isEmpty {
                Button(bulkActionTitle, action: performSelectedActions)
                    .buttonStyle(.mhPrimary)
                    .frame(maxWidth: theme.layout.readableContentWidth)
                    .padding(.horizontal, theme.spacing.content)
                    .padding(.vertical, theme.spacing.inline)
            }
        }
        .stallyListChrome(.content)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
                    .stallyToolbarActionStyle()
            }
        }
        .alert("Could Not Update Item", isPresented: isShowingActionError) {
            Button("OK", role: .cancel) {
                actionErrorMessage = nil
            }
        } message: {
            if let actionErrorMessage {
                Text(actionErrorMessage)
            }
        }
    }

    private func performPrimaryAction(
        for item: Item,
        in lane: ReviewLane
    ) {
        do {
            try ReviewOperations.performPrimaryAction(
                for: item,
                in: lane,
                context: modelContext
            )
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }

    private func performSelectedActions() {
        do {
            try ReviewOperations.performPrimaryActions(
                selectedRequests,
                context: modelContext
            )
            selectedItemIDs.removeAll()
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }
}
