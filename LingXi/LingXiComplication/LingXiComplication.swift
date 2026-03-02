import WidgetKit
import SwiftUI

// MARK: - 表盘数据（从 App Group UserDefaults 读取，带范围校验）
// ⚠️ 安全修复：Widget Extension 禁止使用 UserDefaults.standard，
//   统一使用 UserDefaults(suiteName: LingXiKeys.appGroupID)

struct LingXiEntry: TimelineEntry {
    let date: Date
    let realmLevel: Int      // 1-9（已校验范围）
    let realmName: String
    let cultivation: Int     // ≥ 0（已校验）
    let nextThreshold: Int   // ≥ 1（已校验）
    let lotusState: String   // "calm" / "ripple" / "demon"
    let complicationLabel: String
}

// MARK: - Timeline Provider

struct LingXiProvider: TimelineProvider {

    func placeholder(in context: Context) -> LingXiEntry {
        LingXiEntry(date: Date(),
                    realmLevel: 1,
                    realmName: "凡心初悟",
                    cultivation: 0,
                    nextThreshold: 100,
                    lotusState: "calm",
                    complicationLabel: "凡心")
    }

    func getSnapshot(in context: Context,
                     completion: @escaping (LingXiEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<LingXiEntry>) -> Void) {
        let entry = loadEntry()
        // 安全修复：30分钟刷新，保留后台预算给 Background App Refresh
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }

    // MARK: - 从 App Group UserDefaults 加载（带范围校验）

    private static let fallbackEntry = LingXiEntry(
        date: Date(), realmLevel: 1, realmName: "凡心初悟",
        cultivation: 0, nextThreshold: 100, lotusState: "calm", complicationLabel: "凡心"
    )

    private func loadEntry() -> LingXiEntry {
        guard let defaults = UserDefaults(suiteName: LingXiKeys.appGroupID) else {
            return LingXiProvider.fallbackEntry
        }

        // 范围校验：防止数据注入导致数组越界
        let rawLevel = defaults.integer(forKey: LingXiKeys.currentRealmLevel)
        let level = max(1, min(9, rawLevel == 0 ? 1 : rawLevel))

        let name = defaults.string(forKey: LingXiKeys.currentRealmName) ?? "凡心初悟"
        let cultivation = max(0, defaults.integer(forKey: LingXiKeys.currentCultivation))
        let nextThreshold = max(1, defaults.integer(forKey: LingXiKeys.nextRealmThreshold) == 0
                                    ? 100
                                    : defaults.integer(forKey: LingXiKeys.nextRealmThreshold))
        let lotusRaw = defaults.string(forKey: LingXiKeys.lotusState) ?? "calm"

        // 境界缩写（Complication 空间有限）
        let complicationLabel = complicationLabelForLevel(level)

        return LingXiEntry(date: Date(),
                            realmLevel: level,
                            realmName: name,
                            cultivation: cultivation,
                            nextThreshold: nextThreshold,
                            lotusState: lotusRaw,
                            complicationLabel: complicationLabel)
    }

    private func complicationLabelForLevel(_ level: Int) -> String {
        let labels = ["凡心", "练气", "筑基", "金丹", "元婴", "化神", "炼虚", "合体", "大乘"]
        guard level >= 1 && level <= labels.count else { return "修仙" }
        return labels[level - 1]
    }
}

// MARK: - Widget 定义

@main
struct LingXiComplication: Widget {
    let kind: String = "LingXiComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LingXiProvider()) { entry in
            LingXiComplicationView(entry: entry)
        }
        .configurationDisplayName("灵息")
        .description("显示你的修仙境界与修为进度")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner,
            .accessoryInline
        ])
    }
}

// MARK: - 表盘视图路由

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

// MARK: - Circular（圆形）— 境界缩写 + 进度环

struct CircularView: View {
    let entry: LingXiEntry

    private var progress: Double {
        guard entry.nextThreshold > 0 else { return 1 }
        return min(1.0, Double(entry.cultivation) / Double(entry.nextThreshold))
    }

    var body: some View {
        ZStack {
            // 进度环
            Circle()
                .trim(from: 0, to: progress)
                .stroke(lotusColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text(entry.complicationLabel)
                    .font(.system(size: 11, weight: .bold))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("第\(entry.realmLevel)境")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .widgetAccentable()
    }

    private var lotusColor: Color {
        switch entry.lotusState {
        case "demon":  return Color(hex: "#FF4757")
        case "ripple": return Color(hex: "#F7B731")
        default:       return Color(hex: "#4ECDC4")
        }
    }
}

// MARK: - Rectangular（矩形）— 境界名 + 进度条

struct RectangularView: View {
    let entry: LingXiEntry

    private var progress: Double {
        guard entry.nextThreshold > 0 else { return 1 }
        return min(1.0, Double(entry.cultivation) / Double(entry.nextThreshold))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("灵息")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(lotusEmoji)
                    .font(.system(size: 10))
            }

            Text(entry.realmName)
                .font(.system(size: 14, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            ProgressView(value: progress)
                .tint(Color(hex: "#C8A96E"))

            Text("\(entry.cultivation) / \(entry.nextThreshold) 修为")
                .font(.system(size: 9).monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .widgetAccentable()
    }

    private var lotusEmoji: String {
        switch entry.lotusState {
        case "demon":  return "🔴"
        case "ripple": return "🟡"
        default:       return "🔵"
        }
    }
}

// MARK: - Corner（角落）— 境界缩写

struct CornerView: View {
    let entry: LingXiEntry

    var body: some View {
        Text(entry.complicationLabel)
            .font(.system(size: 14, weight: .bold))
            .widgetLabel {
                Text("第\(entry.realmLevel)境 · \(entry.cultivation)修为")
                    .font(.system(size: 11).monospacedDigit())
            }
            .widgetAccentable()
    }
}

// MARK: - Inline（内联）— 单行文字

struct InlineView: View {
    let entry: LingXiEntry

    var body: some View {
        Text("灵息 · \(entry.realmName) · \(entry.cultivation)修为")
            .font(.system(size: 12).monospacedDigit())
    }
}

// MARK: - Hex Color（Widget Extension 无法引用主 App 的 LingXiColors）

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - LingXiKeys（Widget Extension 侧的常量镜像）
// Widget Extension 是独立 target，不能引用主 App 的 LingXiKeys，需镜像常量

private enum LingXiKeys {
    static let appGroupID           = "group.com.yourteam.lingxi"
    static let currentRealmLevel    = "lx_realm_level"
    static let currentRealmName     = "lx_realm_name"
    static let currentCultivation   = "lx_cultivation"
    static let nextRealmThreshold   = "lx_next_threshold"
    static let lotusState           = "lx_lotus_state"
}
