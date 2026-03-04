import WidgetKit
import SwiftUI
import AppIntents

// MARK: - 表盘数据

struct LingXiEntry: TimelineEntry {
    let date: Date
    let realmName: String
    let cultivation: Int
    let nextThreshold: Int
    let lotusState: String
    let complicationLabel: String
    let stateLabel: String
    let heartRate: Int
    let selectedItem: SpiritItemEntity?
    let deepLink: URL                    // 点击跳转的深链接

    var progress: Double {
        guard nextThreshold > 0 else { return 1 }
        return min(1.0, Double(cultivation) / Double(nextThreshold))
    }
    var percentText: String { "\(Int(progress * 100))%" }
}

// MARK: - AppIntent Timeline Provider

struct LingXiConfigProvider: AppIntentTimelineProvider {
    typealias Entry = LingXiEntry
    typealias Intent = SelectSpiritItemIntent

    let defaultItemId: String
    let deepLink: URL                    // 该组件点击后打开的页面

    func placeholder(in context: Context) -> LingXiEntry {
        makeEntry(item: resolveDefaultItem())
    }

    func snapshot(for configuration: SelectSpiritItemIntent,
                  in context: Context) async -> LingXiEntry {
        loadEntry(configuration: configuration)
    }

    func timeline(for configuration: SelectSpiritItemIntent,
                  in context: Context) async -> Timeline<LingXiEntry> {
        let entry = loadEntry(configuration: configuration)
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }

    func recommendations() -> [AppIntentRecommendation<SelectSpiritItemIntent>] {
        SpiritItemEntity.allItems.prefix(5).map { item in
            var intent = SelectSpiritItemIntent()
            intent.spiritItem = item
            // watchOS bug: 插值字符串会导致 Widget Extension 崩溃，必须用变量
            let desc: String = item.name
            return .init(intent: intent, description: desc)
        }
    }

    private func resolveDefaultItem() -> SpiritItemEntity {
        SpiritItemEntity.allItems.first { $0.id == defaultItemId }
            ?? SpiritItemEntity.defaultLotus
    }

    private func loadEntry(configuration: SelectSpiritItemIntent) -> LingXiEntry {
        let item = configuration.spiritItem ?? resolveDefaultItem()
        return makeEntry(item: item)
    }

    private func makeEntry(item: SpiritItemEntity) -> LingXiEntry {
        let defaults = UserDefaults(suiteName: ComplicationKeys.appGroupID)
        let rawLevel = defaults?.integer(forKey: ComplicationKeys.currentRealmLevel) ?? 0

        if rawLevel == 0 {
            return LingXiEntry(
                date: Date(), realmName: "清心境", cultivation: 72,
                nextThreshold: 100, lotusState: "calm",
                complicationLabel: "凝神", stateLabel: "灵台清明",
                heartRate: 68, selectedItem: item, deepLink: deepLink
            )
        }

        let level = max(1, min(9, rawLevel))
        let labels = ["凝神","练气","筑基","金丹","元婴","化神","炼虚","合体","大乘"]
        let name = defaults?.string(forKey: ComplicationKeys.currentRealmName) ?? "凡心初悟"
        let lotusRaw = defaults?.string(forKey: ComplicationKeys.lotusState) ?? "calm"
        let hr = defaults?.integer(forKey: ComplicationKeys.heartRate) ?? 68

        return LingXiEntry(
            date: Date(), realmName: name,
            cultivation: max(0, defaults?.integer(forKey: ComplicationKeys.currentCultivation) ?? 0),
            nextThreshold: max(1, defaults?.integer(forKey: ComplicationKeys.nextRealmThreshold) ?? 100),
            lotusState: lotusRaw,
            complicationLabel: labels[min(level-1, labels.count-1)],
            stateLabel: lotusRaw == "ripple" ? "心绪微澜" : (lotusRaw == "demon" ? "心魔暗生" : "灵台清明"),
            heartRate: hr > 0 ? hr : 68,
            selectedItem: item, deepLink: deepLink
        )
    }
}

// MARK: - WidgetBundle（4 个独立组件，各有不同默认灵物）

@main
struct LingXiWidgetBundle: WidgetBundle {
    var body: some Widget {
        LingXiComplication1()
        LingXiComplication2()
        LingXiComplication3()
        LingXiComplication4()
    }
}

