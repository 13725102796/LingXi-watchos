# 灵息 (LingXi) — 产品需求文档 (PRD)

> **项目代号：** 灵息 (LingXi)
> **版本：** v2.0 | **日期：** 2026-02-28 | **状态：** MVP 定稿
> **产品形态：** 纯 watchOS 独立应用（Standalone App），无 iOS 伴随应用

---

## 1. 产品概述

### 1.1 产品定位
一款面向女性用户的 **独立 watchOS 修仙养成模拟器**，将 Apple Watch 的真实健康数据（HealthKit）转化为唯美、治愈的"修仙"视觉体验与情绪价值反馈。

### 1.2 核心价值主张
- **健康即修行** — 睡眠是闭关、运动是历练、心率是灵台，让枯燥的健康数据有温度
- **情绪治愈** — 以"温润仙尊"口吻的古风文案，在恰当时机给予关怀与陪伴
- **零成本极简** — 纯本地 HealthKit 读取与运算，零服务器，零订阅

### 1.3 目标用户
| 用户画像 | 特征 | 核心需求 |
|----------|------|----------|
| 古风仙侠爱好者 | 喜爱古风/仙侠文化，有审美追求 | 日常生活中的"仙感"沉浸体验 |
| 亚健康都市女性 | 高压、睡眠不规律、缺乏运动 | 温和的健康关怀，非教条式的数据轰炸 |
| 情绪消费型用户 | 重视精神陪伴与情绪价值 | 每日仪式感，被在意的感觉 |

### 1.4 设计红线
- **禁止：** 极客风黑红配色、赛博朋克色、数据堆砌式 UI、说教口吻
- **禁止：** 网文式重度修仙系统（无打怪、无装备、无PVP、无复杂门派）
- **必须：** 国风水墨或清冷仙女色系、温柔关怀口吻、每次交互 < 5 秒

---

## 2. 技术架构

### 2.1 技术栈

| 层级 | 技术选择 | 理由 |
|------|----------|------|
| **UI 框架** | SwiftUI | watchOS 原生，声明式 UI，支持动画与渐变 |
| **架构模式** | @Observable + View 直接状态管理 | 2025 SwiftUI 最佳实践，轻量无冗余 |
| **数据持久化** | SwiftData | Swift 原生，与 SwiftUI 无缝集成 |
| **轻量存储** | UserDefaults | 存储当日状态快照、境界等级等高频读取数据 |
| **健康数据** | HealthKit | Apple Watch 传感器数据唯一官方接口 |
| **表盘组件** | WidgetKit (Accessory Families) | 替代已废弃的 ClockKit |
| **触觉反馈** | WKInterfaceDevice / CoreHaptics | 关怀提醒的柔和震动 |
| **最低系统** | watchOS 10+ | 覆盖 Series 6 及以上，支持 SwiftData |
| **开发工具** | Xcode 16+ / Swift 5.9+ | 最新稳定版 |

### 2.2 项目结构

```
LingXi/
├── LingXiWatch/                    # watchOS 独立 App
│   ├── App/
│   │   └── LingXiApp.swift         # App 入口 + HealthKit 授权
│   ├── Views/
│   │   ├── HomeView.swift           # 主界面（灵境总览）
│   │   ├── SleepRewardView.swift    # 驻颜闭关 — 晨起奖励弹窗
│   │   ├── HeartLotusView.swift     # 灵台清心 — 莲花动态视觉
│   │   ├── JourneyView.swift        # 云游历练 — 运动成就
│   │   ├── CollectionView.swift     # 灵物图鉴 — 收集品展示
│   │   └── OnboardingView.swift     # 首次引导 + HealthKit 授权
│   ├── Models/
│   │   ├── CultivationState.swift   # 境界/灵气/修为 数据模型
│   │   ├── SpiritItem.swift         # 灵物收集品模型
│   │   └── DailyRecord.swift        # 每日健康数据快照
│   ├── Services/
│   │   ├── HealthKitManager.swift   # HealthKit 数据读写
│   │   ├── CultivationEngine.swift  # 核心算法：健康数据 → 修仙状态
│   │   └── CopywritingEngine.swift  # 文案引擎：根据状态输出古风文案
│   ├── Design/
│   │   ├── LingXiColors.swift       # 国风色彩常量
│   │   ├── LingXiFonts.swift        # 字体规范
│   │   └── LingXiAnimations.swift   # 呼吸光效/渐变动画
│   ├── Widgets/
│   │   └── LingXiComplication.swift  # 表盘组件
│   └── Assets.xcassets               # 仙境插画/图标
├── LingXiTests/
└── README.md
```

---

## 3. 核心功能模块

### 3.1 驻颜闭关系统（睡眠 → 晨起奖励）

**优先级：P0 — MVP 必须**

#### 数据源
- `HKCategoryValueSleepAnalysis`（睡眠时长 + 阶段：清醒/REM/核心/深睡）

#### 业务逻辑
睡眠即"闭关修炼"。根据昨夜睡眠质量，决定今日的灵气充沛度与掉落道具。

