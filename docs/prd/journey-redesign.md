# 云游历练页面重设计：三大修仙化运动指标

## 一、设计概述

将 Apple Watch 三项运动指标（Move / Exercise / Stand）彻底改造为修仙世界观的沉浸式体验：

| Apple 指标 | 修仙映射 | 视觉呈现 |
|-----------|---------|---------|
| **活动消耗** (卡路里) | 聚灵·玉净瓶 | 琉璃瓶中仙露渐满 |
| **锻炼时长** (分钟) | 云游·秘境奇遇 | 水墨画卷 + 灵物掉落 |
| **站立次数** (小时) | 周天·本命星图 | 十二时辰星宿点亮 |

**页面布局** — 极简垂直滚动流：
1. **首屏** (玉净瓶)：占据 ~70% 屏高，展示灵气收集情况
2. **向下滑动** (奇遇录)：今日解锁的风景画卷或灵植
3. **最底部** (星宿阵)：12 颗星辰排列，点亮进度一目了然

---

## 二、三大组件详细设计

### 2.1 聚灵·玉净瓶与凝露 (Move / 卡路里)

**修仙映射**：每消耗一定能量 = 在天地间汲取灵气，凝结为仙露。

**视觉设计**：
- 页面顶部：「聚 灵」衬线体标题 + 卡路里计数（金色）
- 中央主体：晶莹剔透的**玉净瓶**（贝塞尔曲线绘制轮廓）
- 瓶内仙露：随卡路里消耗增加，"鸿蒙仙露"慢慢涨满
  - 双层正弦波水面 + 渐变填充（深青 → 浅玉 → 淡雾）
  - 水波持续微微荡漾（2.4s 循环呼吸动画）
- 瓶身：半透明高光模拟琉璃质感
- 满溢时：金色光晕 + 步数标签

**文案互动**：
| 状态 | 文案 |
|------|------|
| 空 (0 kcal) | "灵气尚未凝聚，仙子今日尚需迈步。" |
| 凝聚中 (1-399 kcal) | "仙露正在凝聚，继续前行可成甘露。" |
| 满溢 (≥400 kcal) | "仙子今日步履轻盈，已凝结一滴极品仙露，可润泽容颜。" |

**动画**：
- 进入时：仙露从 0 缓慢填满到当前进度（1.2s easeOut）
- 持续：水面波纹循环（2.4s easeInOut repeatForever）

---

### 2.2 云游·秘境奇遇 (Exercise / 分钟)

**修仙映射**：主动锻炼 = 驾起祥云去各大秘境游历。

**视觉设计**：
- 标题行：「云 游」+ 运动分钟数（青瓷色）
- **未达标** (< 30 min)：
  - 水墨山影暗纹背景（极淡，似有若无）
  - 云雾图标 + "云深不知处，待仙子探寻"
- **已达标** (≥ 30 min)：
  - 展示最新解锁仙境名 + 描述
  - 灵物图标掉落（SF Symbol + 品级色光晕）
  - 山水图标渐变发光

**文案互动**：
| 状态 | 文案 |
|------|------|
| 未达标 | "云深不知处，待仙子探寻。" |
| 已达标 | "仙子今日御风行万里，于昆仑虚深处寻得一株『九叶仙芝』。" |
| 已达标 (轮换) | "足迹所至，奇遇自来，秘境已为仙子开启。" |
| 已达标 (轮换) | "云游历练有成，灵物现身，今日因缘深厚。" |

**收集反馈**：达标后展示的灵物/仙境每日不同（确定性轮换），激励明天继续运动解锁新奇遇。

---

### 2.3 周天·点亮本命星图 (Stand / 小时)

**修仙映射**：久坐气血凝滞，站起来活动 = 运转小周天，冲破经脉阻滞。

**视觉设计**：
- 标题行：「周 天」+ 时辰计数（月白色）
- **星宿图**：12 颗星辰代表十二时辰
  - 布局：双行蜂巢排列（上排 6 + 下排 6 交错）
  - 已亮星：5pt 月白实心圆 + 14pt 径向光晕 + 呼吸闪烁
  - 未亮星：3pt 暗灰色圆点
  - 星座连线：亮星之间 0.5pt 半透明连线
