# watchOS 开发指南（Q&A）

> 适用于 watchOS 10+ / SwiftUI，基于 Apple HIG 与社区最佳实践整理

---

## 一、项目结构与入门

### Q1：Apple Watch 应用必须使用什么框架？

**A：SwiftUI + Swift，这是唯一的现代选择。**

- watchOS 7+ 后，Apple 全面推动 SwiftUI；WatchKit（UIKit 风格）仍可用但不推荐新项目使用
- Xcode 创建 watchOS target 时默认生成 SwiftUI 项目
- 可选：纯 watchOS 独立 App（不依赖 iPhone companion），或带 iOS companion 的双 target 项目

```swift
// 入口结构
@main
struct LingXiApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Q2：Xcode 项目结构如何组织？

**A：推荐分层目录结构**

```
LingXiApp/
├── App/
│   ├── LingXiApp.swift          # @main 入口
│   └── AppDelegate.swift        # (可选) 生命周期处理
├── Views/
│   ├── Home/
│   │   └── HomeView.swift
│   ├── Cultivation/
│   │   └── CultivationView.swift
│   └── Components/
│       └── RingView.swift
├── Models/
│   └── PlayerState.swift
├── Services/
│   ├── HealthKitService.swift
│   └── WatchConnectivityService.swift
├── Complications/              # WidgetKit complications
│   └── LingXiComplication.swift
└── Assets.xcassets
```

---

## 二、屏幕尺寸与设计约束

### Q3：Apple Watch 的屏幕尺寸有哪些？应该怎么适配？

**A：共 5 种主要尺寸，优先设计 45mm/49mm。**

| 型号 | 分辨率 | 逻辑点 | 备注 |
|------|--------|--------|------|
| 38mm (Series 1-3) | 272×340 | 136×170 pt | 几乎不需要支持 |
| 40mm (Series 4-6, SE) | 324×394 | 162×197 pt | 仍需兼容 |
| 41mm (Series 7-10) | 352×430 | 176×215 pt | 主流 |
| 44mm (Series 4-6) | 368×448 | 184×224 pt | 主流 |
| 45mm (Series 7-10) | 396×484 | 198×242 pt | 主流 |
| 49mm (Ultra) | 410×502 | 205×251 pt | 顶配 |

**适配技巧：**
```swift
// 用 GeometryReader 获取实际尺寸
struct AdaptiveView: View {
    var body: some View {
        GeometryReader { geo in
            VStack {
                Text("主内容")
                    .font(geo.size.width < 170 ? .footnote : .body)
            }
        }
    }
}

// 或用 WKInterfaceDevice 判断尺寸类别
let screenWidth = WKInterfaceDevice.current().screenBounds.width
```

### Q4：watchOS UI 设计的核心原则是什么？

**A：「一瞥即得」（Glanceable）——3秒内获取信息，5秒内完成操作。**

- **信息密度低**：每屏只展示最关键的 1-2 条信息
- **字体要大**：最小使用 `.footnote` (13pt)，主要内容用 `.body` 或以上
- **触控目标大**：最小 44×44 pt（Apple HIG 要求）
- **避免深层导航**：最多 3 层，优先平铺而非嵌套
- **深色优先**：watchOS 天然黑色背景，避免大面积亮色

---

## 三、导航模式

### Q5：watchOS 的三种导航模式各适合什么场景？

**A：根据内容结构选择。**

#### 1. TabView（垂直页面式）— 推荐首选
适合：并列的主功能模块（2-5个）

```swift
struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("首页", systemImage: "house") }

            CultivationView()
                .tabItem { Label("修炼", systemImage: "flame") }

            InventoryView()
                .tabItem { Label("背包", systemImage: "bag") }
        }
        .tabViewStyle(.verticalPage)  // watchOS 10+ 推荐
    }
}
```

#### 2. NavigationStack — 线性流程
适合：详情页、设置流程、向导式操作

```swift
struct ShopView: View {
    var body: some View {
        NavigationStack {
            List(items) { item in
                NavigationLink(item.name) {
                    ItemDetailView(item: item)
                }
            }
            .navigationTitle("商店")
        }
    }
}
```

#### 3. NavigationSplitView — 列表+详情
适合：有强烈主列表/详情关系的内容（watchOS 10+）

```swift
struct QuestView: View {
    @State private var selectedQuest: Quest?

