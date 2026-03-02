import SwiftUI

struct JourneyRewardPopup: View {

    let data: JourneyRewardData
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            LingXiColors.background.opacity(0.95).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 10) {
                    // 图标 + 标题
                    VStack(spacing: 4) {
                        Image(systemName: journeyIcon)
                            .font(.system(size: 28))
                            .foregroundStyle(LingXiColors.teal)
                            .scaleEffect(appeared ? 1 : 0.3)
                            .animation(LingXiAnimations.popIn, value: appeared)

                        Text("历练归来")
                            .font(LingXiFonts.pageTitle)
                            .foregroundStyle(LingXiColors.textPrimary)

                        Text(journeyLevelText)
                            .font(LingXiFonts.caption)
                            .foregroundStyle(LingXiColors.teal)
                    }

                    // 步数展示
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text("\(data.steps)")
                            .font(LingXiFonts.stepsValue)
                            .foregroundStyle(LingXiColors.textPrimary)
                        Text("步")
                            .font(LingXiFonts.caption)
                            .foregroundStyle(LingXiColors.textSecondary)
                    }

                    // 奖励
                    HStack(spacing: 16) {
                        rewardBadge(value: "+\(data.cultivationGained)", label: "修为", color: LingXiColors.teal)
                        rewardBadge(value: "+\(data.spiritEnergyGained)", label: "灵气", color: LingXiColors.gold)
                    }
                    .opacity(appeared ? 1 : 0)
                    .animation(LingXiAnimations.popIn.delay(0.2), value: appeared)

                    // 获得灵物
                    if !data.newItemIds.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(data.newItemIds.prefix(2), id: \.self) { itemId in
                                if let item = StaticDataLoader.shared.item(id: itemId) {
                                    SpiritItemCard(item: item, isUnlocked: true)
                                        .scaleEffect(appeared ? 1 : 0.3)
                                        .animation(LingXiAnimations.quickPop.delay(0.3), value: appeared)
                                }
                            }
                        }
                    }

                    // 新仙境解锁
                    if let sceneryId = data.newSceneryId,
                       let scenery = StaticDataLoader.shared.scenery(id: sceneryId) {
                        VStack(spacing: 3) {
                            Text("新仙境解锁")
                                .font(LingXiFonts.label)
                                .foregroundStyle(LingXiColors.textSecondary)
                            Text(scenery.name)
                                .font(LingXiFonts.cardTitle)
                                .foregroundStyle(LingXiColors.gold)
                        }
                        .opacity(appeared ? 1 : 0)
                        .animation(LingXiAnimations.popIn.delay(0.35), value: appeared)
                    }

                    // 文案
                    Text(data.copywritingLine)
                        .font(LingXiFonts.caption)
                        .foregroundStyle(LingXiColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .italic()

                    Button("领取") {
                        withAnimation(LingXiAnimations.standard) { onDismiss() }
                    }
                    .font(LingXiFonts.cardTitle)
                    .foregroundStyle(LingXiColors.background)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(LingXiColors.teal)
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
        }
        .onAppear { appeared = true }
    }

    private var journeyIcon: String {
        switch data.level {
        case .legendary: return "trophy.fill"
        case .full:      return "star.circle.fill"
        default:         return "figure.walk.circle.fill"
        }
    }

    private var journeyLevelText: String {
        switch data.level {
        case .legendary: return "传说历练"
        case .full:      return "全力历练"
        case .basic:     return "基础历练"
        case .none:      return ""
        }
    }

    private func rewardBadge(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(LingXiFonts.cultivationValue).foregroundStyle(color)
            Text(label).font(LingXiFonts.caption).foregroundStyle(LingXiColors.textSecondary)
        }
    }
}