| 睡眠评级 | 判定条件 | 灵气恢复 | 掉落道具 | 文案风格 |
|----------|----------|----------|----------|----------|
| **仙品闭关** | ≥ 7.5h 且深睡 ≥ 20% | +100 灵气 | 天山雪莲 / 琼浆玉露 | 赞美 + 鼓励 |
| **上品闭关** | 6.5–7.5h 或深睡 15–20% | +70 灵气 | 晨露凝珠 / 玉髓 | 温和肯定 |
| **中品闭关** | 5–6.5h 或深睡 10–15% | +40 灵气 | 清泉一缕 | 温柔提醒 |
| **未入定** | < 5h 或深睡 < 10% | +10 灵气 | 无 | 心疼关怀 |

#### 交互流程
```
清晨首次抬腕
  → 检测昨夜睡眠数据
  → 计算睡眠评级
  → 弹出全屏"闭关结算"卡片：
    ┌──────────────────────┐
    │                      │
    │   ✧ 闭关圆满 ✧       │  ← 毛玻璃背景 + 月白渐变
    │                      │
    │   昨夜安睡 7 时 42 分  │
    │   深睡占比 23%        │
    │                      │
    │   获得【天山雪莲】×1   │  ← 道具图标 + 微光动效
    │                      │
    │   "仙子安眠一夜，       │
    │    容光焕发如初。"      │  ← 古风文案
    │                      │
    │    [ 收入囊中 ]        │  ← 轻触关闭
    └──────────────────────┘
  → 灵气值更新
  → 道具存入图鉴
```

#### 文案示例
- **仙品：** "仙子昨夜安睡如莲，元神充沛，驻颜有成。今日灵气充盈，诸事可期。"
- **上品：** "尚可，虽未达极致，但灵基稳固。今日宜静心修行。"
- **中品：** "仙子昨夜眠浅，灵气略有不继。今日可多饮温水，午后小憩片刻。"
- **未入定：** "夜深露重，仙子却未曾安眠……元神耗损，切记今夜早些入定护体。"

---

### 3.2 灵台清心系统（心率 + HRV → 动态视觉）

**优先级：P0 — MVP 必须**

#### 数据源
- 实时心率：`HKQuantityTypeIdentifier.heartRate`
- 心率变异性：`HKQuantityTypeIdentifier.heartRateVariabilitySDNN`

#### 业务逻辑
核心视觉是一朵动态"灵莲"，根据心率/HRV 状态实时变化。

| 状态 | 判定条件 | 视觉表现 | 修为变化 |
|------|----------|----------|----------|
| **灵台清明** | 静息心率区间 & HRV > 40ms | 莲花柔和呼吸光（月白 → 淡青） | +1 修为/10min |
| **心绪微澜** | 心率略高(非运动) 或 HRV 30–40ms | 莲花光芒微弱闪烁 | +0.5 修为/10min |
| **心魔暗生** | 心率 > 100(非运动) & HRV < 30ms | 莲花泛红光 + 触觉震动 | 修为不变 |

#### 交互流程
```
主界面常驻显示
  ┌──────────────────────┐
  │                      │
  │      ❋               │  ← 动态莲花（SVG/SwiftUI 绘制）
  │    ❋ ✿ ❋             │     根据状态改变颜色和动画节奏
  │      ❋               │
  │                      │
  │   灵台清明            │  ← 状态文字
  │   内息绵长            │
  │                      │
  │   心率 68 · HRV 52   │  ← 底部小字数据
  └──────────────────────┘

"心魔暗生" 触发时：
  → Apple Watch 触觉引擎柔和震动 (2次短促)
  → 弹出关怀卡片：
    "感应到仙子心绪不宁，气血翻涌。
     可是凡间俗务惹你烦忧？
     且随我深呼吸三次，护住灵台。"
  → [ 开始调息 ] ← 跳转系统正念呼吸 App
  → [ 知道了 ]   ← 关闭提醒
```

#### 心魔触发防抖
- 同一小时内最多触发 1 次
- 运动状态下不触发（检测 `HKWorkoutSession` 是否活跃）
- 触发后 30 分钟内不重复

---

### 3.3 云游历练系统（运动 → 仙境解锁）

**优先级：P0 — MVP 必须**

#### 数据源
- 活动能量：`HKQuantityTypeIdentifier.activeEnergyBurned`
- 运动时间：`HKQuantityTypeIdentifier.appleExerciseTime`
- 站立小时：`HKCategoryTypeIdentifier.appleStandHour`
- 步数：`HKQuantityTypeIdentifier.stepCount`

#### 业务逻辑
运动达标 = 在名山大川"云游历练"。

| 历练等级 | 判定条件 | 奖励 |
|----------|----------|------|
| **仙山一日游** | 步数 ≥ 5,000 步 | 解锁风景 1 帧 + 灵物 1 个 |
| **云游四方** | 步数 ≥ 10,000 步 或 三环全闭合 | 解锁风景 2 帧 + 稀有灵物 |
| **万里云游** | 连续 3 日达标 | 解锁特殊仙境 + 境界经验加成 |

#### 仙境风景池（MVP 共 12 帧，每月轮换）

| 编号 | 风景名 | 解锁条件 |
|------|--------|----------|
| 1 | 青云峰·晨雾 | 首次步数达标 |
| 2 | 碧波潭·月影 | 累计 3 次达标 |
| 3 | 灵鹤谷·花雨 | 累计 7 次达标 |
| 4 | 瑶池·莲开 | 累计 14 次达标 |
| ... | ... | 渐进解锁 |

