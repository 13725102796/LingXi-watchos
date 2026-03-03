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
    let selectedItem: SpiritItemEntity?  // 用户选择的灵物（nil = 默认莲花）

    var progress: Double {
        guard nextThreshold > 0 else { return 1 }
        return min(1.0, Double(cultivation) / Double(nextThreshold))
    }
    var percentText: String { "\(Int(progress * 100))%" }

    var showDefaultLotus: Bool {
        guard let item = selectedItem else { return true }
        return item.id == "__default_lotus__"
    }
}

// MARK: - AppIntent Timeline Provider

struct LingXiConfigProvider: AppIntentTimelineProvider {
    typealias Entry = LingXiEntry
    typealias Intent = SelectSpiritItemIntent

    func placeholder(in context: Context) -> LingXiEntry {
        Self.demoEntry
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
        var lotus = SelectSpiritItemIntent()
        lotus.spiritItem = .defaultLotus

        var xuelian = SelectSpiritItemIntent()
        xuelian.spiritItem = SpiritItemEntity.allItems.first { $0.id == "tianshan_xuelian" }

        var fenghuang = SelectSpiritItemIntent()
        fenghuang.spiritItem = SpiritItemEntity.allItems.first { $0.id == "fenghuangyu" }

        return [
            .init(intent: lotus, description: "心莲"),
            .init(intent: xuelian, description: "天山雪莲"),
            .init(intent: fenghuang, description: "凤凰羽"),
        ]
    }

    static let demoEntry = LingXiEntry(
        date: Date(), realmName: "清心境", cultivation: 72,
        nextThreshold: 100, lotusState: "calm",
        complicationLabel: "凝神", stateLabel: "灵台清明",
        heartRate: 68, selectedItem: nil
    )

    private func loadEntry(configuration: SelectSpiritItemIntent) -> LingXiEntry {
        let defaults = UserDefaults(suiteName: ComplicationKeys.appGroupID)
        let rawLevel = defaults?.integer(forKey: ComplicationKeys.currentRealmLevel) ?? 0
        if rawLevel == 0 {
            return LingXiEntry(
                date: Date(), realmName: "清心境", cultivation: 72,
                nextThreshold: 100, lotusState: "calm",
                complicationLabel: "凝神", stateLabel: "灵台清明",
                heartRate: 68, selectedItem: configuration.spiritItem
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
            selectedItem: configuration.spiritItem
        )
    }
}

// MARK: - Widget

@main
struct LingXiComplication: Widget {
    let kind = "LingXiComplication"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectSpiritItemIntent.self,
            provider: LingXiConfigProvider()
        ) { entry in
            LingXiComplicationView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("灵息")
        .description("修仙境界与灵物展示")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular,
                            .accessoryCorner, .accessoryInline])
    }
}

// MARK: - 视图路由

struct LingXiComplicationView: View {
    @Environment(\.widgetFamily) var family
    let entry: LingXiEntry

    var body: some View {
        switch family {
        case .accessoryCircular:    CircularView(entry: entry)
        case .accessoryRectangular: RectangularView(entry: entry)
        case .accessoryCorner:      CornerView(entry: entry)
        case .accessoryInline:      InlineView(entry: entry)
        default:                    CircularView(entry: entry)
        }
    }
}

// MARK: - ========== Circular（圆形）==========

struct CircularView: View {
    let entry: LingXiEntry

    private var base: Color {
        switch entry.lotusState {
        case "demon":  return Color(hex: "#D4605A")
        case "ripple": return Color(hex: "#E0B4C8")
        default:       return Color(hex: "#A8D8D8")
        }
    }
    private var light: Color {
        entry.lotusState == "demon" ? Color(hex: "#D4605A") : Color(hex: "#D6ECF0")
    }

    var body: some View {
        ZStack {
            if entry.showDefaultLotus {
                // 默认莲花
                lotusBody

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [light.opacity(0.7), base.opacity(0.05)],
                            center: .center, startRadius: 0, endRadius: 5
                        )
                    )
                    .frame(width: 8, height: 8)
            } else if let item = entry.selectedItem {
                // 灵物图标
                spiritItemBody(item: item)
            }