// 组件壹 — 默认：清泉 → 点击跳转「首页·境界」
struct LingXiComplication1: Widget {
    let kind = "LingXiComplication1"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectSpiritItemIntent.self,
            provider: LingXiConfigProvider(
                defaultItemId: "qingquan",
                deepLink: URL(string: "lingxi://tab/0")!      // 首页
            )
        ) { entry in
            LingXiComplicationView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("灵息·清泉")
        .description("点击打开首页·境界")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular,
                            .accessoryCorner, .accessoryInline])
    }
}

// 组件贰 — 默认：凤凰羽 → 点击跳转「云游历练」
struct LingXiComplication2: Widget {
    let kind = "LingXiComplication2"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectSpiritItemIntent.self,
            provider: LingXiConfigProvider(
                defaultItemId: "fenghuangyu",
                deepLink: URL(string: "lingxi://tab/1")!      // 历练
            )
        ) { entry in
            LingXiComplicationView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("灵息·凤凰羽")
        .description("点击打开云游历练")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular,
                            .accessoryCorner, .accessoryInline])
    }
}

// 组件叁 — 默认：夜华 → 点击跳转「灵物图鉴」
struct LingXiComplication3: Widget {
    let kind = "LingXiComplication3"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectSpiritItemIntent.self,
            provider: LingXiConfigProvider(
                defaultItemId: "yehua",
                deepLink: URL(string: "lingxi://tab/2")!      // 灵物图鉴
            )
        ) { entry in
            LingXiComplicationView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("灵息·夜华")
        .description("点击打开灵物图鉴")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular,
                            .accessoryCorner, .accessoryInline])
    }
}

// 组件肆 — 默认：天山雪莲 → 点击跳转「灵物详情」
struct LingXiComplication4: Widget {
    let kind = "LingXiComplication4"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectSpiritItemIntent.self,
            provider: LingXiConfigProvider(
                defaultItemId: "tianshan_xuelian",
                deepLink: URL(string: "lingxi://item/tianshan_xuelian")!  // 灵物详情
            )
        ) { entry in
            LingXiComplicationView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("灵息·天山雪莲")
        .description("点击打开灵物详情")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular,
                            .accessoryCorner, .accessoryInline])
    }
}

// MARK: - 视图路由

struct LingXiComplicationView: View {
    @Environment(\.widgetFamily) var family
    let entry: LingXiEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:    CircularView(entry: entry)
            case .accessoryRectangular: RectangularView(entry: entry)
            case .accessoryCorner:      CornerView(entry: entry)
            case .accessoryInline:      InlineView(entry: entry)
            default:                    CircularView(entry: entry)
            }
        }
        .widgetURL(entry.deepLink)
    }
}

// MARK: - 灵力色系（仙气调色盘）

private enum LingQiPalette {
    static let moonWhite   = Color(red: 0.88, green: 0.97, blue: 0.98) // 太阴月白 #E0F7FA
    static let jadeGlow    = Color(red: 0.30, green: 0.71, blue: 0.67) // 清心翡翠 #4DB6AC
    static let lotusPurple = Color(red: 0.70, green: 0.62, blue: 0.86) // 紫气东来 #B39DDB
}

// MARK: - 公共：从 entry 提取灵物图标 & 品级色

private extension LingXiEntry {
    var itemSymbol: String { selectedItem?.sfSymbol ?? "sparkle" }
    var itemName: String   { selectedItem?.name ?? "灵息" }
    var itemColor: Color {
        guard let item = selectedItem else { return LingQiPalette.jadeGlow }
        return gradeColor(for: item.gradeRank)
    }
}

// MARK: - ========== Circular（圆形）==========

struct CircularView: View {
    let entry: LingXiEntry