- 十二时辰：子、丑、寅、卯、辰、巳、午、未、申、酉、戌、亥

**文案互动**：
| 状态 | 文案 |
|------|------|
| 无 (0 小时) | "子时将至，灵脉待启，静候周天运转。" |
| 部分 (1-11 小时) | "气血流转，灵脉畅通，又点亮了一颗太微垣星辰。" |
| 圆满 (12 小时) | "十二时辰圆满，周天功法大成，灵气充盈周身。" |

**动画**：
- 进入时：星辰逐颗点亮（每颗间隔 80ms，staggered reveal）
- 点亮完成后：全体已亮星启动闪烁循环（1.8s easeInOut）

---

## 三、色彩系统

复用项目现有 `LingXiColors` 设计系统：

| 色彩 Token | Hex | 用途 |
|-----------|-----|------|
| `gold` | #C8A96E | 玉净瓶标题、满溢光晕、卡路里数字 |
| `teal` | #4ECDC4 | 云游标题、山水图标、运动分钟 |
| `lotusCalm` | #A8D8D8 | 仙露深层渐变色 |
| `lotusCalmLight` | #D6ECF0 | 仙露表面浅色 |
| `surface` | #12121A | 卡片背景 |
| `textPrimary` | #F0EDE4 | 主文字 |
| `textSecondary` | #8A8A9A | 次要文字、未达标文案 |

星图专用月白色：`#E8E4F4`（微泛薰衣草的冷白），定义为组件内私有常量。

---

## 四、实现计划

### Phase 1: 设计系统扩展

| 文件 | 变更 |
|------|------|
| `Design/LingXiAnimations.swift` | 添加 4 个动画预设 (waterWave, dewFill, starTwinkle, starLight) |
| `Resources/copywriting.json` | 添加 `journeyView` 顶级 key (vase/encounter/star 文案) |
| `Services/StaticDataLoader.swift` | 添加 `JourneyViewCopy` 结构体 |

### Phase 2: 构建三个独立子组件

| 新建文件 | 组件 |
|---------|------|
| `Views/Journey/JadeVaseSection.swift` | 聚灵·玉净瓶（含 VaseOutlineShape, LiquidFillView） |
| `Views/Journey/EncounterSection.swift` | 云游·秘境奇遇（含 InkWashMountainView） |
| `Views/Journey/StarChartSection.swift` | 周天·本命星图（含 StarConstellationView） |

### Phase 3: 集成到 JourneyView

| 文件 | 变更 |
|------|------|
| `Views/Journey/JourneyView.swift` | 重写 body，替换为三个新 section 组合 |
| `Views/Journey/ActivityRingView.swift` | 可选删除（不再被引用） |

### Phase 4: 验证

- refreshActivity() 仍正常获取 HealthKit 数据
- JourneyRewardPopup 弹窗不受影响
- 深链接 lingxi://tab/1 正常跳转
- watchOS 模拟器 + 真机编译通过

---

## 五、图片素材清单 (AI 生成)

> **策略：关键视觉用 AI 生成图片，动态效果用 SwiftUI 代码叠加。**
> 生成工具：Midjourney / DALL-E / Stable Diffusion

### 通用生成约束

```
所有图片统一后缀 prompt:
  --ar 按下方比例 --style raw --no text, watermark, signature, border
  背景色: 纯黑 #0A0A0F 或透明
  输出: PNG, 去除背景后导入 Xcode Assets
  命名规范: snake_case, 加 @2x/@3x 后缀
```

---

### 5.1 玉净瓶 (聚灵 Section 核心素材)

| 编号 | 资源名 | 尺寸 (px) | 说明 |
|------|--------|-----------|------|
| V1 | `jade_vase` | 240×320 | 玉净瓶主体（空瓶，用于叠加仙露动效） |
| V2 | `jade_vase_glow` | 240×320 | 满溢金光版（叠加在 V1 上，满 400kcal 切换） |