#### 交互流程
```
运动达标时：
  → 抬腕显示成就卡片：
    ┌──────────────────────┐
    │  ✧ 历练有成 ✧        │
    │                      │
    │  今日云游 12,368 步   │
    │  历经 青云峰          │
    │                      │
    │  获得【灵鹤羽】×1     │
    │                      │
    │  "踏遍青山人未老，     │
    │   风景这边独好。"      │
    │                      │
    │   [ 收入囊中 ]        │
    └──────────────────────┘
```

---

### 3.4 修为境界系统（成长主线）

**优先级：P0 — MVP 必须**

#### 境界等级（MVP 共 9 级）

| 阶段 | 境界名 | 所需修为 | 描述 |
|------|--------|----------|------|
| 1 | 凡心初悟 | 0 | 初入修行之路 |
| 2 | 清心境·凝神 | 100 | 心绪初定 |
| 3 | 清心境·固本 | 300 | 灵基稳固 |
| 4 | 灵台境·明镜 | 600 | 灵台初清 |
| 5 | 灵台境·澄澈 | 1,000 | 心如止水 |
| 6 | 悟道境·初窥 | 1,500 | 初窥大道 |
| 7 | 悟道境·通幽 | 2,200 | 渐入佳境 |
| 8 | 归真境·返璞 | 3,000 | 洗尽铅华 |
| 9 | 归真境·天成 | 4,000 | 道法自然 |

#### 修为获取途径
- 灵台清明状态：+1 修为 / 10 分钟
- 驻颜闭关：按评级获得 10–100 灵气（灵气 ÷ 10 = 修为）
- 云游历练达标：+20 修为 / 次
- 连续签到（每日打开App）：+5 修为 / 天

#### 突破动效
境界突破时全屏动效 + 触觉反馈：
```
┌──────────────────────┐
│                      │
│    ✦ 突破成功 ✦       │  ← 流光粒子效果
│                      │
│   清心境·凝神         │  ← 旧境界（淡出）
│       ↓              │
│   清心境·固本         │  ← 新境界（金光亮起）
│                      │
│  "恭喜仙子，         │
│   灵基更进一层。"     │
│                      │
└──────────────────────┘
```

---

### 3.5 灵物图鉴（收集系统）

**优先级：P1 — MVP 后快速迭代**

#### 灵物分类

| 品级 | 来源 | 示例 |
|------|------|------|
| **凡品** | 每日签到 | 清泉一缕、山间野花 |
| **灵品** | 中品闭关 / 步数达标 | 晨露凝珠、灵鹤羽 |
| **仙品** | 仙品闭关 / 稀有成就 | 天山雪莲、琼浆玉露、百花仙露 |
| **神品** | 连续 30 天全部达标 | 混沌灵珠（极稀有） |

#### 存储方式
- SwiftData 存储灵物列表与获得时间
- 图鉴页面展示已收集/未收集状态（未收集显示剪影）

---

### 3.6 表盘小组件 (Complications)

**优先级：P0 — MVP 必须（杀手级获客功能）**

| 组件类型 | 展示内容 | 更新频率 |
|----------|----------|----------|
| `accessoryCircular` | 灵莲图标 + 当前灵台状态色 | 15 分钟 |
| `accessoryRectangular` | 当前境界名 + 灵气条 + 微型莲花 | 15 分钟 |
| `accessoryCorner` | 今日修为进度弧 | 30 分钟 |
| `accessoryInline` | "清心境·凝神 · 灵台清明" 文字 | 15 分钟 |

#### 设计要求
- 组件视觉必须符合国风美学，可作为社交分享炫耀点
- 点击组件直接跳转至 App 主界面

---

## 4. 视觉设计规范

> **设计风格定位：** OLED Dark + 国风水墨 + 柔光毛玻璃 (Soft Glassmorphism)
> **参考线框：** 详见 [WIREFRAME.md](WIREFRAME.md)

### 4.1 色彩体系

#### 主色板（OLED 优化版）

| 色名 | 色值 | RGB | 对比度 (vs 背景) | 用途 |
|------|------|-----|-----------------|------|
| **墨渊** | `#000000` | 0,0,0 | — | **主背景色** (OLED 纯黑，像素完全关闭，最省电) |
| **玄夜** | `#0A0E14` | 10,14,20 | — | 卡片/弹窗背景 (微蓝暗色，区别于纯黑) |
| **霜雪** | `#F0EDE8` | 240,237,232 | 19.4:1 ✓ AAA | **主文字色** (暖白而非冷白，减少刺眼) |
| **远山黛** | `#8A9B9B` | 138,155,155 | 6.2:1 ✓ AA | 次要文字、辅助信息 |
| **岫烟** | `#4A5568` | 74,85,104 | 3.2:1 | 最低层级文字、禁用态 (仅用于大字) |

#### 强调色板

| 色名 | 色值 | RGB | 对比度 (vs 墨渊) | 用途 | 语义 |
|------|------|-----|-----------------|------|------|
| **月白** | `#D6ECF0` | 214,236,240 | 16.7:1 ✓ AAA | 莲花默认光、呼吸动效起点 | 清净、初始 |
| **青瓷** | `#A8D8D8` | 168,216,216 | 12.1:1 ✓ AAA | 灵台清明状态、主按钮 | 安宁、平衡 |
| **藕荷** | `#E0B4C8` | 224,180,200 | 10.8:1 ✓ AAA | 灵气条、心绪微澜、Activity 动环 | 温柔、女性 |
| **鎏金** | `#D4A853` | 212,168,83 | 8.5:1 ✓ AA | 境界突破、仙品道具、成就 | 珍贵、庄重 |
| **朱砂** | `#D4605A` | 212,96,90 | 5.4:1 ✓ AA | 心魔暗生警示 (仅此一处) | 警告、危机 |
| **烟紫** | `#B8A9C9` | 184,169,201 | 8.8:1 ✓ AA | 神品道具、特殊成就光效 | 神秘、稀有 |

