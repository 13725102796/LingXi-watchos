import SwiftData
import Foundation

@Model final class DailyRecord {
    @Attribute(.unique) var dateKey: String  // "2026-03-02"（唯一键，SwiftData 强制去重）

    // 睡眠
    var sleepHours: Double       // 0 = 未读取
    var deepSleepPercent: Double
    var sleepGrade: String       // "仙品"/"上品"/"中品"/"未入定"/"无数据"

    // 运动
    var steps: Int
    var activeCalories: Double
    var exerciseMinutes: Int
    var standHours: Int
    var journeyCompleted: Bool

    // 奖励
    var spiritEnergyGained: Int
    var cultivationGained: Int

    // 灵台
    var heartDemonCount: Int     // 当日心魔触发次数
    var lotusCalmMinutes: Int    // 灵台清明分钟数

    init(dateKey: String) {
        self.dateKey = dateKey
        self.sleepHours = 0
        self.deepSleepPercent = 0
        self.sleepGrade = "无数据"
        self.steps = 0
        self.activeCalories = 0
        self.exerciseMinutes = 0
        self.standHours = 0
        self.journeyCompleted = false
        self.spiritEnergyGained = 0
        self.cultivationGained = 0
        self.heartDemonCount = 0
        self.lotusCalmMinutes = 0
    }
}
