import SwiftUI
import SwiftData

struct CollectionView: View {

    @Query private var collectedItems: [CollectedItem]
    @State private var selectedItem: SpiritItemDef?

    private let allItems = StaticDataLoader.shared.spiritItems

    var body: some View {
        ZStack {
            LingXiColors.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 8) {
                    // 标题
                    HStack {
                        Text("灵物图鉴")
                            .font(LingXiFonts.pageTitle)
                            .foregroundStyle(LingXiColors.gold)
                        Spacer()
                        Text("\(collectedIds.count)/\(allItems.count)")
                            .font(LingXiFonts.caption)
                            .foregroundStyle(LingXiColors.textSecondary)
                    }

                    // 3列网格
                    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(sortedItems) { item in
                            Button {
                                if collectedIds.contains(item.id) {
                                    selectedItem = item
                                }
                            } label: {
                                SpiritItemCard(item: item,
                                               isUnlocked: collectedIds.contains(item.id))
                            }
                            .buttonStyle(.plain)
                            .frame(minWidth: 44, minHeight: 44)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
        }
        .sheet(item: $selectedItem) { item in
            SpiritItemDetailSheet(item: item,
                                   obtainedDate: obtainedDate(for: item.id))
        }
    }

    private var collectedIds: Set<String> {
        Set(collectedItems.map { $0.itemId })
    }

    // 已获得的排前，按品级降序；未获得的按品级降序排在后
    private var sortedItems: [SpiritItemDef] {
        let collected = allItems.filter { collectedIds.contains($0.id) }
                                .sorted { $0.gradeRank > $1.gradeRank }
        let locked = allItems.filter { !collectedIds.contains($0.id) }
                             .sorted { $0.gradeRank > $1.gradeRank }
        return collected + locked
    }

    private func obtainedDate(for itemId: String) -> Date? {
        collectedItems.first { $0.itemId == itemId }?.obtainedDate
    }
}

// MARK: - 灵物详情 Sheet

struct SpiritItemDetailSheet: View {

    let item: SpiritItemDef
    let obtainedDate: Date?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LingXiColors.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 8) {
                    // 灵物图片
                    Group {
                        if let uiImage = UIImage(named: item.iconName) {
                            Image(uiImage: uiImage).resizable().scaledToFit()
                        } else {
                            Image(systemName: "star.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(LingXiColors.gradeColor(for: item.gradeRank))
                        }
                    }
                    .frame(width: 60, height: 60)
                    .shadow(color: LingXiColors.gradeColor(for: item.gradeRank).opacity(0.8), radius: 8)

                    Text(item.name)
                        .realmTitleStyle()

                    Text(item.grade)
                        .gradeLabelStyle(grade: item.grade)

                    Text(item.description)
                        .font(LingXiFonts.caption)
                        .foregroundStyle(LingXiColors.textSecondary)
                        .multilineTextAlignment(.center)

                    if let date = obtainedDate {
                        Text("获得于 \(date.formatted(.dateTime.month().day()))")
                            .font(LingXiFonts.caption)
                            .foregroundStyle(LingXiColors.textDisabled)
                    }

                    Text("来源：\(item.source)")
                        .font(LingXiFonts.caption)
                        .foregroundStyle(LingXiColors.textDisabled)
                }
                .padding()
            }
        }
    }
}