#### 功能色

| 色名 | 色值 | 用途 |
|------|------|------|
| **暗纹** | `#1A1A1E` | 进度条底色、未填充区域、分割线 |
| **薄雾** | `rgba(240,237,232,0.06)` | 毛玻璃叠加层 (blur 背景上的微白) |
| **幽光** | `rgba(168,216,216,0.15)` | 莲花外围柔光辉 |

#### 渐变色组

| 渐变名 | 起点 → 终点 | 用途 |
|--------|------------|------|
| **莲光渐变** | 月白 `#D6ECF0` → 青瓷 `#A8D8D8` | 莲花呼吸光效 (默认态) |
| **澜色渐变** | 月白 `#D6ECF0` → 藕荷 `#E0B4C8` | 莲花呼吸光效 (心绪微澜) |
| **灵气渐变** | 藕荷 `#E0B4C8` → 青瓷 `#A8D8D8` | 灵气/修为进度条填充 |
| **突破渐变** | 鎏金 `#D4A853` → 霜雪 `#F0EDE8` | 境界突破时金光扩散 |
| **魔心渐变** | 朱砂 `#D4605A` → 玄夜 `#0A0E14` | 心魔暗生时莲花脉动 |

### 4.2 色彩使用原则

**OLED 省电第一原则：**
- 背景必须用纯黑 `#000000`，非深灰。OLED 纯黑 = 像素关闭 = 零功耗
- 弹窗/卡片背景用 `#0A0E14` 微蓝暗色，与纯黑形成层次但不浪费电量
- 强调色面积控制在屏幕 15% 以内，避免大面积亮色

**对比度安全原则：**
- 主文字 (霜雪 on 墨渊)：19.4:1 — 超过 WCAG AAA (7:1)
- 次要文字 (远山黛 on 墨渊)：6.2:1 — 达到 WCAG AA (4.5:1)
- 所有强调色 on 墨渊：均 ≥ 5.4:1 — 达到 WCAG AA
- 按钮文字 (墨渊 on 青瓷)：12.1:1 — 反色使用同样安全

**情绪色彩语义：**
- 一个状态只用一个主色，不混搭
- 朱砂红只在"心魔暗生"出现，其他场景绝不使用红色
- 鎏金只在"成就/突破/仙品"出现，保持稀缺感

### 4.3 字体规范

> watchOS 只能使用系统字体 SF Pro，通过字重/字号变化营造层次。

| 层级 | 字号 | 字重 | 行距 | 用途 | SwiftUI |
|------|------|------|------|------|---------|
| **Display** | 32pt | `.ultraLight` | 1.2 | 步数、睡眠时长等核心数值 | `.system(size: 32, weight: .ultraLight)` |
| **Title** | 20pt | `.light` | 1.3 | 境界名、弹窗标题 | `.system(size: 20, weight: .light)` |
| **Headline** | 17pt | `.medium` | 1.3 | 次级标题、状态文字 | `.system(size: 17, weight: .medium)` |
| **Body** | 15pt | `.regular` | 1.5 | 古风文案正文 | `.system(size: 15)` |
| **Caption** | 13pt | `.regular` | 1.4 | 道具名、辅助说明 | `.system(size: 13)` |
| **Footnote** | 12pt | `.light` | 1.3 | 心率/HRV 数值、时间戳 | `.system(size: 12, weight: .light)` |

**字体风格原则：**
- 核心数值 (Display) 用 `.ultraLight` — 极细体营造"仙气"质感，在 OLED 黑底上尤其优雅
- 文案正文 (Body) 用 `.regular` — 确保中文阅读舒适度
- 同一屏幕最多 3 个字号层级，避免视觉混乱
- 文案行距 1.5 倍，保证古风长句的呼吸感

### 4.4 动效规范

> **核心原则：** 最多同时 1 个持续动画 (莲花)，其余为触发式一次性动效。
> **必须支持：** `@Environment(\.accessibilityReduceMotion)` 检测，关闭所有动画时显示静态图。

#### 持续动效

| 动效 | 代码 | 参数 | 备注 |
|------|------|------|------|
| **莲花呼吸** (默认) | `.scaleEffect` + `.opacity` | `easeInOut(duration: 3.0).repeatForever(autoreverses: true)` | 缩放 0.96–1.04，透明度 0.7–1.0 |
| **莲花微澜** | `.scaleEffect` + `.opacity` | `easeInOut(duration: 1.5).repeatForever(autoreverses: true)` | 缩放 0.94–1.06，节奏加快 |
| **莲花心魔** | `.opacity` | `easeInOut(duration: 0.8).repeatForever(autoreverses: true)` | 朱砂色透明度 0.4–1.0 脉动 |

#### 触发式动效

