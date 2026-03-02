import SwiftData
import Foundation

@Model final class CollectedItem {
    var itemId: String       // 对应 spirit_items.json 的 id
    var obtainedDate: Date
    var obtainSource: String // "仙品闭关" / "三环全闭合" 等

    init(itemId: String, obtainSource: String) {
        self.itemId = itemId
        self.obtainedDate = Date()
        self.obtainSource = obtainSource
    }
}