    var body: some View {
        NavigationSplitView {
            List(quests, selection: $selectedQuest) { quest in
                Text(quest.name)
            }
        } detail: {
            if let quest = selectedQuest {
                QuestDetailView(quest: quest)
            }
        }
    }
}
```

**选择原则：**
- 2-4个并列功能 → `TabView(.verticalPage)`
- 列表钻入详情 → `NavigationStack`
- 主列表+详情联动 → `NavigationSplitView`
- 避免三者混用

---

## 四、Digital Crown（数字表冠）

### Q6：如何使用 Digital Crown 交互？

**A：用 `digitalCrownRotation` modifier 绑定数值。**

```swift
struct CultivationView: View {
    @State private var cultivationLevel: Double = 0
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack {
            Text("修为: \(Int(cultivationLevel))")
                .font(.title2)

            ProgressView(value: cultivationLevel, total: 100)
        }
        .focusable()                           // 必须设置才能接收 Crown 输入
        .digitalCrownRotation(
            $cultivationLevel,
            from: 0,
            through: 100,
            by: 1,
            sensitivity: .medium,             // .low / .medium / .high
            isContinuous: false,              // 是否循环
            isHapticFeedbackEnabled: true     // 震动反馈
        )
        .onAppear { isFocused = true }
    }
}
```

**最佳实践：**
- 只在当前主视图上设置 `focusable()`，避免多个 View 同时竞争 Crown
- `sensitivity` 根据数值范围调整：大范围用 `.low`，精细调节用 `.high`
- 滚动列表默认已使用 Crown，不需要额外处理

---

## 五、Complications（表盘复杂功能）

### Q7：如何添加 Watch Face Complications？

**A：使用 WidgetKit 实现，watchOS 9+ 统一了 Complication 和 Widget 接口。**

```swift
// Complications/LingXiComplication.swift
import WidgetKit
import SwiftUI

// 1. 定义 Timeline Entry
struct CultivationEntry: TimelineEntry {
    let date: Date
    let cultivationLevel: Int
    let spiritPower: String
}

// 2. 定义 Provider
struct CultivationProvider: TimelineProvider {
    func placeholder(in context: Context) -> CultivationEntry {
        CultivationEntry(date: Date(), cultivationLevel: 50, spiritPower: "练气期")
    }

    func getSnapshot(in context: Context, completion: @escaping (CultivationEntry) -> Void) {
        completion(CultivationEntry(date: Date(), cultivationLevel: 72, spiritPower: "筑基期"))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CultivationEntry>) -> Void) {
        let entry = CultivationEntry(date: Date(), cultivationLevel: 72, spiritPower: "筑基期")
        // 1小时后刷新
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// 3. 定义 Widget View（适配各种 Complication 家族）
struct LingXiComplicationEntryView: View {
    var entry: CultivationProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            // 圆形小组件
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Text("\(entry.cultivationLevel)")
                        .font(.system(size: 16, weight: .bold))
                    Text("修为")
                        .font(.system(size: 9))
                }
            }
        case .accessoryRectangular:
            // 矩形组件
            VStack(alignment: .leading) {
                Text("灵息")
                    .font(.headline)
                Text(entry.spiritPower)
                    .font(.body)
                Text("修为 \(entry.cultivationLevel)/100")
                    .font(.caption)
            }
        case .accessoryCorner:
            // 角落组件
            Text("\(entry.cultivationLevel)")
                .widgetLabel("修为")
        default:
            Text("\(entry.cultivationLevel)")
        }
    }
}

