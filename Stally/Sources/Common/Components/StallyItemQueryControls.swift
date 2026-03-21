import StallyLibrary
import SwiftUI

struct StallyItemQueryControls: View {
    @Binding var query: ItemListQuery

    let displayedCount: Int
    let usesCompactLayout: Bool

    var body: some View {
        if usesCompactLayout {
            VStack(alignment: .leading, spacing: 12) {
                ViewThatFits(in: .horizontal) {
                    horizontalMenus
                    verticalMenus
                }

                HStack(spacing: 12) {
                    queryStatusLabel
                    Spacer(minLength: .zero)
                }
            }
        } else {
            HStack(alignment: .center, spacing: 12) {
                HStack(spacing: 12) {
                    categoryMenu
                    sortMenu
                }
                .stallyPanel(.elevated, padding: 10)

                Spacer(minLength: 12)

                queryStatusLabel

                if query.hasRefinements {
                    clearFiltersButton
                }
            }
        }
    }
}

private extension StallyItemQueryControls {
    var horizontalMenus: some View {
        HStack(spacing: 12) {
            categoryMenu
            sortMenu

            if query.hasRefinements {
                clearFiltersButton
            }
        }
        .stallyPanel(.elevated, padding: 10)
    }

    var verticalMenus: some View {
        VStack(alignment: .leading, spacing: 12) {
            categoryMenu
            sortMenu

            if query.hasRefinements {
                clearFiltersButton
            }
        }
        .stallyPanel(.elevated, padding: 10)
    }

    var categoryMenu: some View {
        Menu {
            Button("All Categories") {
                query.category = nil
            }

            ForEach(ItemCategory.allCases, id: \.self) { category in
                Button {
                    query.category = category
                } label: {
                    categoryMenuLabel(for: category)
                }
            }
        } label: {
            Label(
                query.category?.title ?? StallyLocalization.string("All Categories"),
                systemImage: "line.3.horizontal.decrease.circle"
            )
            .lineLimit(1)
        }
        .buttonStyle(StallySecondaryButtonStyle())
        .fixedSize(horizontal: true, vertical: false)
    }

    var sortMenu: some View {
        Menu {
            ForEach(ItemListQuery.SortOption.allCases, id: \.self) { sortOption in
                Button {
                    query.sortOption = sortOption
                } label: {
                    sortMenuLabel(for: sortOption)
                }
            }
        } label: {
            Label(
                query.sortOption.title,
                systemImage: "arrow.up.arrow.down.circle"
            )
            .lineLimit(1)
        }
        .buttonStyle(StallySecondaryButtonStyle())
        .fixedSize(horizontal: true, vertical: false)
    }

    var queryStatusLabel: some View {
        Text(
            StallyLocalization.format("%lld shown", displayedCount)
        )
        .font(.caption.weight(.semibold))
        .foregroundStyle(StallyDesign.Palette.mutedInk)
    }

    var clearFiltersButton: some View {
        Button("Clear") {
            query = .init()
        }
        .buttonStyle(StallySecondaryButtonStyle())
        .fixedSize(horizontal: true, vertical: false)
    }

    func categoryMenuLabel(
        for category: ItemCategory
    ) -> some View {
        Group {
            if query.category == category {
                Label(category.title, systemImage: "checkmark")
            } else {
                Text(category.title)
            }
        }
    }

    func sortMenuLabel(
        for sortOption: ItemListQuery.SortOption
    ) -> some View {
        Group {
            if query.sortOption == sortOption {
                Label(sortOption.title, systemImage: "checkmark")
            } else {
                Text(sortOption.title)
            }
        }
    }
}