**AI Prompt — V1 (空瓶)**:
```
Chinese traditional jade vase (玉净瓶), translucent celadon jade material,
elegant narrow neck and wide belly, classical Song dynasty form,
soft inner glow, luminous teal-green tint (#4ECDC4), subtle light
refraction on surface, on pure black background (#0A0A0F),
minimalist, digital art, Apple Watch UI icon style,
high detail, centered composition --ar 3:4 --style raw
--no text, watermark, cracks, chips, stand, table
```

**AI Prompt — V2 (满溢金光)**:
```
Chinese traditional jade vase (玉净瓶), translucent celadon jade,
filled with glowing golden-teal liquid overflowing from the top,
ethereal golden mist rising, warm radiance (#C8A96E) mixing with
teal (#4ECDC4), magical dew drops floating, celestial atmosphere,
on pure black background, digital art, Apple Watch UI style --ar 3:4
--style raw --no text, watermark
```

**代码叠加**：SwiftUI `Canvas` 绘制正弦波水面动画，叠在 V1 图片的瓶身区域内。仙露填充高度随卡路里变化。

---

### 5.2 水墨山影 (云游 Section 空态背景)

| 编号 | 资源名 | 尺寸 (px) | 说明 |
|------|--------|-----------|------|
| M1 | `ink_mountains_empty` | 360×144 | 未达标时的朦胧山影背景 |

**AI Prompt**:
```
Minimalist Chinese ink wash painting (水墨画), distant misty mountains,
two overlapping mountain silhouettes, thin fog layer between peaks,
extremely subtle and ethereal, very low opacity feel, desaturated
blue-grey tones, traditional shuimo style, on pure black background
(#0A0A0F), horizontal landscape composition, Apple Watch card size
--ar 5:2 --style raw --no text, watermark, sun, moon, trees, people
```

**用法**：作为 EncounterSection 未达标状态的背景图，叠加 `.opacity(0.15)` 呈现若隐若现的效果。

---

### 5.3 十二秘境仙景 (云游 Section 达标奖励)

对应 `sceneries.json` 的 12 个仙境。**这是核心收集奖励，品质要高。**

| 编号 | 资源名 | 仙境名 | 尺寸 (px) |
|------|--------|--------|-----------|
| S01 | `scenery_misty_mountains` | 云雾仙山 | 320×240 |
| S02 | `scenery_bamboo_forest` | 翠竹幽林 | 320×240 |
| S03 | `scenery_lotus_lake` | 莲花灵湖 | 320×240 |
| S04 | `scenery_waterfall_gorge` | 飞瀑幽谷 | 320×240 |
| S05 | `scenery_cherry_blossom` | 樱花仙境 | 320×240 |
| S06 | `scenery_mountain_peak` | 云端峰顶 | 320×240 |
| S07 | `scenery_ancient_temple` | 古刹钟声 | 320×240 |
| S08 | `scenery_starry_night` | 星河夜渡 | 320×240 |
| S09 | `scenery_aurora_peaks` | 极光仙域 | 320×240 |
| S10 | `scenery_golden_sea` | 金光圣境 | 320×240 |
| S11 | `scenery_void_space` | 太虚幻境 | 320×240 |
| S12 | `scenery_immortal_realm` | 仙界彼岸 | 320×240 |

**通用 Prompt 前缀**:
```
Chinese traditional ink wash painting (水墨画) with subtle watercolor tint,
ethereal Xianxia (修仙) fantasy landscape, low saturation, soft edges
fading to transparency, dreamlike atmosphere, miniature scene,
on pure black background (#0A0A0F), Apple Watch card illustration
--ar 4:3 --style raw --no text, watermark, people, animals
```

**逐张 Prompt 后缀**:

