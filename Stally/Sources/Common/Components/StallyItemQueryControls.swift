import MHUI
import StallyLibrary
import SwiftUI

struct StallyItemQueryControls: View {
    private enum ControlID: String, Sendable {
        case category
        case sort
        case clear
    }

    @Environment(\.stallyMHUIThemeMetrics)
    private var theme

    @Namespace private var compactHorizontalMenuNamespace
    @Namespace private var compactVerticalMenuNamespace
    @Namespace private var regularMenuNamespace

    @Binding var query: ItemListQuery

    let displayedCount: Int
    let usesCompactLayout: Bool

    var body: some View {
        if usesCompactLayout {
            VStack(alignment: .leading, spacing: theme.spacing.control) {
                ViewThatFits(in: .horizontal) {
                    horizontalMenus
                    verticalMenus
                }

                HStack(spacing: theme.spacing.control) {
                    queryStatusLabel
                    Spacer(minLength: .zero)
                }
            }
        } else {
            HStack(alignment: .center, spacing: theme.spacing.control) {
                StallyGlassContainer(spacing: theme.spacing.control) {
                    HStack(spacing: theme.spacing.control) {
                        categoryMenu
                            .stallyGlassEffectID(
                                ControlID.category,
                                in: regularMenuNamespace
                            )
                        sortMenu
                            .stallyGlassEffectID(
                                ControlID.sort,
                                in: regularMenuNamespace
                            )
                    }
                }

                Spacer(minLength: theme.spacing.control)

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
        StallyGlassContainer(spacing: theme.spacing.control) {
            HStack(spacing: theme.spacing.control) {
                categoryMenu
                    .stallyGlassEffectID(
                        ControlID.category,
                        in: compactHorizontalMenuNamespace
                    )
                sortMenu
                    .stallyGlassEffectID(
                        ControlID.sort,
                        in: compactHorizontalMenuNamespace
                    )

                if query.hasRefinements {
                    clearFiltersButton
                        .stallyGlassEffectID(
                            ControlID.clear,
                            in: compactHorizontalMenuNamespace
                        )
                }
            }
        }
    }

    var verticalMenus: some View {
        StallyGlassContainer(spacing: theme.spacing.control) {
            VStack(alignment: .leading, spacing: theme.spacing.control) {
                categoryMenu
                    .stallyGlassEffectID(
                        ControlID.category,
                        in: compactVerticalMenuNamespace
                    )
                sortMenu
                    .stallyGlassEffectID(
                        ControlID.sort,
                        in: compactVerticalMenuNamespace
                    )

                if query.hasRefinements {
                    clearFiltersButton
                        .stallyGlassEffectID(
                            ControlID.clear,
                            in: compactVerticalMenuNamespace
                        )
                }
            }
        }
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
        .buttonStyle(.mhSecondary)
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
        .buttonStyle(.mhSecondary)
        .fixedSize(horizontal: true, vertical: false)
    }

    var queryStatusLabel: some View {
        Text(
            StallyLocalization.format("%lld shown", displayedCount)
        )
        .mhRowSupporting()
    }

    var clearFiltersButton: some View {
        Button("Clear") {
            query = .init()
        }
        .buttonStyle(.mhSecondary)
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
