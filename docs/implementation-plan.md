# 灵息 LingXi — watchOS MVP 实现计划

## Context

基于 mockup.html 中的完整 PRD，灵息是一款将 Apple Watch 健康数据转化为修仙养成体验的独立 watchOS 应用。目标是在不依赖任何远程数据库的前提下，实现三大核心系统（驻颜闭关/灵台清心/云游历练）+ 修为境界成长线 + 灵物图鉴收集 + 表盘 Complication。本计划聚焦数据流转与存储设计，是后续开发的蓝图。

---

## 一、存储分层架构（全本地）

### 分层原则

| 层级 | 技术 | 数据类型 | 访问频率 |
|------|------|----------|----------|
| 静态资源 | Bundle JSON | 灵物定义、文案库、仙境元数据 | 启动时一次性加载 |
| 快速缓存 | UserDefaults | 表盘需要的实时数据、防抖时间戳 | 每秒级别 |
| 业务持久化 | SwiftData | 用户档案、历史记录、已收集灵物 | 事件驱动 |
| 健康数据 | HealthKit Store | 所有传感器数据 | 按需查询 |

### 1.1 Bundle JSON（只读静态配置）

```
Resources/
├── spirit_items.json       # 20个灵物定义（id/name/grade/source/iconName/description）
├── realms.json             # 9级境界定义（level/name/requiredCultivation/unlockText）
├── copywriting.json        # 文案库（按场景/状态分类）
└── sceneries.json          # 12幅仙境定义（id/name/unlockDays/imageName）
```

**spirit_items.json 样例：**
```json
[
  { "id": "tianshan_xuelian", "name": "天山雪莲", "grade": "仙品",
    "source": "仙品闭关", "iconName": "tianshan_xuelian", "description": "..." },
  { "id": "hundun_lingzhu", "name": "混沌灵珠", "grade": "神品",
    "source": "连续30日全达标", "iconName": "hundunlingzhu", "description": "..." }
]
```

### 1.2 UserDefaults（快速缓存，Key 定义）

```swift
// LingXiDefaults.swift
// ⚠️ 安全修复：主 App 与 Widget Extension 必须通过 App Group 共享 UserDefaults。
// Xcode → 两个 Target 均添加 App Groups Capability，ID：group.com.yourteam.lingxi
enum LingXiKeys {
    // App Group Suite Name（主 App 与 Widget Extension 共享同一容器）
    static let appGroupID = "group.com.yourteam.lingxi"

    // 表盘组件需要的高频数据（WidgetKit 读取）
    static let currentRealmLevel   = "lx_realm_level"     // Int
    static let currentRealmName    = "lx_realm_name"      // String
    static let currentCultivation  = "lx_cultivation"     // Int
    static let nextRealmThreshold  = "lx_next_threshold"  // Int
    static let lotusState          = "lx_lotus_state"     // String: calm/ripple/demon

    // 防抖与去重
    static let lastSleepRewardDate = "lx_last_sleep_date" // String: "yyyy-MM-dd"
    static let lastHeartDemonTime  = "lx_last_hd_time"    // Double: timestamp
    static let lastJourneyDate     = "lx_last_journey"    // String: "yyyy-MM-dd"
    static let lastHeartDemonHour  = "lx_last_hd_hour"    // String: "yyyy-MM-dd-HH"

    // App 状态
    static let hasCompletedOnboarding = "lx_onboarded"   // Bool
    static let totalJourneyDays       = "lx_journey_days" // Int（连续达标天数）

    // 共享 UserDefaults 访问入口（全项目统一使用此实例，禁止使用 .standard）
    static var shared: UserDefaults {
        UserDefaults(suiteName: appGroupID)!
    }
}
```

### 1.3 SwiftData 模型（持久化）

**CultivationProfile（全局唯一用户档案）**
```swift
@Model final class CultivationProfile {
    var realmLevel: Int              // 1-9
    var realmName: String            // "清心境·凝神"
    var cultivation: Int             // 累计修为
    var spiritEnergy: Int            // 当前灵气（用于未来商城）
    var consecutiveCheckInDays: Int  // 连续签到天数
    var lastCheckInDate: Date?       // 上次签到日期
    var totalCultivationTime: Int    // 灵台清明累计分钟数（成就用）
    var createdAt: Date              // 注册日期
}
```