// 4. 注册 Widget
@main
struct LingXiComplication: Widget {
    let kind: String = "LingXiComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CultivationProvider()) { entry in
            LingXiComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("灵息修炼")
        .description("显示当前修为进度")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner
        ])
    }
}
```

**注意：**
- Complication 更新频率受系统限制（每天约 50 次预算）
- 使用 `WidgetKit.reloadTimelines(ofKind:)` 从主 App 触发刷新
- watchOS 9 起只剩 4 个 family：`.accessoryCircular`、`.accessoryRectangular`、`.accessoryCorner`、`.accessoryInline`

---

## 六、HealthKit 健康数据

### Q8：如何集成 HealthKit？

**A：分三步：申请权限 → 读写数据 → 处理后台更新。**

**步骤 1：Info.plist 添加权限描述**
```xml
<key>NSHealthShareUsageDescription</key>
<string>灵息需要读取您的心率数据来计算修炼强度</string>
<key>NSHealthUpdateUsageDescription</key>
<string>灵息需要记录修炼锻炼数据</string>
```

**步骤 2：Capabilities 开启 HealthKit**

**步骤 3：代码实现**
```swift
import HealthKit

class HealthKitService: ObservableObject {
    private let store = HKHealthStore()

    // 申请权限
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.workoutType()
        ]

        try await store.requestAuthorization(toShare: typesToWrite, read: typesToRead)
    }

    // 查询心率
    func fetchLatestHeartRate() async -> Double? {
        let type = HKQuantityType(.heartRate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
            // handle samples
        }
        store.execute(query)
        return nil
    }
}
```

---

## 七、Watch Connectivity（与 iPhone 通信）

### Q9：Apple Watch 如何与 iPhone 同步数据？

**A：使用 `WatchConnectivity` 框架的 `WCSession`。**

```swift
import WatchConnectivity

class WatchConnectivityService: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityService()
    @Published var receivedData: [String: Any] = [:]

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // 发送消息到 iPhone（实时，需双方都在前台）
    func sendMessage(_ data: [String: Any]) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(data, replyHandler: nil)
    }

    // 更新 ApplicationContext（最新状态同步，不需要实时）
    func updateContext(_ data: [String: Any]) {
        try? WCSession.default.updateApplicationContext(data)
    }

    // 接收 iPhone 发来的消息
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            self.receivedData = message
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    // iOS only
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif
}
```

**三种通信方式对比：**

| 方式 | 时机 | 适用场景 |
|------|------|----------|
| `sendMessage` | 实时，双方需在线 | 即时指令 |
| `updateApplicationContext` | 后台，单向覆盖 | 状态同步（推荐） |
| `transferUserInfo` | 后台队列，保序 | 批量数据传输 |
| `transferFile` | 后台大文件 | 图片、音频 |

---

## 八、后台任务与电池优化

### Q10：watchOS 的后台任务有哪些限制？

**A：watchOS 后台极为受限，只有 4 种合法后台模式。**

| 模式 | API | 适用场景 | 限制 |
|------|-----|----------|------|
| App 刷新 | `WKApplicationRefreshBackgroundTask` | 定期更新数据 | 每天约 50 次，系统调度 |
| Workout | `HKWorkoutSession` | 运动追踪 | 需 HealthKit 权限 |
| 扩展运行时 | `WKExtendedRuntimeSession` | 冥想、理疗等 | 需申请特殊 Entitlement |
| URL 后台下载 | `URLSession` background | 文件下载 | 系统调度 |

```swift
// 请求后台 App 刷新
func scheduleBackgroundRefresh() {
    let fireDate = Date().addingTimeInterval(60 * 60) // 1小时后
    WKExtension.shared().scheduleBackgroundRefresh(
        withPreferredDate: fireDate,
        userInfo: nil
    ) { error in
        if let error { print("Schedule failed: \(error)") }
    }
}

