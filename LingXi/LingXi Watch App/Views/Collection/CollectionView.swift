import SwiftUI
import SwiftData

struct CollectionView: View {

    @Environment(AppState.self) private var appState
    @Query private var collectedItems: [CollectedItem]
    @State private var selectedItem: SpiritItemDef?

    private let allItems = StaticDataLoader.shared.spiritItems

    // 按品级降序分组 — 匹配原型: 神品→仙品→灵品→凡品→下品
    private let gradeOrder: [(key: String, rank: Int)] = [
        ("神品", 5), ("仙品", 4), ("灵品", 3), ("凡品", 2), ("下品", 1)
    ]

    var body: some View {
        ZStack {
            LingXiColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // 标题行
                    HStack {
                        Text("灵物图鉴")
                            .font(.system(size: 14, weight: .regular, design: .serif))
                            .tracking(2)
                            .foregroundStyle(LingXiColors.textPrimary)
                        Spacer()
                        Text("\(collectedIds.count)/\(allItems.count)")
                            .font(.system(size: 11))
                            .foregroundStyle(LingXiColors.textSecondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                    // 按品级分组展示
                    ForEach(gradeOrder, id: \.key) { gradeInfo in
                        let items = itemsForGrade(gradeInfo.rank)
                        if !items.isEmpty {
                            gradeSection(grade: gradeInfo.key, rank: gradeInfo.rank, items: items)
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedItem) { item in
            SpiritItemDetailSheet(item: item, obtainedDate: obtainedDate(for: item.id))
        }
        .onChange(of: appState.deepLinkItemId) { _, itemId in
            guard let itemId, let item = allItems.first(where: { $0.id == itemId }) else { return }
            selectedItem = item
            appState.deepLinkItemId = nil
        }
    }

    // MARK: - 品级分区

    private func gradeSection(grade: String, rank: Int, items: [SpiritItemDef]) -> some View {
        let gradeColor = LingXiColors.gradeColor(for: grade)
        return VStack(spacing: 4) {
            // 分隔标签 "— 神品 —"
            HStack(spacing: 6) {
                Rectangle().fill(gradeColor.opacity(0.3)).frame(height: 0.5)
                Text("— \(grade) —")
                    .font(.system(size: 10))
                    .tracking(3)
                    .foregroundStyle(gradeColor)
                Rectangle().fill(gradeColor.opacity(0.3)).frame(height: 0.5)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 3)

            // 3列网格
            let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(items) { item in
                    let isUnlocked = collectedIds.contains(item.id)
                    Button {
                        if isUnlocked { selectedItem = item }
                    } label: {
                        SpiritItemCard(item: item, isUnlocked: isUnlocked)
                    }
                    .buttonStyle(.plain)
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 6)
        }
    }

    // MARK: - 数据辅助

    private var collectedIds: Set<String> {
        Set(collectedItems.map { $0.itemId })
    }

    private func itemsForGrade(_ rank: Int) -> [SpiritItemDef] {
        allItems.filter { $0.gradeRank == rank }
                .sorted { $0.name < $1.name }
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
                    Image(systemName: SpiritItemSymbolMap.sfSymbol(for: item.id))
                        .font(.system(size: 40))
                        .foregroundStyle(LingXiColors.gradeColor(for: item.gradeRank))
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