**CollectedItem（已解锁灵物）**
```swift
@Model final class CollectedItem {
    var itemId: String       // 对应 spirit_items.json 的 id
    var obtainedDate: Date
    var obtainSource: String // "仙品闭关" / "三环全闭合" 等
}
```

**DailyRecord（每日快照，保留90天）**
```swift
@Model final class DailyRecord {
    @Attribute(.unique) var dateKey: String  // "2026-03-02"（唯一键，SwiftData 强制去重）
    var sleepHours: Double       // 0 = 未读取
    var deepSleepPercent: Double
    var sleepGrade: String       // "仙品"/"上品"/"中品"/"未入定"/"无数据"
    var steps: Int
    var activeCalories: Double
    var exerciseMinutes: Int
    var standHours: Int
    var journeyCompleted: Bool
    var spiritEnergyGained: Int
    var cultivationGained: Int
    var heartDemonCount: Int     // 当日心魔触发次数
    var lotusCalmMinutes: Int    // 灵台清明分钟数
}
```

---

## 二、数据流转架构

### 2.1 全局数据流图

```
                    ┌──────────────────────┐
                    │   HealthKit Store    │
                    │ (心率/HRV/睡眠/步数)  │
                    └──────────┬───────────┘
                               │ HKAnchoredObjectQuery
                               │ HKObserverQuery
                               ▼
                    ┌──────────────────────┐
                    │  HealthKitManager   │  ← 单例 Service
                    │  (授权/查询/监听)    │
                    └──────────┬───────────┘
                               │ async/await
                               ▼
                    ┌──────────────────────┐
                    │ CultivationEngine   │  ← 纯逻辑，无副作用
                    │ (评级算法/修为计算)  │
                    └──────────┬───────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                 ▼
   ┌──────────────────┐ ┌───────────┐ ┌────────────────┐
   │  AppState        │ │SwiftData  │ │  UserDefaults  │
   │ @Observable      │ │(持久档案) │ │  (快速缓存)    │
   │ (运行时状态)      │ └───────────┘ └────────┬───────┘
   └────────┬─────────┘                        │
            │                                  ▼
            ▼                      ┌───────────────────────┐
   ┌─────────────────┐             │  WidgetKit Timeline  │
   │   SwiftUI Views │             │  LingXiComplication  │
   │ HomeView        │             └───────────────────────┘
   │ JourneyView     │
   │ CollectionView  │
   │ Popups          │
   └─────────────────┘
```

### 2.2 心率/HRV 实时数据流（莲花系统）

```
每5秒触发（前台活跃时）
  HKAnchoredObjectQuery(heartRate) → 最新心率值 HR
  HKSampleQuery(heartRateVariabilitySDNN, limit:1) → HRV

  CultivationEngine.computeLotusState(hr: HR, hrv: HRV):
    if HR < 75 && HRV > 40  → .calm    → +1修为/10min
    elif HR < 100 && HRV > 30 → .ripple → +0.5修为/10min
    else                     → .demon  → +0修为

  AppState.lotusState = result
    → UserDefaults[lotusState] = result.rawValue (供 Widget)
    → HeartLotusView 响应动画变化

  if demon && !throttled:
    trigger HeartDemonPopup
    schedule haptic (2× .notification)
    update throttle timestamps
```

### 2.3 睡眠结算数据流（晨起闭关）

