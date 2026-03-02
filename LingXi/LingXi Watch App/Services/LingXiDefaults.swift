import Foundation

// MARK: - App Group UserDefaults（主 App + Widget Extension 共享）
// ⚠️ 安全修复：全项目必须使用 LingXiKeys.shared，禁止使用 UserDefaults.standard
// Xcode Capability：两个 Target 均需添加 App Groups → group.com.yourteam.lingxi

enum LingXiKeys {
    // App Group 标识符（需与 Xcode Capability 配置一致）
    static let appGroupID = "group.com.yourteam.lingxi"

    // MARK: - WidgetKit 所需高频数据 Key

    static let currentRealmLevel   = "lx_realm_level"      // Int
    static let currentRealmName    = "lx_realm_name"       // String
    static let currentCultivation  = "lx_cultivation"      // Int
    static let nextRealmThreshold  = "lx_next_threshold"   // Int
    static let lotusState          = "lx_lotus_state"      // String

    // MARK: - 防抖与去重 Key

    static let lastSleepRewardDate = "lx_last_sleep_date"  // String: "yyyy-MM-dd"
    static let lastHeartDemonTime  = "lx_last_hd_time"     // Double: timestamp
    static let lastJourneyDate     = "lx_last_journey"     // String: "yyyy-MM-dd"
    static let lastHeartDemonHour  = "lx_last_hd_hour"     // String: "yyyy-MM-dd-HH"

    // MARK: - App 状态 Key

    static let hasCompletedOnboarding = "lx_onboarded"    // Bool
    static let totalJourneyDays       = "lx_journey_days" // Int

    // MARK: - 共享 UserDefaults 访问入口（全项目统一用此，禁止 .standard）

    static var shared: UserDefaults {
        // 模拟器 / Personal Team 无 App Group 时自动 fallback 到 .standard
        return UserDefaults(suiteName: appGroupID) ?? .standard
    }
}

// MARK: - 类型安全的读写封装

extension LingXiKeys {

    // MARK: Realm（带范围校验，防止 Widget 数组越界）

    static var realmLevel: Int {
        get { max(1, min(9, shared.integer(forKey: currentRealmLevel).nonZeroOr(1))) }
        set { shared.set(max(1, min(9, newValue)), forKey: currentRealmLevel) }
    }

    static var realmName: String {
        get { shared.string(forKey: currentRealmName) ?? "凡心初悟" }
        set { shared.set(newValue, forKey: currentRealmName) }
    }

    static var cultivation: Int {
        get { max(0, shared.integer(forKey: currentCultivation)) }
        set { shared.set(max(0, newValue), forKey: currentCultivation) }
    }

    static var nextThreshold: Int {
        get { max(1, shared.integer(forKey: nextRealmThreshold).nonZeroOr(100)) }
        set { shared.set(max(1, newValue), forKey: nextRealmThreshold) }
    }

    static var lotus: LotusState {
        get {
            let raw = shared.string(forKey: lotusState) ?? "calm"
            return LotusState(rawValue: raw) ?? .calm
        }
        set { shared.set(newValue.rawValue, forKey: lotusState) }
    }

    // MARK: 防抖

    static var lastSleepDate: String {
        get { shared.string(forKey: lastSleepRewardDate) ?? "" }
        set { shared.set(newValue, forKey: lastSleepRewardDate) }
    }

    static var lastJourneyDateValue: String {
        get { shared.string(forKey: lastJourneyDate) ?? "" }
        set { shared.set(newValue, forKey: lastJourneyDate) }
    }

    static var lastHeartDemonTimestamp: Double {
        get { shared.double(forKey: lastHeartDemonTime) }
        set { shared.set(newValue, forKey: lastHeartDemonTime) }
    }

    static var lastHeartDemonHourKey: String {
        get { shared.string(forKey: lastHeartDemonHour) ?? "" }
        set { shared.set(newValue, forKey: lastHeartDemonHour) }
    }

    // MARK: App 状态

    static var hasOnboarded: Bool {
        get { shared.bool(forKey: hasCompletedOnboarding) }
        set { shared.set(newValue, forKey: hasCompletedOnboarding) }
    }

    static var journeyDays: Int {
        get { max(0, shared.integer(forKey: totalJourneyDays)) }
        set { shared.set(max(0, newValue), forKey: totalJourneyDays) }
    }
}

// MARK: - 日期工具

extension LingXiKeys {
    static func todayKey() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }

    static func hourKey() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd-HH"
        return fmt.string(from: Date())
    }
}

// MARK: - Int 扩展

private extension Int {
    func nonZeroOr(_ fallback: Int) -> Int {
        self == 0 ? fallback : self
    }
}