| 编号 | 追加描述 |
|------|---------|
| S01 | `layered distant mountains shrouded in clouds and mist, blue-grey monochrome, serene mood` |
| S02 | `bamboo grove with dappled light filtering through, emerald green tint, calm breeze feeling` |
| S03 | `tranquil lake with blooming lotus flowers, teal and cyan reflections, spiritual glow on water surface` |
| S04 | `tall waterfall cascading into a deep gorge, spray mist rising, blue-white tones, energetic` |
| S05 | `cherry blossom trees in full bloom, pink petals drifting in wind, pale pink and white, joyful spring` |
| S06 | `solitary peak piercing above clouds, golden sunrise light on summit, majestic and vast` |
| S07 | `ancient Buddhist temple with curved eaves, pine trees, ochre and dark ink tones, sacred atmosphere` |
| S08 | `milky way galaxy stretching across night sky, countless stars, deep indigo and purple, transcendent` |
| S09 | `aurora borealis flowing over snow-capped peaks, green and purple ribbons of light, mystical` |
| S10 | `golden divine light radiating from horizon, auspicious clouds rolling, warm gold tones, divine` |
| S11 | `cosmic void with floating celestial bodies, dark purple-black with scattered star dust, cosmic` |
| S12 | `celestial immortal palace above clouds, golden spires, warm white and gold radiance, paradise` |

---

### 5.4 星宿底图 (周天 Section 背景)

| 编号 | 资源名 | 尺寸 (px) | 说明 |
|------|--------|-----------|------|
| T1 | `star_chart_bg` | 360×160 | 星图底纹（星云 + 经络线暗纹） |

**AI Prompt**:
```
Subtle celestial star map background, Chinese traditional astronomy
star chart (星宿图) style, very faint constellation lines and meridian
marks, dark nebula clouds in deep indigo (#0F0F1A), barely visible
star dust, elegant and minimal, for Apple Watch dark UI background
--ar 9:4 --style raw --no text, watermark, bright stars, planets
```

**用法**：作为 StarChartSection 的底层背景 `.opacity(0.3)`，SwiftUI 代码在上层绘制动态星辰点亮效果。

---

### 5.5 代码绘制部分（不需要图片）

以下效果继续用 SwiftUI 代码实现，因为它们是动态的：

| 效果 | 实现方式 | 原因 |
|------|---------|------|
| 仙露水面波纹 | `Canvas` 正弦波 + 渐变 | 需要实时动画，随卡路里数据变化 |
| 仙露填充高度 | SwiftUI `.clipShape` + 动画 | 需要精确映射到 calories 进度 |
| 星辰点亮/闪烁 | `Circle` + `RadialGradient` + 动画 | 需要逐颗 stagger 动画 + 持续闪烁 |
| 星座连线 | `Canvas` 线条 | 需要根据亮星数量动态绘制 |
| 满溢金光 | `RadialGradient` 叠层 | 简单渐变，代码比图片更灵活 |

---

## 六、素材生成后处理流程

### 步骤 1: AI 生成
用上方 prompt 在 Midjourney/DALL-E 生成，每个素材选最佳 1 张。

### 步骤 2: 后处理
- **去背景**：用 remove.bg 或 Photoshop 去除黑色背景，导出透明 PNG
- **调色**：确保整体色调与 app 色系一致（墨渊黑底、金青色系）
- **裁切**：按上方尺寸裁切，确保主体居中

### 步骤 3: 导入 Xcode
- 放入 `LingXi Watch App/Assets.xcassets/` 对应分组
- 配置 @2x 和 @3x（Apple Watch Series 11 使用 @2x）
- Render As: Template Image（仙境画卷除外，使用 Original）

### 素材存放目录

#### AI 生成原图 (未处理)

存放在项目根目录 `assets/raw/`，按类别分文件夹：

```
applewatch-mvp/
└── assets/
    └── raw/                          ← AI 生成的原始图片
        ├── jade-vase/
        │   ├── jade_vase_v1.png
        │   ├── jade_vase_v2.png
        │   └── ...                   ← 多个候选，选最佳
        ├── encounter/
        │   ├── ink_mountains_empty_v1.png
        │   └── ...
        ├── sceneries/
        │   ├── misty_mountains_v1.png
        │   ├── bamboo_forest_v1.png
        │   └── ...                   ← 12 张仙境
        └── star-chart/
            ├── star_chart_bg_v1.png
            └── ...
```