```
首次抬腕 (App 进入前台)
  检查：UserDefaults[lastSleepRewardDate] == today? → 跳过

  HealthKitManager.fetchLastNightSleep():
    HKSampleQuery(sleepAnalysis, predicate: 昨晚22:00-07:00)
    → 计算 totalHours, deepSleepPercent

  CultivationEngine.gradeSleep(hours, deepPercent):
    → SleepGrade: .immortal / .superior / .medium / .poor

  CultivationEngine.computeReward(grade):
    → spiritEnergy: Int (10/40/70/100)
    → itemIds: [String] (从 spirit_items.json 中按权重随机)

  更新持久化：
    SwiftData DailyRecord.sleepGrade = ...
    SwiftData CultivationProfile.spiritEnergy += spiritEnergy
    SwiftData CultivationProfile.cultivation += spiritEnergy/10
    CollectedItem 插入新道具

  更新缓存：
    UserDefaults[lastSleepRewardDate] = today
    UserDefaults[currentCultivation] = new value

  触发 UI：
    AppState.pendingSleepReward = SleepRewardData(...)
    → 显示 SleepRewardView 弹窗

  检查境界突破 → 若满足 → 触发 BreakthroughPopup
```

### 2.4 历练达标数据流（运动系统）

```
进入前台 or 后台刷新触发：
  HealthKitManager.fetchTodayActivity():
    steps = HKStatisticsQuery(.stepCount, today)
    calories = HKStatisticsQuery(.activeEnergyBurned, today)
    exercise = HKStatisticsQuery(.appleExerciseTime, today)
    stand = HKStatisticsQuery(.appleStandHour, today)

  CultivationEngine.evaluateJourney(steps, calories, exercise, stand):
    → JourneyLevel: .none / .basic(5000步) / .full(10000步或三环) / .legendary(连续3日)

  if journeyLevel > .none && !todayRewarded:
    unlock scenery (按累计达标次数 from UserDefaults[totalJourneyDays])
    unlock spirit items (按 journeyLevel 权重随机)
    cultivation += 20 (full: +30, legendary: +50)
    UserDefaults[totalJourneyDays] += 1
    UserDefaults[lastJourneyDate] = today
    AppState.pendingJourneyReward = JourneyRewardData(...)
    → 显示 JourneyRewardPopup
```

### 2.5 修为累计与境界突破流程

```
修为变化触发点（任意一处）:
  CultivationEngine.addCultivation(amount):
    profile.cultivation += amount
    UserDefaults[currentCultivation] = profile.cultivation

    // 检查突破
    let nextRealm = RealmsConfig.realm(after: profile.realmLevel)
    if profile.cultivation >= nextRealm.requiredCultivation:
      profile.realmLevel += 1
      profile.realmName = nextRealm.name
      UserDefaults[currentRealmLevel] = profile.realmLevel
      UserDefaults[currentRealmName] = profile.realmName
      UserDefaults[nextRealmThreshold] = nextNextRealm.requiredCultivation
      AppState.pendingBreakthrough = BreakthroughData(...)
      WidgetCenter.shared.reloadTimelines(ofKind: "LingXiComplication")
      → 触发 BreakthroughPopup + 触觉
```

---

## 三、关键 Service 设计

### 3.1 HealthKitManager（单例）

```swift
// Services/HealthKitManager.swift
@Observable final class HealthKitManager {
    // 权限申请（Onboarding 阶段调用一次）
    func requestAuthorization() async throws

    // 前台实时（HomeView 激活时开启，离开时停止）
    func startHeartRateMonitoring(handler: @escaping (Double, Double) -> Void)
    func stopHeartRateMonitoring()

    // 晨起结算（进入前台时调用）
    func fetchLastNightSleep() async -> SleepData?

    // 历练数据（JourneyView 或后台刷新调用）
    func fetchTodayActivity() async -> ActivityData

    // 后台 HRV 观察（注册 HKObserverQuery，系统推送）
    func registerHRVObserver()
}
```

### 3.2 CultivationEngine（纯函数逻辑层）

```swift
// Services/CultivationEngine.swift
struct CultivationEngine {
    // 睡眠评级
    static func gradeSleep(hours: Double, deepPercent: Double) -> SleepGrade

    // 睡眠奖励计算（spiritEnergy + itemIds）
    static func computeSleepReward(grade: SleepGrade, allItems: [SpiritItemDef]) -> SleepReward

    // 莲花状态判定
    static func computeLotusState(hr: Double, hrv: Double) -> LotusState

    // 心魔防抖判定
    static func shouldTriggerHeartDemon(currentState: LotusState) -> Bool

    // 历练等级评估
    static func evaluateJourney(steps: Int, calories: Double, exercise: Int, stand: Int,
                                 consecutiveDays: Int) -> JourneyLevel

    // 历练奖励（sceneryId + itemIds + cultivation）
    static func computeJourneyReward(level: JourneyLevel, totalDays: Int,
                                      allItems: [SpiritItemDef]) -> JourneyReward

    // 修为累加与境界突破判断
    static func checkBreakthrough(cultivation: Int, currentLevel: Int,
                                   realms: [RealmDef]) -> RealmDef?
}
```

