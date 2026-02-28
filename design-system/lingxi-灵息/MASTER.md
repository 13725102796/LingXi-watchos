# 灵息 (LingXi) — Design System Master File

> **LOGIC:** When building a specific page, first check `design-system/lingxi-灵息/pages/[page-name].md`.
> If that file exists, its rules **override** this Master file.
> If not, strictly follow the rules below.

---

**Project:** LingXi 灵息 — watchOS 独立修仙养成模拟器
**Platform:** watchOS 10+ (Apple Watch 41mm / 45mm)
**Framework:** SwiftUI + SwiftData
**Updated:** 2026-02-28
**Style:** OLED Dark + 国风水墨 + Soft Glassmorphism

---

## Color Palette

### Base Colors (OLED Optimized)

| SwiftUI Name | Hex | Contrast vs BG | Role |
|-------------|-----|----------------|------|
| `moYuan` (墨渊) | `#000000` | — | **Primary background** (OLED pure black) |
| `xuanYe` (玄夜) | `#0A0E14` | — | Card/popup background |
| `shuangXue` (霜雪) | `#F0EDE8` | 19.4:1 AAA | **Primary text** (warm white) |
| `yuanShanDai` (远山黛) | `#8A9B9B` | 6.2:1 AA | Secondary text |
| `xiuYan` (岫烟) | `#4A5568` | 3.2:1 | Disabled/lowest text (large only) |
| `anWen` (暗纹) | `#1A1A1E` | — | Progress bar track, dividers |

### Accent Colors

| SwiftUI Name | Hex | Contrast vs BG | Semantic |
|-------------|-----|----------------|----------|
| `yueBai` (月白) | `#D6ECF0` | 16.7:1 AAA | Lotus default, purity |
| `qingCi` (青瓷) | `#A8D8D8` | 12.1:1 AAA | Calm state, primary button |
| `ouHe` (藕荷) | `#E0B4C8` | 10.8:1 AAA | Spirit energy, feminine warmth |
| `liuJin` (鎏金) | `#D4A853` | 8.5:1 AA | Achievement, breakthrough |
| `zhuSha` (朱砂) | `#D4605A` | 5.4:1 AA | **Warning only** (heart demon) |
| `yanZi` (烟紫) | `#B8A9C9` | 8.8:1 AA | Rare/divine items |

### Gradients

```swift
// Lotus breathing (default - calm)
LinearGradient(colors: [.yueBai, .qingCi], startPoint: .top, endPoint: .bottom)

// Lotus breathing (agitated)
LinearGradient(colors: [.yueBai, .ouHe], startPoint: .top, endPoint: .bottom)

// Spirit energy / cultivation bar
LinearGradient(colors: [.ouHe, .qingCi], startPoint: .leading, endPoint: .trailing)

// Breakthrough golden burst
RadialGradient(colors: [.liuJin, .shuangXue.opacity(0)], center: .center, startRadius: 0, endRadius: 100)

// Heart demon pulse
RadialGradient(colors: [.zhuSha, .xuanYe], center: .center, startRadius: 0, endRadius: 60)
```

### Glassmorphism Layers

```swift
// Popup background
.background(.ultraThinMaterial)
.clipShape(RoundedRectangle(cornerRadius: 16))

// Card border glow
.overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))

// Soft glow behind lotus
.shadow(color: .qingCi.opacity(0.15), radius: 20)
```

---

## Typography (SF Pro — System Font Only)

| Level | Size | Weight | LineSpacing | SwiftUI | Usage |
|-------|------|--------|-------------|---------|-------|
| Display | 32pt | `.ultraLight` | 1.2 | `.system(size: 32, weight: .ultraLight)` | Core numbers (steps, sleep hours) |
| Title | 20pt | `.light` | 1.3 | `.system(size: 20, weight: .light)` | Realm name, popup title |
| Headline | 17pt | `.medium` | 1.3 | `.system(size: 17, weight: .medium)` | Status text ("灵台清明") |
| Body | 15pt | `.regular` | 1.5 | `.system(size: 15)` | Poetic copy |
| Caption | 13pt | `.regular` | 1.4 | `.system(size: 13)` | Item names, descriptions |
| Footnote | 12pt | `.light` | 1.3 | `.system(size: 12, weight: .light)` | HR/HRV data, timestamps |

**Rules:**
- Max 3 type levels per screen
- `.ultraLight` for "ethereal" number display only
- Body at 1.5 line-height for Chinese readability
- Never use `.bold` or `.black` — too aggressive for the aesthetic

---

## Spacing (8pt Grid)

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4pt | Icon-to-text gap |
| `sm` | 8pt | Same-group spacing |
| `md` | 12pt | Component spacing |
| `lg` | 16pt | Section spacing |
| `xl` | 24pt | Page top/bottom padding |

**Screen Safe Area:**
- 41mm: 10pt horizontal inset → 156pt content width
- 45mm: 12pt horizontal inset → 174pt content width

---

## Component Specs

### Buttons