// 处理后台任务（AppDelegate 或 @main App）
func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
    for task in backgroundTasks {
        switch task {
        case let refreshTask as WKApplicationRefreshBackgroundTask:
            // 执行数据更新（时间极短，< 15秒）
            updateData()
            refreshTask.setTaskCompletedWithSnapshot(false)
        default:
            task.setTaskCompletedWithSnapshot(false)
        }
    }
}
```

**电池优化原则：**
- 避免在 App 活跃时持续使用 GPS、心率传感器
- 用 `WidgetKit` 而非定时器更新 Complication
- 后台任务必须在 15 秒内完成并调用 `setTaskCompleted`
- 使用 `URLSession` 而非自定义 socket 进行网络请求

---

## 九、常见坑与反模式

### Q11：watchOS 开发有哪些常见错误？

**A：以下是最高频的 10 个坑。**

#### 坑 1：在 Watch 上做复杂导航
```swift
// ❌ 错误：超过 3 层嵌套导航
NavigationStack {
    → ListView → DetailView → SubDetailView → EditView  // 太深

// ✅ 正确：用 Sheet 替代深层导航
.sheet(isPresented: $showEdit) {
    EditView()
}
```

#### 坑 2：UI 元素太小无法点击
```swift
// ❌ 错误
Button("修炼") { }.frame(width: 20, height: 20)

// ✅ 正确：最小 44×44 pt
Button("修炼") { }
    .frame(minWidth: 44, minHeight: 44)
    .buttonStyle(.borderedProminent)
```

#### 坑 3：不处理模拟器与真机的差异
- 模拟器无法测试：心率、GPS、加速度计、真实延迟
- 始终在真实设备上测试性能和电池消耗

#### 坑 4：在主线程做网络请求
```swift
// ❌ 错误
let data = try! Data(contentsOf: url)  // 阻塞主线程

// ✅ 正确：async/await
Task {
    let data = try await URLSession.shared.data(from: url).0
}
```

#### 坑 5：忽视深色模式适配
```swift
// ❌ 错误：硬编码颜色
Text("修为").foregroundColor(.black)

// ✅ 正确：使用语义颜色
Text("修为").foregroundStyle(.primary)
```

#### 坑 6：Complication 更新过于频繁
- 每天预算约 50 次 Timeline 刷新
- 不要在每次 App 状态变化时就调用 `reloadTimelines`

#### 坑 7：在后台任务中做太多工作
- 后台任务时间窗口极短（< 15 秒）
- 必须调用 `setTaskCompleted`，否则 watchOS 会惩罚 App 的后台配额

#### 坑 8：WCSession 未检查可达性
```swift
// ❌ 错误：直接发送
WCSession.default.sendMessage(data, replyHandler: nil)

// ✅ 正确：检查可达性
guard WCSession.default.isReachable else { return }
WCSession.default.sendMessage(data, replyHandler: nil)
```

#### 坑 9：过度使用动画
- Watch 的 GPU 较弱，过度动画导致掉帧和耗电
- 用简单的 `withAnimation(.easeIn(duration: 0.2))` 而非复杂动画

#### 坑 10：不在 watchOS target 中单独测试
- 共享代码要用 `#if os(watchOS)` 区分平台逻辑

---

## 十、参考资源

### 官方文档
- [Apple Developer - watchOS](https://developer.apple.com/watchos/)
- [Creating a watchOS app (SwiftUI Tutorial)](https://developer.apple.com/tutorials/swiftui/creating-a-watchos-app)
- [Design and build apps for watchOS 10 - WWDC23](https://developer.apple.com/videos/play/wwdc2023/10138/)
- [Update your app for watchOS 10 - WWDC23](https://developer.apple.com/videos/play/wwdc2023/10031/)
- [Complications and Widgets Reloaded - WWDC22](https://developer.apple.com/videos/play/wwdc2022/10050/)
- [Using Extended Runtime Sessions](https://developer.apple.com/documentation/watchkit/using-extended-runtime-sessions)

### 开源参考
- [awesome-apple-watch](https://github.com/738/awesome-apple-watch) — 精选 watchOS 框架与示例合集
- [WWDCNotes - watchOS 10](https://www.wwdcnotes.com/notes/wwdc23/10138/) — WWDC 笔记整理
- [Hacking with Swift - Digital Crown](https://www.hackingwithswift.com/quick-start/swiftui/how-to-read-the-digital-crown-on-watchos-using-digitalcrownrotation)

### 学习资源
- [Kodeco: watchOS With SwiftUI by Tutorials](https://www.kodeco.com/books/watchos-with-swiftui-by-tutorials)
- [Complete Guide to watchOS Development 2025](https://www.netsetsoftware.com/insights/a-complete-guide-to-watchos-app-development-in-2025/)

---

*最后更新：2026-03 | 适用 watchOS 10-11，Xcode 16+*