### 3.3 AppState（运行时全局状态，@Observable）

```swift
// App/AppState.swift
@Observable final class AppState {
    // 实时健康状态
    var currentHR: Double = 0
    var currentHRV: Double = 0
    var lotusState: LotusState = .calm

    // 今日活动
    var todaySteps: Int = 0
    var todayCalories: Double = 0
    var todayExercise: Int = 0
    var todayStand: Int = 0

    // 用户档案（从 SwiftData 加载后缓存在内存）
    var realmLevel: Int = 1
    var realmName: String = "凡心初悟"
    var cultivation: Int = 0
    var nextThreshold: Int = 100

    // 待显示弹窗（nil=不显示）
    var pendingSleepReward: SleepRewardData?
    var pendingJourneyReward: JourneyRewardData?
    var pendingBreakthrough: BreakthroughData?
    var showHeartDemonPopup: Bool = false
}
```

---

## 四、项目文件结构

```
LingXi.xcodeproj
└── LingXiWatch/
    ├── App/
    │   ├── LingXiApp.swift              # @main，注入 modelContainer + AppState
    │   └── AppState.swift               # @Observable 全局运行时状态
    │
    ├── Models/                          # SwiftData 模型
    │   ├── CultivationProfile.swift
    │   ├── CollectedItem.swift
    │   └── DailyRecord.swift
    │
    ├── Services/
    │   ├── HealthKitManager.swift       # HK 授权/查询/监听
    │   ├── CultivationEngine.swift      # 纯逻辑：评级/奖励/突破算法
    │   ├── StaticDataLoader.swift       # 加载 Bundle JSON（灵物/境界/文案/仙境）
    │   └── LingXiDefaults.swift         # UserDefaults key 常量 + 读写封装
    │
    ├── Views/
    │   ├── Onboarding/
    │   │   └── OnboardingView.swift
    │   ├── Home/
    │   │   ├── HomeView.swift
    │   │   └── HeartLotusView.swift     # 动态莲花动画组件
    │   ├── Journey/
    │   │   ├── JourneyView.swift
    │   │   └── ActivityRingView.swift   # 三环组件
    │   ├── Collection/
    │   │   ├── CollectionView.swift
    │   │   └── SpiritItemCard.swift
    │   └── Popups/
    │       ├── SleepRewardView.swift
    │       ├── HeartDemonPopup.swift
    │       ├── JourneyRewardPopup.swift
    │       └── BreakthroughPopup.swift
    │
    ├── Design/
    │   ├── LingXiColors.swift           # 色彩常量（墨渊/玄夜/月白/青瓷等）
    │   ├── LingXiFonts.swift            # 字体规范
    │   └── LingXiAnimations.swift       # 动画预设（呼吸/弹入/粒子）
    │
    ├── Resources/
    │   ├── spirit_items.json
    │   ├── realms.json
    │   ├── copywriting.json
    │   └── sceneries.json
    │
    └── Assets.xcassets
        ├── spirit-items/               # 灵物图片（已存在）
        └── scenery/                    # 仙境风景图

LingXiComplication/                     # 独立 Widget Extension target
└── LingXiComplication.swift
```

---

## 五、分阶段实现计划

### Phase 1：脚手架 + 设计系统（Day 1-5）
**目标：** App 可安装到 Watch，首次启动流程完整

