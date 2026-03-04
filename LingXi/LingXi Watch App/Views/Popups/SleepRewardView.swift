import SwiftUI
import SwiftData
import WidgetKit

struct SleepRewardView: View {

    @Environment(\.modelContext) private var modelContext

    let data: SleepRewardData
    let onDismiss: () -> Void

    @State private var itemsVisible = false
    @State private var textVisible = false

    var body: some View {
        ZStack {
            LingXiColors.background.opacity(0.95).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 10) {
                    // 品级标题
                    VStack(spacing: 4) {
                        Text("晨起闭关")
                            .font(LingXiFonts.label)
                            .foregroundStyle(LingXiColors.textSecondary)

                        Text(data.grade.rawValue)
                            .font(.title2.bold())
                            .foregroundStyle(data.grade.color)
                            .shadow(color: data.grade.color.opacity(0.5), radius: 6)
                    }
                    .opacity(textVisible ? 1 : 0)
                    .animation(LingXiAnimations.popIn.delay(0.1), value: textVisible)

                    // 睡眠时长
                    Text(String(format: "入定 %.1f 小时", data.sleepHours))
                        .font(LingXiFonts.caption)
                        .foregroundStyle(LingXiColors.textSecondary)

                    // 灵气 + 修为奖励
                    HStack(spacing: 16) {
                        rewardBadge(icon: "sparkles", value: "+\(data.spiritEnergyGained)", label: "灵气", color: LingXiColors.gold)
                        rewardBadge(icon: "arrow.up.circle.fill", value: "+\(data.cultivationGained)", label: "修为", color: LingXiColors.teal)
                    }
                    .opacity(textVisible ? 1 : 0)
                    .animation(LingXiAnimations.popIn.delay(0.2), value: textVisible)

                    // 获得灵物
                    if !data.newItemIds.isEmpty {
                        VStack(spacing: 6) {
                            Text("获得灵物")
                                .font(LingXiFonts.label)
                                .foregroundStyle(LingXiColors.textSecondary)

                            HStack(spacing: 8) {
                                ForEach(data.newItemIds.prefix(2), id: \.self) { itemId in
                                    if let item = StaticDataLoader.shared.item(id: itemId) {
                                        SpiritItemCard(item: item, isUnlocked: true)
                                            .scaleEffect(itemsVisible ? 1 : 0.3)
                                            .animation(LingXiAnimations.popIn.delay(0.3), value: itemsVisible)
                                    }
                                }
                            }
                        }
                    }

                    // 古风文案
                    Text(data.copywritingLine)
                        .font(LingXiFonts.caption)
                        .foregroundStyle(LingXiColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .italic()
                        .opacity(textVisible ? 1 : 0)
                        .animation(LingXiAnimations.popIn.delay(0.4), value: textVisible)

                    // 确认按钮
                    Button("领取") {
                        saveCollectedItems()
                        withAnimation(LingXiAnimations.standard) { onDismiss() }
                    }
                    .font(LingXiFonts.cardTitle)
                    .foregroundStyle(LingXiColors.background)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(LingXiColors.gold)
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
        }
        .onAppear {
            textVisible = true
            itemsVisible = true
        }
    }

    private func saveCollectedItems() {
        for itemId in data.newItemIds {
            let collected = CollectedItem(itemId: itemId, obtainSource: "闭关·\(data.grade.rawValue)")
            modelContext.insert(collected)
        }
        try? modelContext.save()
        syncCollectedItemsToWidget()
    }

    private func syncCollectedItemsToWidget() {
        let descriptor = FetchDescriptor<CollectedItem>()
        guard let allItems = try? modelContext.fetch(descriptor) else { return }
        var seen = Set<String>()
        let dtos: [SpiritItemDTO] = allItems.compactMap { collected in
            guard seen.insert(collected.itemId).inserted,
                  let def = StaticDataLoader.shared.item(id: collected.itemId) else { return nil }
            return SpiritItemDTO(
                id: def.id, name: def.name, grade: def.grade,
                gradeRank: def.gradeRank,
                sfSymbol: SpiritItemSymbolMap.sfSymbol(for: def.id),
                obtainedDate: collected.obtainedDate
            )
        }
        LingXiKeys.syncCollectedItems(dtos)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func rewardBadge(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon).foregroundStyle(color).font(.body)
            Text(value).font(LingXiFonts.cultivationValue).foregroundStyle(color)
            Text(label).font(LingXiFonts.caption).foregroundStyle(LingXiColors.textSecondary)
        }
    }
}
