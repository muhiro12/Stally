import FoundationModels

@Generable
struct GeneratedItemDateClassification {
    @Guide(description: "対象の日付に何をしたと述べているか、その動作・出来事を原文からそのまま抜き出す。なければ空文字。")
    var action: String
    @Guide(
        description: "対象の日付が表す出来事。年式、修理、交換、既に所有していた時点、予定、不明な日付は対象外。",
        .anyOf(["購入", "注文", "到着", "使用開始", "使用継続", "終了", "対象外"])
    )
    var event: String
    @Guide(description: "対象日付の出来事は対象アイテム自身についてか、別の品物についてか。", .anyOf(["対象アイテム", "別の物"]))
    var subject: String
    @Guide(description: "対象日付からの使用が今も続いていると原文に明記されていればtrue。現在の状態が書かれていなければfalse。")
    var isOngoing: Bool

    var role: ItemInputDateRole {
        switch event {
        case "購入":
            .purchase
        case "注文":
            .order
        case "到着":
            .delivery
        case "使用開始", "使用継続":
            isOngoing ? .ongoingStart : .start
        case "終了":
            .end
        default:
            .irrelevant
        }
    }
}
