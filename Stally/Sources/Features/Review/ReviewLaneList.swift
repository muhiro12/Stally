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
    @Environment(RemoteUpdateOperations.self)
    private var remoteUpdates
    @Environment(\.modelContext)
    private var modelContext

    @State private var actionErrorMessage: String?
    @State private var selectedItemIDs = Set<UUID>()

    #if os(iOS) || os(visionOS)
    @State private var editMode = EditMode.inactive
    #endif

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

    private var bulkActionSystemImage: String {
        let lanes = Set(selectedRequests.map(\.lane))

        if lanes == [.recoveryCandidates] {
            return "tray.and.arrow.up"
        }
        if lanes.isSubset(of: [.dormant, .needsFirstMark]) {
            return "archivebox"
        }
        return "checkmark.circle"
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
        .stallyListChrome(.content)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if !selectedRequests.isEmpty {
                    Button(action: performSelectedActions) {
                        Label {
                            Text(bulkActionTitle)
                        } icon: {
                            Image(systemName: bulkActionSystemImage)
                        }
                    }
                    .stallyToolbarActionStyle()
                }
            }

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
        #if os(iOS) || os(visionOS)
        .environment(\.editMode, $editMode)
        #endif
    }

    private func performPrimaryAction(
        for item: Item,
        in lane: ReviewLane
    ) {
        Task {
            do {
                try await remoteUpdates.checkMutationAllowed()
                try ReviewOperations.performPrimaryAction(
                    for: item,
                    in: lane,
                    context: modelContext
                )
            } catch {
                actionErrorMessage = error.localizedDescription
            }
        }
    }

    private func performSelectedActions() {
        let requests = selectedRequests
        Task {
            do {
                try await remoteUpdates.checkMutationAllowed()
                try ReviewOperations.performPrimaryActions(
                    requests,
                    context: modelContext
                )
                selectedItemIDs.subtract(requests.map(\.item.uuid))
            } catch {
                actionErrorMessage = error.localizedDescription
            }
        }
    }
}
