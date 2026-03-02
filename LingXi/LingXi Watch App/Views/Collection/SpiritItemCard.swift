import SwiftUI

struct SpiritItemCard: View {

    let item: SpiritItemDef
    let isUnlocked: Bool

    var body: some View {
        ZStack {
            // 背景光晕
            RoundedRectangle(cornerRadius: 10)
                .fill(LingXiColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            isUnlocked ? LingXiColors.gradeColor(for: item.gradeRank).opacity(0.5) : .clear,
                            lineWidth: 1
                        )
                )

            if isUnlocked {
                unlockedContent
            } else {
                lockedContent
            }
        }
        .frame(width: 56, height: 68)
    }

    private var unlockedContent: some View {
        VStack(spacing: 3) {
            // 灵物图片（使用 Assets，fallback 到 SF Symbol）
            Group {
                if let uiImage = UIImage(named: item.iconName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "star.fill")
                        .foregroundStyle(LingXiColors.gradeColor(for: item.gradeRank))
                }
            }
            .frame(width: 32, height: 32)
            .shadow(color: LingXiColors.gradeColor(for: item.gradeRank).opacity(0.6), radius: 4)

            Text(item.name)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(LingXiColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(item.grade)
                .font(.system(size: 8))
                .foregroundStyle(LingXiColors.gradeColor(for: item.gradeRank))
        }
        .padding(4)
    }

    private var lockedContent: some View {
        VStack(spacing: 3) {
            Text("?")
                .font(.system(size: 22, weight: .ultraLight))
                .foregroundStyle(LingXiColors.textDisabled)
            Text("未知")
                .font(.system(size: 9))
                .foregroundStyle(LingXiColors.textDisabled)
        }
    }
}