#### 处理后的正式素材 (去背 + 裁切)

存放在 `assets/processed/`，文件名即最终资源名：

```
applewatch-mvp/
└── assets/
    └── processed/                    ← 去背、调色、裁切后的最终 PNG
        ├── jade_vase.png             (240×320)
        ├── jade_vase_glow.png        (240×320)
        ├── ink_mountains_empty.png   (360×144)
        ├── star_chart_bg.png         (360×160)
        ├── scenery_misty_mountains.png    (320×240)
        ├── scenery_bamboo_forest.png      (320×240)
        ├── scenery_lotus_lake.png         (320×240)
        ├── scenery_waterfall_gorge.png    (320×240)
        ├── scenery_cherry_blossom.png     (320×240)
        ├── scenery_mountain_peak.png      (320×240)
        ├── scenery_ancient_temple.png     (320×240)
        ├── scenery_starry_night.png       (320×240)
        ├── scenery_aurora_peaks.png       (320×240)
        ├── scenery_golden_sea.png         (320×240)
        ├── scenery_void_space.png         (320×240)
        └── scenery_immortal_realm.png     (320×240)
```

#### Xcode Assets Catalog (正式引用)

从 `assets/processed/` 导入到 Xcode 工程内：

```
LingXi/LingXi Watch App/Assets.xcassets/
├── AccentColor.colorset/             ← 已有
├── AppIcon.appiconset/               ← 已有
├── JadeVase/                         ← 新增分组
│   ├── jade_vase.imageset/
│   │   ├── jade_vase@2x.png
│   │   └── Contents.json
│   └── jade_vase_glow.imageset/
│       ├── jade_vase_glow@2x.png
│       └── Contents.json
├── Encounter/                        ← 新增分组
│   ├── ink_mountains_empty.imageset/
│   │   ├── ink_mountains_empty@2x.png
│   │   └── Contents.json
│   └── Sceneries/                    ← 子分组
│       ├── scenery_misty_mountains.imageset/
│       ├── scenery_bamboo_forest.imageset/
│       ├── scenery_lotus_lake.imageset/
│       ├── scenery_waterfall_gorge.imageset/
│       ├── scenery_cherry_blossom.imageset/
│       ├── scenery_mountain_peak.imageset/
│       ├── scenery_ancient_temple.imageset/
│       ├── scenery_starry_night.imageset/
│       ├── scenery_aurora_peaks.imageset/
│       ├── scenery_golden_sea.imageset/
│       ├── scenery_void_space.imageset/
│       └── scenery_immortal_realm.imageset/
└── StarChart/                        ← 新增分组
    └── star_chart_bg.imageset/
        ├── star_chart_bg@2x.png
        └── Contents.json
```

**Xcode 配置说明**：
- Apple Watch Series 11 使用 **@2x** 分辨率
- 仙境画卷 Render As: **Original**（保留原色）
- 玉净瓶/山影/星图 Render As: **Original**（保留原色）
- 所有 imageset 的 `Contents.json` 中 `"appearances"` 设为 `"luminosity": "dark"`（仅暗色模式）

### 总计素材数量
| 类别 | 数量 | 存放位置 |
|------|------|---------|
| 玉净瓶 | 2 张 | `assets/processed/jade_vase*.png` → `Assets.xcassets/JadeVase/` |
| 水墨山影 | 1 张 | `assets/processed/ink_mountains_empty.png` → `Assets.xcassets/Encounter/` |
| 秘境仙景 | 12 张 | `assets/processed/scenery_*.png` → `Assets.xcassets/Encounter/Sceneries/` |
| 星宿底图 | 1 张 | `assets/processed/star_chart_bg.png` → `Assets.xcassets/StarChart/` |
| **合计** | **16 张 PNG** | |
