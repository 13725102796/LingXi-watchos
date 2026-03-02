---
name: watchos-dev
description: |
  Apple Watch (watchOS) 开发专项技能。
  约束 Claude 在生成 watchOS / SwiftUI 代码时，严格遵守 Apple HIG、
  watchOS 平台限制与本项目规范，避免常见反模式。

  触发词（中英文）：
  - watchOS, WatchKit, Apple Watch, 手表, 表盘, Complication
  - SwiftUI watch, HealthKit, WCSession, Watch Connectivity
  - Digital Crown, 数字表冠, Complication, Widget
  - 后台任务, background task, WKExtendedRuntimeSession
  - NavigationStack watch, TabView watch

  不用于：iOS/macOS 专属功能、纯 UI 原型（用 phase-3-mockup）
version: 1.0.0
---

# watchOS 开发规范（Claude 代码生成约束）

> 本 Skill 在 Claude 生成 watchOS / SwiftUI 代码时自动激活，
> 所有输出必须遵守以下规范。违反约束时，Claude 应主动指出并提供修正版本。

---

## 一、强制约束（MUST）

### 1.1 框架选择
- **必须使用 SwiftUI**，禁止新增 WatchKit Interface Controller 代码
- **必须使用 Swift async/await**，禁止回调嵌套（completion handler hell）
- **必须使用 Swift Concurrency**（`Task`、`@MainActor`）处理异步 UI 更新

```swift
// ✅ 正确
Task { @MainActor in
    self.data = try await service.fetch()
}

// ❌ 禁止
service.fetch { result in
    DispatchQueue.main.async {
        self.data = result
    }
}
```

### 1.2 导航结构

必须按以下规则选择导航模式，**禁止混用或超过 3 层嵌套**：

| 场景 | 使用 | 禁止 |
|------|------|------|
| 2-4 个并列功能模块 | `TabView(.verticalPage)` | 多层 `NavigationStack` 嵌套 |
| 列表钻入详情 | `NavigationStack` | `.tabItem` 混用 |
| 主列表+详情联动 | `NavigationSplitView` | 自定义 push/pop 动画 |
| 临时弹窗/表单 | `.sheet` 或 `.fullScreenCover` | 超过 2 层 sheet |

```swift
// ✅ 正确 - 主界面用垂直 TabView
TabView {
    HomeView().tabItem { Label("主页", systemImage: "house") }
    CultivationView().tabItem { Label("修炼", systemImage: "flame") }
}
.tabViewStyle(.verticalPage)

// ❌ 禁止 - 超过3层导航
NavigationStack { ListA { NavigationStack { ListB { NavigationLink { DetailC() } } } } }
```

### 1.3 触控目标尺寸

**所有可交互元素（Button、NavigationLink）最小尺寸 44×44 pt**：

```swift
// ✅ 正确
Button("修炼") { startCultivation() }
    .frame(minWidth: 44, minHeight: 44)
    .buttonStyle(.borderedProminent)

// ❌ 禁止
Image(systemName: "flame")
    .onTapGesture { startCultivation() }  // 无法保证触控大小
```

### 1.4 颜色与字体

```swift
// ✅ 必须使用语义颜色，支持深色模式
.foregroundStyle(.primary)
.foregroundStyle(.secondary)
.tint(.accentColor)
Color("CustomColor")  // Assets 中定义，有 Dark 变体

// ❌ 禁止硬编码颜色
.foregroundColor(.black)
Color(red: 0.1, green: 0.1, blue: 0.1)  // 不支持深色适配

// ✅ 字体规范（watchOS 最小字号）
.font(.headline)   // 主标题
.font(.body)       // 正文
.font(.footnote)   // 最小可用（13pt）
// ❌ 禁止
.font(.system(size: 8))  // 过小，不可读
```

### 1.5 Digital Crown

```swift
// ✅ 正确 - 必须搭配 focusable()
VStack { ... }
    .focusable()
    .digitalCrownRotation($value, from: 0, through: 100, by: 1,
                          sensitivity: .medium,
                          isHapticFeedbackEnabled: true)

// ❌ 禁止 - 缺少 focusable() 或重复绑定多个 View
Text("val").digitalCrownRotation($value)  // 没有 focusable
```

### 1.6 网络与数据访问

```swift
// ✅ 正确 - 异步网络请求
func fetchData() async throws -> GameData {
    let (data, _) = try await URLSession.shared.data(from: apiURL)
    return try JSONDecoder().decode(GameData.self, from: data)
}

// ❌ 禁止 - 同步阻塞
let data = try! Data(contentsOf: url)  // 阻塞主线程，watchOS 会杀死 App
```

### 1.7 后台任务

```swift
// ✅ 正确 - 后台任务必须在完成后立即调用 setTaskCompleted
func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
    for task in backgroundTasks {
        switch task {
        case let task as WKApplicationRefreshBackgroundTask:
            Task {
                await updateGameState()
                task.setTaskCompletedWithSnapshot(false)  // 必须调用！
            }
        default:
            task.setTaskCompletedWithSnapshot(false)
        }
    }
}

// ❌ 禁止 - 忘记调用 setTaskCompleted 或超时
// 会导致 watchOS 减少该 App 的后台配额
```

### 1.8 Watch Connectivity

```swift
// ✅ 正确 - 必须检查 isReachable
func sendToPhone(_ data: [String: Any]) {
    guard WCSession.default.isReachable else {
        // 降级：使用 updateApplicationContext
        try? WCSession.default.updateApplicationContext(data)
        return
    }
    WCSession.default.sendMessage(data, replyHandler: nil)
}

// ❌ 禁止 - 不检查直接发送
WCSession.default.sendMessage(data, replyHandler: nil)  // 可能 crash
```

