import SwiftData
import Foundation

@Model final class CultivationProfile {
    var realmLevel: Int              // 1-9
    var realmName: String            // "清心凝神"
    var cultivation: Int             // 累计修为点数
    var spiritEnergy: Int            // 当前灵气（灵物收集货币）
    var consecutiveCheckInDays: Int  // 连续签到天数
    var lastCheckInDate: Date?       // 上次签到日期
    var totalCultivationMinutes: Int // 灵台清明累计分钟数
    var createdAt: Date              // 入道日期

    init() {
        self.realmLevel = 1
        self.realmName = "凡心初悟"
        self.cultivation = 0
        self.spiritEnergy = 0
        self.consecutiveCheckInDays = 0
        self.lastCheckInDate = nil
        self.totalCultivationMinutes = 0
        self.createdAt = Date()
    }
}
