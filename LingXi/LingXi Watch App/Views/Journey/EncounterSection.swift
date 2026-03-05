import SwiftUI

// MARK: - 云游·秘境奇遇（锻炼时长 → 水墨奇遇图鉴）

struct EncounterSection: View {

    let exerciseMinutes: Int
    let journeyDays: Int

    private let goalMinutes: Int = 30

    private var isAchieved: Bool { exerciseMinutes >= goalMinutes }

    private var latestScenery: SceneryDef? {
        StaticDataLoader.shared.unlockedSceneries(journeyDays: journeyDays).last
    }

    /// 基于日期的确定性灵物选取（不随重绘变化）
    private var encounterItemId: String? {
        guard isAchieved else { return nil }
        let items = StaticDataLoader.shared.spiritItems
        guard !items.isEmpty else { return nil }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 1
        return items[dayOfYear % items.count].id
    }

    private var encounterItem: SpiritItemDef? {
        guard let id = encounterItemId else { return nil }
        return StaticDataLoader.shared.item(id: id)
    }

    private var caption: String {
        let copy = StaticDataLoader.shared.copywriting?.journeyView.encounter
        if !isAchieved { return copy?.empty ?? "" }
        let lines = copy?.achieved ?? []
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0
        return lines.isEmpty ? "" : lines[dayOfYear % lines.count]
    }

    var body: some View {
        VStack(spacing: 6) {
            // 标题行
            HStack(spacing: 6) {
                Text("云 游")
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .tracking(4)
                    .foregroundStyle(LingXiColors.teal)
                Spacer()
                Text("\(exerciseMinutes)")
                    .font(.system(size: 15, weight: .bold, design: .serif).monospacedDigit())
                    .foregroundStyle(isAchieved ? LingXiColors.teal : LingXiColors.textSecondary)
                Text("/ \(goalMinutes) 分钟")
                    .font(.system(size: 9))
                    .foregroundStyle(LingXiColors.textSecondary)
            }

            // 主体
            ZStack {
                if isAchieved, let scenery = latestScenery {
                    // 已达标：仙境图 + 灵物
                    achievedContent(scenery: scenery)
                } else {
                    // 未达标：水墨山影
                    emptyContent
                }
            }
            .frame(height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // 文案
            Text(caption)
                .font(.system(size: 10, design: .serif))
                .foregroundStyle(LingXiColors.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding(10)
        .background(LingXiColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 已达标内容

    private func achievedContent(scenery: SceneryDef) -> some View {
        ZStack {
            // 仙境背景图
            Image(scenery.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 72)
                .blendMode(.screen)
                .overlay(
                    LinearGradient(
                        colors: [.clear, LingXiColors.surface.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // 仙境名 + 灵物
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(scenery.name)
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .foregroundStyle(LingXiColors.textPrimary)
                    Text(scenery.description)
                        .font(.system(size: 9))
                        .foregroundStyle(LingXiColors.textSecondary)
                        .lineLimit(1)
                }
                Spacer()

                // 灵物掉落
                if let item = encounterItem {
                    VStack(spacing: 2) {
                        Image(systemName: SpiritItemSymbolMap.sfSymbol(for: item.id))
                            .font(.system(size: 16))
                            .foregroundStyle(LingXiColors.gradeColor(for: item.gradeRank))
                            .shadow(color: LingXiColors.gradeColor(for: item.gradeRank).opacity(0.6), radius: 4)
                        Text(item.name)
                            .font(.system(size: 8))
                            .foregroundStyle(LingXiColors.gradeColor(for: item.gradeRank))
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
    }

    // MARK: - 未达标空态

    private var emptyContent: some View {
        ZStack {
            Image("ink_mountains_empty")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 72)
                .blendMode(.screen)
                .opacity(0.5)

            // 进度提示
            VStack(spacing: 4) {
                Image(systemName: "cloud.fog.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(LingXiColors.textSecondary.opacity(0.5))
                Text("运动 \(exerciseMinutes)/\(goalMinutes) 分钟")
                    .font(.system(size: 10))
                    .foregroundStyle(LingXiColors.textSecondary)
            }
        }
    }
}