1. 创建 Xcode 项目（watchOS 10+ target + Widget Extension target）
2. 配置 HealthKit Capability + Background Modes (Background App Refresh)
3. **[安全修复] 配置 App Groups Capability**（两个 Target 均添加 `group.com.yourteam.lingxi`），确保主 App 与 Widget Extension 共享 UserDefaults 容器
4. 编写 `LingXiColors.swift` / `LingXiFonts.swift`（对照 mockup.html 色值）
5. 实现 `StaticDataLoader.swift`（读取4个 Bundle JSON）
6. 编写 `realms.json` / `spirit_items.json` / `copywriting.json` / `sceneries.json`
7. 实现 `OnboardingView.swift`（3屏引导 + HealthKit 授权触发）
8. 实现 TabView 主框架（HomeView / JourneyView / CollectionView 占位）
9. 配置 SwiftData modelContainer（LingXiApp.swift）

**验收：** 安装到 Watch，看到 Onboarding → 授权 → 主界面框架；在两个 Target 的 Entitlements 中均可见 App Groups 条目

---

### Phase 2：HealthKit + 核心算法（Day 6-12）
**目标：** 真机数据可读取，核心算法通过单元测试

1. `HealthKitManager.requestAuthorization()` — 7种数据类型
2. `HealthKitManager.fetchLastNightSleep()` — HKSleepAnalysis 解析
3. `HealthKitManager.startHeartRateMonitoring()` — 5秒锚点查询
4. `HealthKitManager.fetchTodayActivity()` — 步数/卡路里/运动/站立
5. `CultivationEngine` — 全部纯函数实现（可 Playground 验证）
6. `LingXiDefaults.swift` — UserDefaults 读写封装
7. `AppState.swift` — 连接 HealthKitManager 数据到运行时状态
8. 晨起结算触发逻辑（App 进前台检查）
9. 写基本单元测试（睡眠评级、莲花状态、防抖逻辑）

**验收：** 真机读到心率变化，晨起可读到昨晚睡眠数据

---

### Phase 3：完整 UI + 交互体验（Day 13-20）
**目标：** 完整日常闭环在真机运行

1. `HeartLotusView.swift` — 三态动画（calm呼吸3s / ripple1.5s / demon0.8s）
2. `HomeView.swift` — 完整布局（莲花 + 境界名 + 修为条 + 心率数值）
3. `SleepRewardView.swift` — 弹窗（道具 spring 动画 + 古风文案 + 触觉）
4. `HeartDemonPopup.swift` — 弹窗（朱砂莲脉动 + 调息跳转）
5. `JourneyView.swift` — 步数大字 + 三环 + 仙境卡片
6. `JourneyRewardPopup.swift` — 成就弹窗
7. `BreakthroughPopup.swift` — 粒子动效 + 境界展示
8. `CollectionView.swift` — 3列网格（品级光晕 + 锁定"?"）
9. 历练达标本地通知（UNUserNotificationCenter）
10. 后台 App 刷新注册（scheduleBackgroundRefresh）

**验收：** 完整一天操作闭环：晨起弹窗 → 日间莲花 → 运动弹窗 → 境界突破

---

### Phase 4：表盘组件 + 打磨（Day 21-28）
**目标：** MVP 完成，可提交 TestFlight

1. `LingXiComplication.swift` — 4种 family（Circular/Rectangular/Corner/Inline）
2. **[安全修复] 从 `LingXiKeys.shared`（App Group UserDefaults）读取缓存数据**，Widget Extension 禁止使用 `.standard`，并对读取值加范围校验（realmLevel: 1-9，cultivation ≥ 0）
3. **[性能修复] Timeline Policy 改为 30分钟刷新**（系统后台预算约4次/小时，15分钟将耗尽全部预算导致 Background App Refresh 失效）
4. 境界突破时调用 `WidgetCenter.shared.reloadTimelines(ofKind:)`
5. 权限不足降级处理（HealthKit 全拒 → 纯签到养成模式）
6. 每日签到逻辑（首次打开 +5修为，判断 lastCheckInDate）
7. DailyRecord 90天自动清理（SwiftData fetchDescriptor + delete）
8. 全机型适配测试（41mm / 45mm，重点适配小屏）
9. 性能验证：冷启动 <2s，莲花动画 60fps，内存 <25MB