| 动效 | 代码 | 参数 | 触发条件 |
|------|------|------|----------|
| **弹窗滑入** | `.offset` + `.opacity` | `spring(response: 0.5, dampingFraction: 0.8)` | 弹窗出现 |
| **道具掉落** | `.offset` + `.scale` | `spring(response: 0.6, dampingFraction: 0.7)` | 道具展示 |
| **进度条填充** | `.frame(width:)` | `easeOut(duration: 0.8)` | 数据加载完成 |
| **境界突破金光** | `.scaleEffect` + `.opacity` | `easeOut(duration: 0.8)` | 境界提升 |
| **粒子扩散** | `Canvas` / `TimelineView` | 1.5s 总时长 | 突破庆典 |

#### 触觉反馈

| 场景 | 类型 | SwiftUI |
|------|------|---------|
| 心魔暗生 | 2 次短促 | `WKInterfaceDevice.current().play(.notification)` |
| 闭关结算-仙品 | 1 次成功震动 | `WKInterfaceDevice.current().play(.success)` |
| 境界突破 | 长震 0.5s | `WKInterfaceDevice.current().play(.notification)` × 2 |
| 按钮点击 | 轻触 | `WKInterfaceDevice.current().play(.click)` |

#### Reduce Motion 降级方案

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

// 莲花视觉
if reduceMotion {
    // 静态莲花 + 状态色边框环
    // 无缩放/透明度动画
} else {
    // 完整呼吸动效
}

// 弹窗出现
if reduceMotion {
    // 直接显示，无滑入动画
} else {
    // spring 滑入
}
```

### 4.5 毛玻璃与层级规范

**层级体系：**

| 层级 | Z-Index | 背景 | 用途 |
|------|---------|------|------|
| L0 底层 | 0 | `#000000` 纯黑 | 屏幕底色 |
| L1 内容层 | 1 | 透明 | 莲花、文字、进度条 |
| L2 卡片层 | 10 | `#0A0E14` + 1px `rgba(240,237,232,0.08)` 描边 | 道具卡片、灵物格子 |
| L3 弹窗层 | 20 | `Material.ultraThinMaterial` (系统毛玻璃) | 闭关结算、心魔暗生 |
| L4 庆典层 | 30 | 半透明黑 `rgba(0,0,0,0.6)` + 粒子 | 境界突破全屏 |

**毛玻璃使用规范 (SwiftUI)：**
```swift
// 弹窗背景 — 使用系统 Material
.background(.ultraThinMaterial)
.clipShape(RoundedRectangle(cornerRadius: 16))

// 卡片微光边框
.overlay(
    RoundedRectangle(cornerRadius: 12)
        .stroke(Color.white.opacity(0.08), lineWidth: 1)
)
```

- 圆角统一 12pt (卡片) / 16pt (弹窗)
- 不使用纯白高透明度毛玻璃 (会导致对比度不足)
- 毛玻璃 blur 强度：`ultraThinMaterial` (系统最轻级别)

### 4.6 布局规范

#### 屏幕安全区与间距

| 设备 | 屏幕尺寸 | 安全区内边距 | 有效内容宽度 |
|------|----------|-------------|-------------|
| 41mm | 176×215 pt | 左右各 10pt | 156pt |
| 45mm | 198×242 pt | 左右各 12pt | 174pt |

#### 间距系统 (8pt 网格)

| Token | 值 | 用途 |
|-------|-----|------|
| `xs` | 4pt | 图标与文字间距 |
| `sm` | 8pt | 同组元素间距 |
| `md` | 12pt | 不同组件间距 |
| `lg` | 16pt | 区块间距 |
| `xl` | 24pt | 页面顶部/底部留白 |

#### 触控目标

- 所有可点击元素最小 44×44 pt (Apple HIG 要求)
- 按钮高度：44pt
- 灵物网格每格：56×56 pt (含内边距 8pt，图标区 40×40 pt)
- 三环触控区：每环 44×44 pt

### 4.7 文案风格规范

**口吻定调：** 温润仙尊 / 贴心器灵，不卑不亢，温柔而不谄媚。

| 场景 | 文案风格 | 示例 |
|------|----------|------|
| 早安问候 | 关怀 + 期待 | "晨光初照，仙子可安好？今日灵气充沛，宜修行。" |
| 熬夜提醒 | 心疼 + 劝诫 | "夜深露重，仙子不可再过度消耗元神了，请速速入眠护体。" |
| 压力过大 | 理解 + 引导 | "感应到仙子心绪不宁、气血翻涌，可是凡间俗务惹你烦忧？且深呼吸，护住灵台。" |
| 运动达标 | 赞美 + 鼓舞 | "好一个英姿飒爽的仙子！今日云游四方，身轻如燕。" |
| 境界突破 | 庄重 + 祝贺 | "灵基已固，道心通明。恭喜仙子，踏入新的境界。" |
| 连续签到 | 欣慰 + 激励 | "仙子日日精进，修行不辍，假以时日，必成大道。" |

### 4.8 图标规范

- **禁止使用 Emoji 作为正式 UI 图标**（Emoji 仅用于线框示意）
- 灵莲图标：SwiftUI `Shape` 自绘或自定义 SF Symbol
- 灵物图标：16 色限制的简笔 SVG / SF Symbol 组合
- 三环圆弧：SwiftUI `Circle().trim()` 绘制
- 品级标签：纯文字 + 对应色彩，不加图标

---

## 5. 核心 User Flow

### 5.1 首次启动流程

