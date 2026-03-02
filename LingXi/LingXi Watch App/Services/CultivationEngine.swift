import Foundation

// MARK: - CultivationEngine（纯函数逻辑层，无副作用，可单元测试）

struct CultivationEngine {

    // MARK: - 睡眠评级

    /// 根据睡眠时长和深睡比例评级
    static func gradeSleep(hours: Double, deepPercent: Double) -> SleepGrade {
        guard hours > 0 else { return .noData }
        switch (hours, deepPercent) {
        case (7.5..., 0.2...):  return .immortal  // 7.5h+ 且深睡≥20%
        case (6.5..., 0.15...): return .superior  // 6.5h+ 且深睡≥15%
        case (5.5..., _):       return .medium    // 5.5h+
        default:                return .poor      // 不足5.5h
        }
    }

    // MARK: - 睡眠奖励

    struct SleepReward {
        let spiritEnergy: Int
        let cultivationGain: Int
        let itemIds: [String]
    }

    static func computeSleepReward(grade: SleepGrade,
                                    allItems: [SpiritItemDef]) -> SleepReward {
        let energy = grade.spiritEnergyReward
        let cultivation = energy / 10

        // 按品级过滤可获得灵物
        let pool: [SpiritItemDef]
        switch grade {
        case .immortal:
            pool = allItems.filter { $0.gradeRank >= 4 }
        case .superior:
            pool = allItems.filter { $0.gradeRank >= 3 }
        case .medium:
            pool = allItems.filter { $0.gradeRank >= 2 }
        case .poor, .noData:
            pool = allItems.filter { $0.gradeRank <= 2 }
        }

        let itemCount = grade == .immortal ? 2 : 1
        let items = StaticDataLoader.shared.randomItems(from: pool, count: itemCount)

        return SleepReward(spiritEnergy: energy, cultivationGain: cultivation, itemIds: items)
    }

    // MARK: - 莲花状态判定

    /// 根据心率和 HRV 判定莲花状态
    /// calm: HR<75 且 HRV>40 → 平静态 +1修为/10min
    /// ripple: HR<100 且 HRV>30 → 波动态 +0.5修为/10min
    /// demon: 其余 → 心魔态 +0修为
    static func computeLotusState(hr: Double, hrv: Double) -> LotusState {
        guard hr > 0 else { return .calm }  // 无数据时默认平静
        if hr < 75 && hrv > 40 { return .calm }
        if hr < 100 && hrv > 30 { return .ripple }
        return .demon
    }

    // MARK: - 心魔防抖判定

    /// 同一小时内最多触发1次心魔弹窗
    static func shouldTriggerHeartDemon(currentState: LotusState) -> Bool {
        guard currentState == .demon else { return false }
        let currentHour = LingXiKeys.hourKey()
        let lastHour = LingXiKeys.lastHeartDemonHourKey
        return currentHour != lastHour
    }

    static func markHeartDemonTriggered() {
        LingXiKeys.lastHeartDemonHourKey = LingXiKeys.hourKey()
        LingXiKeys.lastHeartDemonTimestamp = Date().timeIntervalSince1970
    }

    // MARK: - 历练评估

    struct ActivityData {
        let steps: Int
        let calories: Double
        let exerciseMinutes: Int
        let standHours: Int
    }

    /// 评估历练等级
    static func evaluateJourney(_ data: ActivityData, consecutiveDays: Int) -> JourneyLevel {
        let threeRingsClosed = data.calories >= 400 && data.exerciseMinutes >= 30 && data.standHours >= 12
        let steps10k = data.steps >= 10_000

        if consecutiveDays >= 3 && (threeRingsClosed || steps10k) {
            return .legendary
        }
        if threeRingsClosed || steps10k {
            return .full
        }
        if data.steps >= 5_000 || data.exerciseMinutes >= 30 {
            return .basic
        }
        return .none
    }

    // MARK: - 历练奖励

    struct JourneyReward {
        let spiritEnergy: Int
        let cultivationGain: Int
        let itemIds: [String]
        let sceneryId: String?
    }

    static func computeJourneyReward(level: JourneyLevel,
                                      totalDays: Int,
                                      allItems: [SpiritItemDef]) -> JourneyReward {
        let cultivation = level.cultivationReward
        let energy = cultivation * 2

        let pool: [SpiritItemDef]
        switch level {
        case .legendary:
            pool = allItems.filter { $0.gradeRank >= 4 }
        case .full:
            pool = allItems.filter { $0.gradeRank >= 2 }
        case .basic:
            pool = allItems.filter { $0.gradeRank <= 3 }
        case .none:
            return JourneyReward(spiritEnergy: 0, cultivationGain: 0, itemIds: [], sceneryId: nil)
        }

        let itemCount = level == .legendary ? 2 : 1
        let items = StaticDataLoader.shared.randomItems(from: pool, count: itemCount)

        // 按累计达标天数解锁仙境
        let availableSceneries = StaticDataLoader.shared.unlockedSceneries(journeyDays: totalDays)
        let newScenery = availableSceneries.last(where: { $0.unlockDays == totalDays })

        return JourneyReward(spiritEnergy: energy,
                              cultivationGain: cultivation,
                              itemIds: items,
                              sceneryId: newScenery?.id)
    }

    // MARK: - 修为累加与境界突破检查

    /// 检查是否满足境界突破条件，返回新境界（nil = 未突破）
    static func checkBreakthrough(cultivation: Int,
                                   currentLevel: Int,
                                   realms: [RealmDef]) -> RealmDef? {
        guard let nextRealm = realms.first(where: { $0.level == currentLevel + 1 }),
              cultivation >= nextRealm.requiredCultivation else {
            return nil
        }
        return nextRealm
    }

    // MARK: - 每日签到奖励

    static func computeCheckInReward(consecutiveDays: Int) -> Int {
        switch consecutiveDays {
        case 0:     return 5    // 首次
        case 1...6: return 5    // 普通签到
        case 7:     return 20   // 7日奖励
        case 8...:  return 5    // 继续
        default:    return 5
        }
    }
}
