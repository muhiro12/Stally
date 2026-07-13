import Foundation
@testable import StallyLibrary
import Testing

struct LocalizedResourceTests {
    @Test
    func package_resources_resolve_in_japanese() {
        #expect(localized(ItemCategory.notebooks.title, locale: "ja") == "ノート")
        #expect(localized(ReviewLane.needsFirstMark.title, locale: "ja") == "最初のマーク待ち")
        #expect(
            localized(ReviewLane.dormant.summary, locale: "ja")
                == "最後のマークから少し時間が経ち、見直してもよさそうなアイテム。"
        )
        #expect(localized(InsightsRange.thirtyDays.title, locale: "ja") == "30日")
        #expect(localized(ItemCollectionFilter.markedOnDay.title, locale: "ja") == "指定日にマーク済み")
        #expect(localized(ItemCollectionSort.mostMarked.title, locale: "ja") == "マーク数の多い順")
        #expect(
            localized(InsightRecommendationKind.revisitQuietFavorites.title, locale: "ja")
                == "静かなお気に入りを見直す"
        )
        #expect(
            localized(BackupValidationIssue(kind: .duplicateItemID).title, locale: "ja")
                == "重複したアイテムID"
        )
        #expect(localized(StallyLinkDestination.library.title, locale: "ja") == "ライブラリ")
    }

    private func localized(
        _ resource: LocalizedStringResource,
        locale identifier: String
    ) -> String {
        var localizedResource = resource
        localizedResource.locale = .init(identifier: identifier)
        return String(localized: localizedResource)
    }
}