```
下载安装
  → 启动 App
  → 引导页 (3 屏)：
      [1] "欢迎踏入灵息世界" — 水墨渐入动画
      [2] "你的健康，即是修行" — 简要说明三大系统
      [3] "需要感应你的身体灵气" — HealthKit 授权说明
  → 请求 HealthKit 授权：
      - 需要权限：心率、HRV、睡眠、步数、活动能量、运动时间、站立小时
      → 全部授权 → 进入主界面
      → 部分授权 → 降级体验（隐藏未授权功能，不阻断）
      → 全部拒绝 → 展示纯修为养成模式（仅签到获得修为）
  → 初始化用户数据：
      - 境界 = "凡心初悟"
      - 修为 = 0
      - 灵气 = 50（初始赠送）
      - 灵物图鉴 = 空
  → 进入主界面
```

### 5.2 日常使用闭环

```
┌─────── 每日循环 ───────┐
│                        │
│  [清晨] 首次抬腕       │
│    → 闭关结算弹窗      │
│    → 获得灵气 + 道具    │
│    → 查看今日灵台状态   │
│         │              │
│  [日间] 日常抬腕       │
│    → 表盘组件一览状态   │
│    → 莲花动态反映心率   │
│    → 心魔触发 → 关怀   │
│         │              │
│  [运动后] 达标通知     │
│    → 历练成就卡片      │
│    → 仙境解锁 + 灵物   │
│         │              │
│  [睡前] 看一眼今日修为  │
│    → 满足感 + 入睡     │
│                        │
└────────────────────────┘
```

### 5.3 导航结构

```
App 启动
  └─ 主界面 (垂直滚动 / TabView)
       ├─ 页面 1: 灵境总览 (Home)
       │    ├─ 莲花动态视觉（灵台清心）
       │    ├─ 当前境界 + 修为进度条
       │    ├─ 今日灵气值
       │    └─ 心率/HRV 小字数据
       ├─ 页面 2: 今日历练 (Journey)
       │    ├─ 步数 / 三环进度（国风视觉化）
       │    ├─ 已解锁仙境缩略图
       │    └─ 今日获得灵物列表
       └─ 页面 3: 灵物图鉴 (Collection)
            ├─ 按品级分类展示
            └─ 已收集 / 未收集（剪影）
```

---

## 6. 数据模型设计

### 6.1 SwiftData Models

```swift
import SwiftData
import Foundation

// 修炼状态（全局唯一，类似 UserProfile）
@Model
class CultivationState {
    var realmLevel: Int              // 境界等级 1-9
    var realmName: String            // 境界名称 "清心境·凝神"
    var cultivation: Int             // 修为值（累计）
    var spiritEnergy: Int            // 当前灵气值
    var consecutiveDays: Int         // 连续签到天数
    var lastCheckInDate: Date?       // 上次签到日期
    var totalJourneyDays: Int        // 累计历练达标天数

    init() {
        self.realmLevel = 1
        self.realmName = "凡心初悟"
        self.cultivation = 0
        self.spiritEnergy = 50
        self.consecutiveDays = 0
        self.totalJourneyDays = 0
    }
}

// 灵物收集品
@Model
class SpiritItem {
    var id: UUID
    var name: String                 // "天山雪莲"
    var grade: String                // "凡品" / "灵品" / "仙品" / "神品"
    var source: String               // 来源描述
    var obtainedDate: Date
    var iconName: String             // 对应 Asset 图标名

    init(name: String, grade: String, source: String, iconName: String) {
        self.id = UUID()
        self.name = name
        self.grade = grade
        self.source = source
        self.obtainedDate = .now
        self.iconName = iconName
    }
}

// 每日记录快照
@Model
class DailyRecord {
    var date: Date                   // 日期（精确到天）
    var sleepHours: Double?          // 睡眠时长（小时）
    var deepSleepPercent: Double?    // 深睡比例 0-1
    var sleepGrade: String?          // "仙品" / "上品" / "中品" / "未入定"
    var steps: Int?                  // 步数
    var activeCalories: Double?      // 活动卡路里
    var journeyCompleted: Bool       // 是否达成历练
    var spiritEnergyGained: Int      // 当日获得灵气
    var cultivationGained: Int       // 当日获得修为
    var heartMagicTriggered: Int     // 心魔触发次数

    init(date: Date) {
        self.date = date
        self.journeyCompleted = false
        self.spiritEnergyGained = 0
        self.cultivationGained = 0
        self.heartMagicTriggered = 0
    }
}
```

### 6.2 UserDefaults 缓存（高频读取）

| Key | 类型 | 用途 |
|-----|------|------|
| `currentRealmName` | String | 表盘组件显示境界名 |
| `currentRealmLevel` | Int | 快速判断境界 |
| `todaySpiritEnergy` | Int | 今日灵气（表盘组件） |
| `lastSleepRewardDate` | String | 防止重复发放晨起奖励 |
| `lastHeartMagicTime` | Date | 心魔触发防抖 |
| `lotusState` | String | 当前莲花状态（供 Widget 读取） |

### 6.3 HealthKit 数据读取计划

| 数据类型 | HK Identifier | 读取时机 | 用途 |
|----------|---------------|----------|------|
| 心率 | `.heartRate` | 前台每 5s (HKAnchoredObjectQuery) | 莲花动态 |
| HRV | `.heartRateVariabilitySDNN` | 后台推送 (HKObserverQuery) | 灵台状态判定 |
| 睡眠 | `.sleepAnalysis` | 每日首次启动 | 闭关结算 |
| 步数 | `.stepCount` | 按需查询 | 历练进度 |
| 活动能量 | `.activeEnergyBurned` | 按需查询 | 三环判定 |
| 运动时间 | `.appleExerciseTime` | 按需查询 | 三环判定 |
| 站立小时 | `.appleStandHour` | 按需查询 | 三环判定 |

