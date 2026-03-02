# 灵息 LingXi — Apple Watch 修仙模拟器 项目记忆

## 项目概况
- **产品**：灵息 LingXi，watchOS 修仙模拟器（Apple Watch MVP）
- **技术栈**：SwiftUI + watchOS 10+，无 iOS companion（独立应用）
- **设计主题**：修仙美学，深色背景 #0A0A0F，金色 #C8A96E / 青色 #4ECDC4 强调色

## 关键文件
- [docs/watchos-dev-guide.md](../docs/watchos-dev-guide.md) — watchOS 开发 Q&A 指南（10大问题）
- [.claude/skills/watchos-dev/SKILL.md](../.claude/skills/watchos-dev/SKILL.md) — Claude 代码生成约束规范
- [prototype.html](../prototype.html) — UI 原型（HTML）
- [assets/images/spirit-items/](../assets/images/spirit-items/) — 灵宝图片资源

## 架构决策
- 主导航：`TabView(.verticalPage)` 垂直页面式（Home / 修炼 / 背包）
- 临时弹窗：`.sheet` 而非深层 `NavigationStack`
- 数据流：HealthKit → HealthKitService → PlayerState → Views → WidgetKit Complications
- 无 WCSession（纯独立应用，不依赖 iPhone）

## watchOS 核心约束（务必遵守）
1. 纯 SwiftUI，禁止 WatchKit / UIKit
2. 导航 ≤ 3 层，Button 最小 44×44pt
3. 颜色使用语义色（`.primary`），不硬编码
4. 异步操作用 async/await + @MainActor
5. 后台任务必须调用 `setTaskCompleted`
6. Digital Crown 必须搭配 `focusable()`

## Complication 规格
- 支持 family：`.accessoryCircular`、`.accessoryRectangular`、`.accessoryCorner`
- 数据：修为等级 + 境界名称（每小时刷新）
- 每天刷新预算约 50 次

## Xcode 项目位置
- **项目路径**：`LingXi/LingXi.xcodeproj`
- **Simulator**：Apple Watch Series 11 (46mm), ID: `54183E19-11A6-42EC-B3C5-1240C37EA2F2`, watchOS 26.1
- **状态**：✅ BUILD SUCCEEDED + 已在模拟器运行

## 已知构建注意事项（避免重蹈覆辙）
1. **Info.plist 冲突**：`LingXiComplication/` 目录是 `PBXFileSystemSynchronizedRootGroup`，会自动把目录内所有文件作为资源。`Info.plist` 必须放在该目录**外**（现为 `LingXi/LingXiComplication-Info.plist`），同时 `GENERATE_INFOPLIST_FILE = NO`，`INFOPLIST_FILE = "LingXiComplication-Info.plist"`
2. **NSExtension 必须**：WidgetKit Extension 的 Info.plist 需要 `NSExtension > NSExtensionPointIdentifier = com.apple.widgetkit-extension`
3. **appleStandHour 类型**：`HKCategoryTypeIdentifier`，不是 `HKQuantityTypeIdentifier`
4. **TimelineProviderContext**：没有公开初始化器，不能用 `.init()`；用 `static let fallbackEntry` 替代
5. **App Groups**：个人免费账号不支持，`LingXiKeys.shared` 用 `?? .standard` 降级

## 待办/下一步
- [x] 创建 Xcode 项目（watchOS target）
- [x] 实现所有 Views（Home/修炼/背包/Complications）
- [x] 集成 HealthKit
- [ ] 在模拟器验证完整功能流程（Onboarding → 主界面 → 修炼）
- [ ] 真机测试（需要 Apple Developer 账号 + 设备）