---

## 二、推荐约束（SHOULD）

### 2.1 状态管理

```swift
// ✅ 推荐 - 轻量 @State / @StateObject，避免重量级框架
struct CultivationView: View {
    @StateObject private var viewModel = CultivationViewModel()
    @State private var showDetail = false
    // ...
}

// ⚠️ 谨慎 - Redux/TCA 等框架在 Watch 上有性能开销
```

### 2.2 Complication 刷新策略

```swift
// ✅ 推荐 - 批量刷新，每天不超过 50 次
func refreshComplications() {
    WidgetCenter.shared.reloadTimelines(ofKind: "LingXiComplication")
}

// ⚠️ 避免 - 每次数据变化就刷新
// 应该：批量或定时（每小时）刷新一次
```

### 2.3 动画规范

```swift
// ✅ 推荐 - 简短动画（≤ 0.3s）
withAnimation(.easeInOut(duration: 0.2)) {
    isExpanded.toggle()
}

// ⚠️ 避免 - 复杂路径动画、长时间动画（>0.5s），耗电且影响体验
```

### 2.4 图片资源

```swift
// ✅ 推荐 - 使用 SF Symbols，自动适配尺寸和颜色
Image(systemName: "flame.fill")
    .symbolRenderingMode(.hierarchical)

// ✅ 自定义图片：提供 @2x、@3x，最大 100KB
Image("spirit-aura")
    .resizable()
    .scaledToFit()
    .frame(width: 40, height: 40)

// ❌ 禁止 - 大图（>500KB）直接在 Watch 上使用
```

### 2.5 HealthKit 权限

```swift
// ✅ 推荐 - 仅申请实际需要的权限类型
let typesToRead: Set<HKObjectType> = [
    HKObjectType.quantityType(forIdentifier: .heartRate)!
    // 只申请心率，不要一次性申请所有类型
]

// ⚠️ 避免 - 一次申请所有权限，会让用户感到不安
```

---

## 三、禁止反模式（MUST NOT）

| 反模式 | 原因 | 正确做法 |
|--------|------|----------|
| `DispatchQueue.main.async` 嵌套 | 应使用 `@MainActor` | `await MainActor.run { }` |
| `UIKit` 类（UIView、UIViewController）| watchOS 不支持 UIKit | 纯 SwiftUI |
| `Timer.scheduledTimer` 长时运行 | 后台会被杀死 | `WKApplicationRefreshBackgroundTask` |
| `UserDefaults` 存储大量数据 | 性能差，限制 1MB | CoreData 或 SwiftData |
| 导航超过 3 层 | 用户迷失，不符合 HIG | 重新设计为扁平结构 |
| `NavigationView`（已弃用）| watchOS 10 废弃 | `NavigationStack` |
| 硬编码屏幕尺寸 | 适配多机型 | `GeometryReader` 或相对布局 |
| 在 Complication 中展示大量文字 | Complication 极小 | 精简到 1-2 个核心数据 |
| 连续传感器采样不释放 | 耗尽电池 | 采样后立即停止 session |
| 在 Watch 上播放长视频/音频 | 无此能力 | 仅展示控制界面，由 iPhone 播放 |

---

## 四、项目特定规范（灵息 LingXi 项目）

### 4.1 设计风格
- **主题**：修仙美学，深色背景（#0A0A0F），金色（#C8A96E）/青色（#4ECDC4）强调色
- **字体**：使用 SF Pro（系统默认），中文使用系统字体，不引入自定义字体（影响包大小）
- **图标**：SF Symbols 为主，项目资产中的 spirit-items 图片仅在详情页使用（非 Complication）

### 4.2 模块边界
```
HomeView          → 今日状态 + 修炼进度（主屏）
CultivationView   → 修炼操作（TabView 第2页）
InventoryView     → 灵宝背包（TabView 第3页）
QuestView         → 任务日志（Sheet 或 NavigationStack）
SettingsView      → 设置（Sheet）
```

### 4.3 数据流
```
HealthKit → HealthKitService → PlayerState（@StateObject）→ Views
iPhone App → WCSession → WatchConnectivityService → PlayerState
PlayerState → WidgetCenter.reloadTimelines → LingXiComplication
```

### 4.4 文件命名
- Views：`{Feature}View.swift`
- ViewModels：`{Feature}ViewModel.swift`
- Services：`{Domain}Service.swift`
- Models：纯 Swift struct/enum，无后缀

---

## 五、代码生成检查清单

Claude 在生成每个代码块后，应自检以下项目：

- [ ] 是否使用了 SwiftUI（无 WatchKit Interface Controller）？
- [ ] 导航层级是否 ≤ 3 层？
- [ ] 所有 Button/NavigationLink 是否 ≥ 44×44 pt？
- [ ] 颜色是否使用语义色（无硬编码）？
- [ ] 异步操作是否用 async/await？
- [ ] 后台任务是否调用了 `setTaskCompleted`？
- [ ] WCSession 消息发送前是否检查了 `isReachable`？
- [ ] Digital Crown 绑定是否搭配了 `focusable()`？
- [ ] 是否避免了在 Watch 上使用 UIKit？
- [ ] 代码是否适配了深色背景（无 `.black` 硬编码）？

---

## 六、参考文档

- [Apple HIG for watchOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-watchos)
- [watchOS App Programming Guide](https://developer.apple.com/documentation/watchos-apps)
- [项目开发指南](../../docs/watchos-dev-guide.md)
- [WWDC23: Design and build apps for watchOS 10](https://developer.apple.com/videos/play/wwdc2023/10138/)