---

## 7. 技术实现要点

### 7.1 HealthKit 权限管理

```
首次启动
  → 请求 HealthKit 授权（批量请求所有类型）
  → 授权成功 → 正常体验
  → 部分授权 → 降级：
      - 无心率权限 → 莲花显示静态图，隐藏灵台清心
      - 无睡眠权限 → 跳过闭关结算，固定给 +30 灵气
      - 无步数权限 → 隐藏云游历练，保留签到修为
  → 拒绝授权 → 纯签到养成模式 + 设置页引导重新开启
```

### 7.2 后台运行策略

| 场景 | 策略 |
|------|------|
| 心率监测 | `HKObserverQuery` 后台推送，前台时切换为 `HKAnchoredObjectQuery` |
| 睡眠数据 | 每日首次前台时查询昨夜数据 |
| 运动达标 | 后台 `HKObserverQuery` 监听步数变化，达标时发本地通知 |
| 表盘组件 | WidgetKit Timeline 每 15 分钟刷新 |
| 通知 | `UNUserNotificationCenter` 本地通知 |

### 7.3 性能约束

| 约束 | 要求 | 措施 |
|------|------|------|
| 内存 | < 25MB | 图片用 SF Symbols + SwiftUI 绘制，不用大位图 |
| 电池 | 后台功耗极低 | 非前台不轮询，依赖 HealthKit 推送 |
| 存储 | SwiftData < 5MB | 仅存储 30 天 DailyRecord，灵物永久保存 |
| 启动 | 冷启动 < 2 秒 | 首屏数据从 UserDefaults 读取，SwiftData 异步加载 |
| 动画 | 60fps | 莲花用 SwiftUI 原生动画，不用 Lottie |

---

## 8. 分阶段开发排期

> **前提：** 单人全栈开发，每天 2 小时业余时间，共 4 周

### Phase 1：骨架搭建 (Day 1–5)

| 天数 | 任务 | 产出 |
|------|------|------|
| D1 | Xcode 项目初始化 + 目录结构 + SwiftData 模型 | 可编译的空壳 App |
| D2 | 国风色彩/字体常量 + LingXiColors.swift | 设计 Token 就绪 |
| D3 | OnboardingView（3 屏引导 + HealthKit 授权请求） | 首次启动流程 |
| D4 | HomeView 主界面布局（静态莲花 + 境界显示 + 灵气条） | 主页面骨架 |
| D5 | TabView 导航 + JourneyView / CollectionView 空壳 | 导航完整可切换 |

**里程碑 1：** App 可安装到 Watch，首次启动引导完整，主界面有静态布局。

### Phase 2：HealthKit 集成 + 核心算法 (Day 6–12)

| 天数 | 任务 | 产出 |
|------|------|------|
| D6 | HealthKitManager — 授权 + 心率读取 | 真机可读心率 |
| D7 | HealthKitManager — 睡眠数据读取 + HRV 读取 | 完整健康数据层 |
| D8 | HealthKitManager — 步数/三环数据读取 | 运动数据就绪 |
| D9 | CultivationEngine — 睡眠评级算法 + 灵气计算 | 闭关逻辑完成 |
| D10 | CultivationEngine — 心率/HRV → 灵台状态判定 | 灵台逻辑完成 |
| D11 | CultivationEngine — 步数/三环 → 历练判定 + 修为累计 | 全部核心算法 |
| D12 | CopywritingEngine — 文案库 + 状态映射输出 | 文案系统就绪 |

**里程碑 2：** 真机上 HealthKit 数据读取成功，核心算法全部可运行。

### Phase 3：交互体验完善 (Day 13–20)

| 天数 | 任务 | 产出 |
|------|------|------|
| D13 | SleepRewardView — 晨起闭关结算弹窗 + 动效 | 闭关系统可用 |
| D14 | HeartLotusView — 莲花呼吸动画 + 状态色变 | 莲花动态视觉 |
| D15 | HeartLotusView — 心魔触发逻辑 + 关怀弹窗 + 触觉反馈 | 灵台系统完整 |
| D16 | JourneyView — 运动进度展示 + 达标奖励弹窗 | 历练系统可用 |
| D17 | CollectionView — 灵物图鉴列表 + 品级分类 | 收集系统可用 |
| D18 | 境界突破动效 + 全局修为/境界联动 | 成长系统完整 |
| D19 | HKObserverQuery 后台监听 + 本地通知 | 后台能力 |
| D20 | 联调测试：完整日常循环走一遍 | 全流程可用 |

**里程碑 3：** 完整的日常使用闭环可在真机上走通。

### Phase 4：表盘组件 + 打磨 (Day 21–28)

| 天数 | 任务 | 产出 |
|------|------|------|
| D21 | WidgetKit 组件 — accessoryCircular (灵莲图标) | 第一个表盘组件 |
| D22 | WidgetKit 组件 — accessoryRectangular (境界 + 灵气条) | 核心表盘组件 |
| D23 | WidgetKit 组件 — accessoryCorner + accessoryInline | 全部组件就绪 |
| D24 | 降级体验处理（部分权限/无权限场景） | 健壮性 |
| D25 | 文案润色 + 增加文案池多样性 | 内容打磨 |
| D26 | 性能优化：内存/电池/启动速度 | 性能达标 |
| D27 | 真机全流程测试 + Bug 修复 | 质量保障 |
| D28 | 最终打磨 + App Store 截图准备 | MVP 完成 |

