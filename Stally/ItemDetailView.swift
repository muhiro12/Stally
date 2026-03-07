//
//  ItemDetailView.swift
//  Stally
//
//  Created by Hiromu Nakano on 2026/03/07.
//

import SwiftData
import SwiftUI

struct ItemDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let item: TrackedItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.name)
                        .font(.title2.weight(.semibold))

                    Text("最終記録 \(item.lastCountedAtText)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 10) {
                    Text("合計")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(item.totalCount.formatted())
                            .font(.system(size: 56, weight: .semibold))
                            .monospacedDigit()

                        Text("回")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemBackground))
                )

                Button {
                    recordCount()
                } label: {
                    Text("+1 を記録")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                VStack(alignment: .leading, spacing: 16) {
                    Text("履歴")
                        .font(.headline)

                    if item.sortedCountEntries.isEmpty {
                        Text("まだ記録がありません")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(item.sortedCountEntries.enumerated()), id: \.element) { index, entry in
                                HStack {
                                    Text(StallyDateFormatting.timestampText(for: entry.countedAt))
                                        .font(.body)
                                    Spacer()
                                    Text("+1")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 14)

                                if index < item.sortedCountEntries.count - 1 {
                                    Divider()
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("詳細")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func recordCount() {
        withAnimation {
            item.recordCount()
            try? modelContext.save()
        }
    }
}