```swift
// Primary action button
Button("收入囊中") { ... }
    .frame(maxWidth: .infinity, minHeight: 44)
    .background(Color.qingCi)
    .foregroundColor(Color.moYuan)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .font(.system(size: 15, weight: .medium))

// Text-only secondary button
Button("知道了") { ... }
    .foregroundColor(Color.yuanShanDai)
    .font(.system(size: 15))
```

### Progress Bar

```swift
// Spirit energy / cultivation bar
ZStack(alignment: .leading) {
    RoundedRectangle(cornerRadius: 4)
        .fill(Color.anWen)
        .frame(height: 6)
    RoundedRectangle(cornerRadius: 4)
        .fill(LinearGradient(colors: [.ouHe, .qingCi], ...))
        .frame(width: fillWidth, height: 6)
}
```

### Cards (Popup/Reward)

```swift
VStack { ... }
    .padding(16)
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .overlay(
        RoundedRectangle(cornerRadius: 16)
            .stroke(Color.white.opacity(0.08), lineWidth: 1)
    )
```

### Collection Grid Item

```swift
// 3-column grid, each cell 56×56pt
VStack(spacing: 4) {
    Image(iconName)
        .frame(width: 40, height: 40)
    Text(name)
        .font(.system(size: 12, weight: .light))
}
.frame(width: 56, height: 56)
// Uncollected: .opacity(0.3) + "?" overlay
```

### Activity Rings (Chinese-styled)

```swift
// 3 arcs: ouHe (Move), qingCi (Exercise), liuJin (Stand)
Circle()
    .trim(from: 0, to: progress)
    .stroke(Color.ouHe, style: StrokeStyle(lineWidth: 2, lineCap: .round))
    .frame(width: 44, height: 44)
    .rotationEffect(.degrees(-90))
// Background arc: Color.anWen lineWidth 2
```

---

## Animation Rules

### Continuous (Max 1 per screen)

| Animation | Params | Duration |
|-----------|--------|----------|
| Lotus breathing (calm) | scaleEffect 0.96–1.04, opacity 0.7–1.0 | 3.0s easeInOut repeat |
| Lotus agitated | scaleEffect 0.94–1.06 | 1.5s easeInOut repeat |
| Lotus heart demon | opacity 0.4–1.0 (red tint) | 0.8s easeInOut repeat |

### Triggered (One-shot)

| Animation | Params | Duration |
|-----------|--------|----------|
| Popup slide-in | offset + opacity | spring(0.5, 0.8) |
| Item drop | offset + scale | spring(0.6, 0.7) |
| Progress fill | frame width | easeOut 0.8s |
| Breakthrough burst | scaleEffect + opacity (radial) | easeOut 0.8s |

### Haptics

| Event | Type |
|-------|------|
| Heart demon | `.notification` ×2 |
| Sleep reward (best) | `.success` |
| Breakthrough | `.notification` ×2 |
| Button tap | `.click` |

### Accessibility

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

// If reduceMotion: static lotus + colored border ring, no animations
// All popups: instant appear, no slide
// Progress bars: instant fill, no animation
```

---

## Z-Index Layers

| Layer | Z | Background | Usage |
|-------|---|-----------|-------|
| L0 Base | 0 | `#000000` | Screen |
| L1 Content | 1 | transparent | Lotus, text, bars |
| L2 Card | 10 | `#0A0E14` + border | Item cards, grid cells |
| L3 Popup | 20 | `.ultraThinMaterial` | Reward popups, alerts |
| L4 Celebration | 30 | `rgba(0,0,0,0.6)` + particles | Breakthrough |

---

## Anti-Patterns (NEVER Use)

- ❌ **Emoji as UI icons** — Use SF Symbols or SwiftUI Shape drawing
- ❌ **Pure white (#FFFFFF) text** — Use warm white `#F0EDE8` instead
- ❌ **Red for non-warning** — `zhuSha` only for heart demon state
- ❌ **Background #2C2C2E or lighter** — Wastes OLED power; use `#000000`
- ❌ **More than 1 continuous animation** — Distracting on tiny screen
- ❌ **Bold/Black font weight** — Too aggressive; max `.medium`
- ❌ **Large bright color areas** — Keep accent color ≤ 15% of screen
- ❌ **Ignoring reduceMotion** — Always check accessibility preference
- ❌ **Nested ScrollViews** — watchOS handles poorly; use flat layout
- ❌ **Custom fonts** — watchOS only supports SF Pro system font

---

## Pre-Delivery Checklist

Before delivering any SwiftUI view:

- [ ] Background is `#000000` (Color.moYuan), not dark gray
- [ ] All text meets AA contrast (4.5:1) against background
- [ ] Max 3 font size levels used on screen
- [ ] Touch targets ≥ 44×44 pt
- [ ] `accessibilityReduceMotion` checked
- [ ] Only 1 continuous animation active
- [ ] Haptics used appropriately (not excessive)
- [ ] No emoji icons in production code
- [ ] Popups dismissible by swipe-down
- [ ] Both 41mm and 45mm layouts verified