**验收：** 表盘可添加 4 种组件，所有弹窗边界情况处理正确

---

## 六、关键技术决策

### 为什么不用 iCloud / CloudKit？
- MVP 不需要跨设备同步（Watch 纯独立应用）
- HealthKit 数据本身由系统同步（iCloud 健康 App）
- 减少 App Store 审核风险，无网络权限声明

### 为什么 SwiftData 而非 CoreData？
- SwiftUI + @Observable 原生集成，代码量少 60%
- watchOS 10+ 完全支持
- 迁移（schema migration）对 MVP 阶段够用

### UserDefaults 为何存修为值（与 SwiftData 重复）？
- WidgetKit Extension 是独立进程，无法直接访问 main App 的 SwiftData
- Widget 必须从 UserDefaults / App Group 读取数据
- 写入 SwiftData 后，同步写 UserDefaults（双写策略，以 SwiftData 为 source of truth）

### 心率监听为何不用后台？
- watchOS 后台心率监听需要特殊 Entitlement（Apple 审核严格）
- MVP 阶段：前台5秒轮询已足够莲花动态效果
- 心魔防抖（同小时最多1次）减少误触发

---

## 七、验证方式

1. **真机安装测试：** iPhone + Watch 同 Apple ID，Xcode → Run on Device
2. **睡眠数据测试：** 在 iOS Health App 手动添加昨晚睡眠记录，验证晨起弹窗
3. **心率测试：** 快走后打开 App，验证莲花从 calm → ripple → demon 变化
4. **步数测试：** 步行达 5000/10000 步，验证历练弹窗触发
5. **境界突破测试：** 临时修改 `CultivationEngine` 中的修为阈值为 1，验证粒子动效
6. **表盘测试：** 进入表盘编辑，添加 LingXi 组件，验证4种 family 显示
7. **权限拒绝测试：** 在设置中关闭 HealthKit 权限，验证降级模式
8. **内存测试：** Xcode Instruments → Allocations，运行10分钟验证无泄漏

---

## 八、关键文件路径

| 文件 | 路径 |
|------|------|
| 原型 HTML | `mockup.html` / `prototype.html` |
| 开发指南 | `docs/watchos-dev-guide.md` |
| watchOS Skill | `.claude/skills/watchos-dev/SKILL.md` |
| 灵物图片 | `assets/images/spirit-items/` |
| 风景图片 | `assets/images/scenery/` |
| 项目记忆 | `memory/MEMORY.md` |

---

## 九、安全审查记录（prd-security-audit）

> 由 `prd-security-audit` Skill 于 2026-03-02 执行，依据 GitHub 开源参考项目对比分析。

| # | 严重程度 | 问题描述 | 修复位置 | 状态 |
|---|---------|---------|---------|------|
| 1 | 🔴 严重 | Widget Extension 无法读取主 App `UserDefaults.standard`，需配置 App Group | Phase 1 Step 3 + `LingXiDefaults.swift` | ✅ 已修复 |
| 2 | 🟡 中 | `DailyRecord.dateKey` 缺少 `@Attribute(.unique)` 约束，重复插入会造成数据重复 | `DailyRecord.swift` 模型定义 | ✅ 已修复 |
| 3 | 🟡 中 | Complication 15分钟刷新耗尽后台预算，导致 Background App Refresh 失效 | Phase 4 Step 3 | ✅ 已修复 |
| 4 | 🟡 低 | `DailyRecord.lotusCalmMinutes` 变量名 typo（中间有空格，编译报错） | 模型定义 L104 | ✅ 已修复 |
| 5 | 🟢 建议 | Widget 读取 UserDefaults 值应加范围校验，防止数据注入导致数组越界 | Phase 4 Step 2 | ✅ 已修复 |

**参考项目：**
- [Gym-Routine-Tracker-Watch-App](https://github.com/open-trackers/Gym-Routine-Tracker-Watch-App) — 独立 watchOS 架构参考
- [brush](https://github.com/BastiaanJansen/brush) — HealthKit + Apple Watch 参考
- Apple Developer Forums: [App Group shared user defaults](https://developer.apple.com/forums/thread/710966)
