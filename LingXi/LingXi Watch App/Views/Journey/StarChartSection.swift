import SwiftUI

// MARK: - 周天·本命星图（站立次数 → 十二时辰星宿点亮）

struct StarChartSection: View {

    let standHours: Int

    private let totalStars = 12
    @State private var litCount: Int = 0

    private let starNames = [
        "子", "丑", "寅", "卯", "辰", "巳",
        "午", "未", "申", "酉", "戌", "亥"
    ]

    // 月白色
    private let moonWhite = Color(hex: "#E0F7FA")

    private var caption: String {
        let copy = StaticDataLoader.shared.copywriting?.journeyView.star
        if standHours == 0 { return copy?.none ?? "" }
        if standHours >= totalStars { return copy?.full ?? "" }
        return copy?.partial ?? ""
    }

    var body: some View {
        VStack(spacing: 6) {
            // 标题行
            HStack(spacing: 6) {
                Text("周 天")
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .tracking(4)
                    .foregroundStyle(moonWhite)
                Spacer()
                Text("\(standHours)")
                    .font(.system(size: 15, weight: .bold, design: .serif).monospacedDigit())
                    .foregroundStyle(standHours >= totalStars ? moonWhite : LingXiColors.textSecondary)
                Text("/ \(totalStars) 时辰")
                    .font(.system(size: 9))
                    .foregroundStyle(LingXiColors.textSecondary)
            }

            // 星图主体
            ZStack {
                // 底图
                Image("star_chart_bg")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 80)
                    .blendMode(.screen)
                    .opacity(0.3)

                // 星辰阵列 (2行6列蜂巢)
                starGrid
            }
            .frame(height: 80)
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
        .onAppear { animateStars() }
        .onChange(of: standHours) { animateStars() }
    }

    // MARK: - 星辰网格

    private var starGrid: some View {
        VStack(spacing: 6) {
            // 上排 6 颗
            HStack(spacing: 0) {
                ForEach(0..<6, id: \.self) { i in
                    starView(index: i)
                        .frame(maxWidth: .infinity)
                }
            }
            // 下排 6 颗（交错偏移）
            HStack(spacing: 0) {
                ForEach(6..<12, id: \.self) { i in
                    starView(index: i)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private func starView(index: Int) -> some View {
        let isLit = index < litCount
        VStack(spacing: 2) {
            ZStack {
                // 光晕
                if isLit {
                    Circle()
                        .fill(moonWhite.opacity(0.25))
                        .frame(width: 14, height: 14)
                        .blur(radius: 3)
                }
                // 星辰
                Circle()
                    .fill(isLit ? moonWhite : LingXiColors.textDisabled)
                    .frame(width: isLit ? 5 : 3, height: isLit ? 5 : 3)
                    .shadow(color: isLit ? moonWhite.opacity(0.8) : .clear, radius: isLit ? 4 : 0)
            }
            .frame(width: 14, height: 14)

            // 时辰名
            Text(starNames[index])
                .font(.system(size: 7, design: .serif))
                .foregroundStyle(isLit ? moonWhite.opacity(0.8) : LingXiColors.textDisabled)
        }
    }

    // MARK: - 逐颗点亮动画

    private func animateStars() {
        litCount = 0
        for i in 0..<standHours {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                withAnimation(LingXiAnimations.starLight) {
                    litCount = i + 1
                }
            }
        }
    }
}
