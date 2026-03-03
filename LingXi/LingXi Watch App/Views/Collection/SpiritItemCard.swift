import SwiftUI

struct SpiritItemCard: View {

    let item: SpiritItemDef
    let isUnlocked: Bool

    var body: some View {
        ZStack {
            // 背景 + 品级光晕边框（对应原型 item-glow-* 样式）
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "#0A0E14").opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            isUnlocked
                                ? LingXiColors.gradeColor(for: item.gradeRank).opacity(0.35)
                                : Color.white.opacity(0.04),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: isUnlocked
                        ? LingXiColors.gradeColor(for: item.gradeRank).opacity(0.15)
                        : .clear,
                    radius: 6
                )

            if isUnlocked {
                unlockedContent
            } else {
                lockedContent
            }
        }
        .frame(width: 54, height: 60)
        .opacity(isUnlocked ? 1.0 : 0.2)
    }

    private var unlockedContent: some View {
        VStack(spacing: 2) {
            // 灵物图标（SF Symbol 映射）
            Image(systemName: SpiritItemSymbolMap.sfSymbol(for: item.id))
                .foregroundStyle(LingXiColors.gradeColor(for: item.gradeRank))
                .font(.system(size: 22))
                .frame(width: 28, height: 28)
                .shadow(color: LingXiColors.gradeColor(for: item.gradeRank).opacity(0.5), radius: 3)

            // 短名称（对应原型 font-size:10px）
            Text(item.name)
                .font(.system(size: 10))
                .foregroundStyle(LingXiColors.gradeColor(for: item.gradeRank))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .tracking(1)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
    }

    private var lockedContent: some View {
        VStack(spacing: 2) {
            Text("?")
                .font(.system(size: 18, weight: .ultraLight))
                .foregroundStyle(LingXiColors.textSecondary)
            Text("???")
                .font(.system(size: 9))
                .foregroundStyle(LingXiColors.textSecondary)
        }
    }
}