**里程碑 4：** MVP 完成，可提交 App Store 审核。

---

## 9. 风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| HealthKit 权限被拒 | 核心功能不可用 | 三级降级策略（见 7.1），确保 App 不白屏 |
| watchOS 模拟器无传感器数据 | 开发调试困难 | 尽早真机测试；Mock 数据层供模拟器使用 |
| 莲花动画卡顿 | 体验崩塌 | 纯 SwiftUI 绘制，避免复杂粒子；预设降级为静态图 |
| SwiftData watchOS 稳定性 | 数据丢失 | 关键状态同时写 UserDefaults，SwiftData 作为持久层 |
| 内存超限 | App 被系统杀死 | 严控图片资源，不加载大位图，DailyRecord 仅保留 30 天 |
| 文案审美翻车 | 用户觉得土/尬 | 首批文案请文学向朋友审稿；后续可替换 |

---

## 10. 成功指标

| 指标 | MVP 目标 |
|------|----------|
| 冷启动时间 | < 2 秒 |
| 主界面渲染 | < 1 秒 |
| 莲花动画帧率 | 稳定 60fps |
| 晨起结算弹出 | 首次抬腕 < 3 秒 |
| 运动中电池消耗 | < 5%/小时（仅后台监听） |
| Crash-free rate | > 99.5% |
| 日活留存（D7） | > 40%（目标） |
| 表盘组件挂载率 | > 60% 用户（目标） |

---

## 11. 推荐开发工具与模式

### 11.1 Claude Code Skills

| 工具/Skill | 用途 | 使用时机 |
|------------|------|----------|
| **Plan Mode** | 每个 Phase 开始前做架构规划 | 开始新阶段时 |
| **spec-kit-skill** | 基于本 PRD 生成开发规格 | 项目启动时 |
| **phase-3-mockup** | UI 原型验证（交互体验完善阶段） | Phase 3 开始前 |
| **autonomous-skill** | 批量生成 Views/Models/文案库 | Phase 2-3 大量编码时 |
| **Explore Agent** | 查找 HealthKit/WidgetKit API 用法 | 遇到 API 问题时 |

### 11.2 模型选择

| 模型 | 适用场景 |
|------|----------|
| **Claude Opus 4.6** | 架构设计、CultivationEngine 算法、HealthKit 集成 |
| **Claude Sonnet 4.6** | UI 编码、文案库生成、重复性代码 |
| **Claude Haiku 4.5** | 简单修改、文件搜索、快速问答 |

---

## 附录

### A. 参考资源
- [HealthKit 官方文档](https://developer.apple.com/documentation/healthkit)
- [WidgetKit Complications](https://developer.apple.com/documentation/widgetkit/creating-accessory-widgets-and-watch-complications)
- [watchOS 开发入门](https://developer.apple.com/watchos/)
- [SwiftUI 2025 架构趋势](https://dimillian.medium.com/swiftui-in-2025-forget-mvvm-262ff2bbd2ed)
- [watchOS 开发实战经验](https://fatbobman.com/en/posts/watchos-development-pitfalls-and-practical-tips)

### B. 竞品参考
- **Finch** — 宠物养成 + 心理健康，验证了"健康数据 → 可爱养成"模式的可行性
- **Standland** — 站立数据 → 角色收集，验证了 HealthKit 驱动收集玩法
- **Forest** — 专注 → 种树，验证了"行为 → 视觉奖励"的成瘾性

### C. 灵物清单（MVP 初始池 20 个）

| 编号 | 名称 | 品级 | 获取方式 |
|------|------|------|----------|
| 1 | 清泉一缕 | 凡品 | 每日签到 |
| 2 | 山间野花 | 凡品 | 每日签到 |
| 3 | 松风一缕 | 凡品 | 中品闭关 |
| 4 | 晨露凝珠 | 灵品 | 上品闭关 |
| 5 | 玉髓 | 灵品 | 上品闭关 |
| 6 | 灵鹤羽 | 灵品 | 步数 ≥ 5000 |
| 7 | 百花仙露 | 灵品 | 三环闭合 |
| 8 | 青云石 | 灵品 | 云游 3 次累计 |
| 9 | 碧波珠 | 灵品 | 云游 7 次累计 |
| 10 | 天山雪莲 | 仙品 | 仙品闭关 |
| 11 | 琼浆玉露 | 仙品 | 仙品闭关 |
| 12 | 金缕丝 | 仙品 | 连续 7 天全达标 |
| 13 | 凤凰涅槃羽 | 仙品 | 境界突破奖励 |
| 14 | 九天玄铁 | 仙品 | 累计修为 1000 |
| 15 | 太虚灵芝 | 仙品 | 云游 14 次累计 |
| 16 | 龙涎香 | 仙品 | 连续 14 天全达标 |
| 17 | 星辰碎片 | 仙品 | 累计修为 2000 |
| 18 | 蟠桃 | 神品 | 连续 21 天全达标 |
| 19 | 混沌灵珠 | 神品 | 连续 30 天全达标 |
| 20 | 鸿蒙之露 | 神品 | 达到归真境·天成 |