            // 底部心率
            VStack {
                Spacer()
                HStack(spacing: 1) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(Color(hex: "#D4605A"))
                    Text("\(entry.heartRate)")
                        .font(.system(size: 9, weight: .medium).monospacedDigit())
                }
            }
            .padding(.bottom, 1)
        }
        .widgetAccentable()
    }

    private func spiritItemBody(item: SpiritItemEntity) -> some View {
        VStack(spacing: 1) {
            Image(systemName: item.sfSymbol)
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(gradeColor(for: item.gradeRank))
                .shadow(color: gradeColor(for: item.gradeRank).opacity(0.6), radius: 4)
            Text(item.name)
                .font(.system(size: 8))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .offset(y: -3)
    }

    private var lotusBody: some View {
        let petals: [(a: Double, o: Double, rx: CGFloat, ry: CGFloat)] = [
            (90,  0.45, 6, 15), (-90, 0.45, 6, 15),
            (60,  0.60, 6, 14), (-60, 0.60, 6, 14),
            (30,  0.80, 6, 14), (-30, 0.80, 6, 14),
            (0,   0.90, 5.5, 13)
        ]
        return ZStack {
            ForEach(0..<petals.count, id: \.self) { i in
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                light.opacity(0.85 * petals[i].o),
                                base.opacity(0.5 * petals[i].o),
                                base.opacity(0.15 * petals[i].o)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: petals[i].rx * 2, height: petals[i].ry * 2)
                    .offset(y: -6)
                    .rotationEffect(.degrees(petals[i].a))
            }
            Ellipse()
                .fill(light.opacity(0.1))
                .frame(width: 8, height: 5)
                .offset(y: -10)
        }
        .offset(y: -3)
    }
}

// MARK: - ========== Rectangular（矩形） ==========

struct RectangularView: View {
    let entry: LingXiEntry

    private var lotusColor: Color {
        switch entry.lotusState {
        case "demon":  return Color(hex: "#D4605A")
        case "ripple": return Color(hex: "#E0B4C8")
        default:       return Color(hex: "#A8D8D8")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                if entry.showDefaultLotus {
                    MiniLotus3(color: lotusColor)
                        .frame(width: 12, height: 12)
                } else if let item = entry.selectedItem {
                    Image(systemName: item.sfSymbol)
                        .font(.system(size: 12))
                        .foregroundStyle(gradeColor(for: item.gradeRank))
                }
                Text("\(entry.realmName) · \(entry.complicationLabel)")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            HStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.1)).frame(height: 3)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#E0B4C8"), Color(hex: "#A8D8D8")],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geo.size.width * entry.progress), height: 3)
                    }
                }
                .frame(height: 3)

                Text("灵气 \(entry.percentText)")
                    .font(.system(size: 10).monospacedDigit())
                    .foregroundStyle(Color(hex: "#8A9B9B"))
                    .fixedSize()
            }
        }
        .widgetAccentable()
    }
}

struct MiniLotus3: View {
    let color: Color
    var body: some View {
        ZStack {
            Ellipse().fill(color.opacity(0.5)).frame(width: 4, height: 9)
                .offset(y: -2).rotationEffect(.degrees(-35))
            Ellipse().fill(color.opacity(0.5)).frame(width: 4, height: 9)
                .offset(y: -2).rotationEffect(.degrees(35))
            Ellipse().fill(color.opacity(0.7)).frame(width: 3.5, height: 8)
                .offset(y: -2)
            Circle().fill(color.opacity(0.6)).frame(width: 2.5, height: 2.5)
        }
    }
}

// MARK: - ========== Corner（角落） ==========

struct CornerView: View {
    let entry: LingXiEntry
    var body: some View {
        Text(entry.percentText)
            .font(.system(size: 14, weight: .light).monospacedDigit())
            .foregroundStyle(Color(hex: "#F0EDE8"))
            .widgetLabel {
                ProgressView(value: entry.progress)
                    .tint(Color(hex: "#D4A853").opacity(0.7))
            }
            .widgetAccentable()
    }
}

// MARK: - ========== Inline（内联） ==========

struct InlineView: View {
    let entry: LingXiEntry
    var body: some View {
        HStack(spacing: 4) {
            if let item = entry.selectedItem, !entry.showDefaultLotus {
                Image(systemName: item.sfSymbol)
                    .font(.system(size: 9))
                Text("\(entry.realmName)·\(item.name)")
                    .tracking(1)
            } else {
                Image(systemName: "sparkle")
                    .font(.system(size: 9))
                Text("\(entry.realmName)·\(entry.complicationLabel) · \(entry.stateLabel)")
                    .tracking(1)
            }
        }
        .font(.system(size: 12))
    }
}

// MARK: - 品级颜色

private func gradeColor(for rank: Int) -> Color {
    switch rank {
    case 1: return Color(hex: "#6B8CAE")   // 下品 - 灰蓝
    case 2: return Color(hex: "#4ECDC4")   // 中品 - 青绿
    case 3: return Color(hex: "#9B6FE8")   // 上品 - 紫
    case 4: return Color(hex: "#C8A96E")   // 仙品 - 金
    case 5: return Color(hex: "#FF6B6B")   // 神品 - 赤红
    default: return Color(hex: "#A8D8D8")
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
