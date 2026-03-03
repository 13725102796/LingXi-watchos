import SwiftUI
import Observation
import WidgetKit

// MARK: - 运行时全局状态（@Observable，由 LingXiApp 注入 Environment）

@Observable final class AppState {

    // MARK: - Onboarding 状态
    var hasOnboarded: Bool = LingXiKeys.hasOnboarded

    // MARK: - 实时健康状态

    var currentHR: Double = 0
    var currentHRV: Double = 0
    var lotusState: LotusState = .calm

    // MARK: - 今日活动

    var todaySteps: Int = 0
    var todayCalories: Double = 0
    var todayExercise: Int = 0
    var todayStand: Int = 0

    // MARK: - 用户档案（从 SwiftData 加载后缓存）

    var realmLevel: Int = 1
    var realmName: String = "凡心初悟"
    var cultivation: Int = 0
    var nextThreshold: Int = 100
    var spiritEnergy: Int = 0
    var totalCultivationMinutes: Int = 0

    // MARK: - 待显示弹窗（nil = 不显示）

    var pendingSleepReward: SleepRewardData?
    var pendingJourneyReward: JourneyRewardData?
    var pendingBreakthrough: BreakthroughData?
    var showHeartDemonPopup: Bool = false

    // MARK: - 从 Profile 同步状态

    func sync(from profile: CultivationProfile) {
        realmLevel = profile.realmLevel
        realmName = profile.realmName
        cultivation = profile.cultivation
        spiritEnergy = profile.spiritEnergy
        totalCultivationMinutes = profile.totalCultivationMinutes

        let loader = StaticDataLoader.shared
        nextThreshold = loader.realm(after: profile.realmLevel)?.requiredCultivation ?? 99999

        // 同步到 UserDefaults 供 Widget 读取
        LingXiKeys.realmLevel  = profile.realmLevel
        LingXiKeys.realmName   = profile.realmName
        LingXiKeys.cultivation = profile.cultivation
        LingXiKeys.nextThreshold = nextThreshold

        WidgetCenter.shared.reloadTimelines(ofKind: "LingXiComplication")
    }
}

// MARK: - 弹窗数据结构

struct SleepRewardData {
    let grade: SleepGrade
    let sleepHours: Double
    let spiritEnergyGained: Int
    let cultivationGained: Int
    let newItemIds: [String]
    let copywritingLine: String
}

struct JourneyRewardData {
    let level: JourneyLevel
    let steps: Int
    let spiritEnergyGained: Int
    let cultivationGained: Int
    let newItemIds: [String]
    let newSceneryId: String?
    let copywritingLine: String
}

struct BreakthroughData {
    let newRealmLevel: Int
    let newRealmName: String
    let newRealmStage: String
    let unlockText: String
}