    var body: some View {
        ZStack {
            // 紫气底晕 — 极淡藕荷紫光晕
            Circle()
                .fill(LingQiPalette.lotusPurple.opacity(0.06))

            // 底环 — 月白色微光
            Circle()
                .stroke(LingQiPalette.moonWhite.opacity(0.10), lineWidth: 5)

            // 进度环 — 渐变 + 双层阴影("真气外溢")
            Circle()
                .trim(from: 0, to: entry.progress)
                .stroke(
                    AngularGradient(
                        colors: [entry.itemColor.opacity(0.2), entry.itemColor, entry.itemColor.opacity(0.8)],
                        center: .center, startAngle: .degrees(0), endAngle: .degrees(360 * entry.progress)
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: entry.itemColor.opacity(0.6), radius: 4, x: 0, y: 0)
                .shadow(color: entry.itemColor.opacity(0.3), radius: 8, x: 0, y: 0)

            // 图标 + 名称
            VStack(spacing: 2) {
                Image(systemName: entry.itemSymbol)
                    .font(.system(size: 20, weight: .light, design: .serif))
                    .foregroundStyle(entry.itemColor)
                    .shadow(color: entry.itemColor.opacity(0.7), radius: 5, x: 0, y: 0)
                    .shadow(color: LingQiPalette.lotusPurple.opacity(0.3), radius: 8, x: 0, y: 0)
                Text(entry.itemName)
                    .font(.system(size: 8, design: .serif))
                    .foregroundStyle(LingQiPalette.moonWhite.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .widgetAccentable()
    }
}

// MARK: - ========== Rectangular（矩形） ==========

struct RectangularView: View {
    let entry: LingXiEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // 标题行 — 衬线体 + 灵物图标
            HStack(spacing: 6) {
                Image(systemName: entry.itemSymbol)
                    .font(.system(size: 14, weight: .light, design: .serif))
                    .foregroundStyle(entry.itemColor)
                    .shadow(color: entry.itemColor.opacity(0.6), radius: 3, x: 0, y: 0)
                    .shadow(color: LingQiPalette.lotusPurple.opacity(0.2), radius: 6, x: 0, y: 0)
                Text("\(entry.realmName) · \(entry.complicationLabel)")
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundStyle(LingQiPalette.moonWhite)
                    .tracking(1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            // 聚灵阵（进度条）— 渐变 + 双层真气外溢
            HStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(LingQiPalette.moonWhite.opacity(0.06))
                            .frame(height: 6)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [entry.itemColor.opacity(0.3), entry.itemColor, entry.itemColor.opacity(0.85)],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geo.size.width * entry.progress), height: 6)
                            .shadow(color: entry.itemColor.opacity(0.5), radius: 3, x: 0, y: 0)
                            .shadow(color: entry.itemColor.opacity(0.25), radius: 6, x: 0, y: 0)
                    }
                }
                .frame(height: 6)

                Text("灵气 \(entry.percentText)")
                    .font(.system(size: 10, design: .serif).monospacedDigit())
                    .foregroundStyle(LingQiPalette.moonWhite.opacity(0.6))
                    .fixedSize()
            }
        }
        .widgetAccentable()
    }
}

// MARK: - ========== Corner（角落） ==========

struct CornerView: View {
    let entry: LingXiEntry

    var body: some View {
        Image(systemName: entry.itemSymbol)
            .font(.system(size: 16, weight: .light, design: .serif))
            .foregroundStyle(entry.itemColor)
            .shadow(color: entry.itemColor.opacity(0.5), radius: 4, x: 0, y: 0)
            .shadow(color: LingQiPalette.lotusPurple.opacity(0.2), radius: 6, x: 0, y: 0)
            .widgetLabel {
                Gauge(value: entry.progress) {
                    Text(entry.itemName)
                        .font(.system(size: 10, design: .serif))
                }
                .gaugeStyle(.accessoryLinearCapacity)
                .tint(entry.itemColor)
            }
            .widgetAccentable()
    }
}

// MARK: - ========== Inline（内联） ==========

struct InlineView: View {
    let entry: LingXiEntry

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: entry.itemSymbol)
                .font(.system(size: 10, design: .serif))
            Text("\(entry.realmName) · \(entry.itemName)")
                .tracking(1)
        }
        .font(.system(size: 12, design: .serif))
    }
}

// MARK: - 品级颜色

private func gradeColor(for rank: Int) -> Color {
    switch rank {
    case 1: return Color(hex: "#7B9DB8")   // 下品 — 寒潭青灰
    case 2: return Color(hex: "#4DB6AC")   // 中品 — 清心翡翠
    case 3: return Color(hex: "#B39DDB")   // 上品 — 紫气东来
    case 4: return Color(hex: "#D4AF61")   // 仙品 — 琉璃金
    case 5: return Color(hex: "#EF7B7B")   // 神品 — 丹火赤焰
    default: return Color(hex: "#4DB6AC")  // 默认翡翠色
    }
}

// MARK: - Hex Color

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(red: Double((int >> 16) & 0xFF) / 255,
                  green: Double((int >> 8) & 0xFF) / 255,
                  blue: Double(int & 0xFF) / 255)
    }
}

// MARK: - Widget 本地 Key 常量

private enum ComplicationKeys {
    static let appGroupID        = "group.com.yourteam.lingxi"
    static let currentRealmLevel = "lx_realm_level"
    static let currentRealmName  = "lx_realm_name"
    static let currentCultivation = "lx_cultivation"
    static let nextRealmThreshold = "lx_next_threshold"
    static let lotusState        = "lx_lotus_state"
    static let heartRate         = "lx_heart_rate"
}
