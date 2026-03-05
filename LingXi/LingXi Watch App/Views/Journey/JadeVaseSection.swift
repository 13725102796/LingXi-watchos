import SwiftUI

// MARK: - 聚灵·玉净瓶（活动消耗 → 仙露渐满）
// 横向布局：左侧环形进度(内嵌瓶子图) + 右侧百分比/进度条/步数

struct JadeVaseSection: View {

    let calories: Double
    let steps: Int

    private let goalCalories: Double = 400
    @State private var animatedFill: CGFloat = 0
    @State private var breathing: Bool = false

    private var fillRatio: CGFloat {
        min(1.0, CGFloat(calories / goalCalories))
    }
    private var isFull: Bool { fillRatio >= 1.0 }
    private var percent: Int { Int(fillRatio * 100) }

    private var caption: String {
        let copy = StaticDataLoader.shared.copywriting?.journeyView.vase
        if calories < 10 { return copy?.empty ?? "" }
        if isFull { return copy?.full ?? "" }
        return copy?.partial ?? ""
    }

    var body: some View {
        VStack(spacing: 6) {
            // 标题行
            HStack(spacing: 6) {
                Text("聚 灵")
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .tracking(5)
                    .foregroundStyle(LingXiColors.gold)
                Spacer()
                Text(String(format: "%.0f", calories))
                    .font(.system(size: 14, weight: .bold, design: .serif).monospacedDigit())
                    .foregroundStyle(LingXiColors.gold)
                Text("千卡")
                    .font(.system(size: 8))
                    .foregroundStyle(LingXiColors.textSecondary)
            }

            // 主体：环形进度 + 信息
            HStack(spacing: 10) {
                // 左：环形进度（内嵌瓶子图）
                progressRing
                    .frame(width: 76, height: 76)

                // 右：百分比 + 进度条 + 步数
                VStack(alignment: .leading, spacing: 5) {
                    // 大字百分比
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text("\(percent)")
                            .font(.system(size: 24, weight: .ultraLight, design: .serif).monospacedDigit())
                            .foregroundStyle(isFull ? LingXiColors.gold : LingXiColors.textPrimary)
                        Text("%")
                            .font(.system(size: 10))
                            .foregroundStyle(LingXiColors.textSecondary)
                    }

                    // 进度条
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(LingXiColors.gold.opacity(0.1))
                                .frame(height: 3)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [LingXiColors.tealDim, LingXiColors.gold],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * animatedFill, height: 3)
                                .shadow(color: LingXiColors.gold.opacity(0.4), radius: 3)
                        }
                    }
                    .frame(height: 3)

                    // 步数 + 卡路里
                    HStack {
                        HStack(spacing: 2) {
                            Image(systemName: "figure.walk")
                                .font(.system(size: 8))
                                .foregroundStyle(LingXiColors.teal.opacity(0.6))
                            Text("\(steps)")
                                .font(.system(size: 9).monospacedDigit())
                                .foregroundStyle(LingXiColors.textSecondary)
                        }
                        Spacer()
                        Text(isFull ? "圆满" : "\(Int(calories))/400")
                            .font(.system(size: 9).monospacedDigit())
                            .foregroundStyle(isFull ? LingXiColors.gold : LingXiColors.textSecondary)
                    }
                }
            }

            // 文案
            Text(caption)
                .font(.system(size: 9, design: .serif))
                .foregroundStyle(LingXiColors.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding(10)
        .background(LingXiColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            breathing = true
            withAnimation(LingXiAnimations.dewFill) {
                animatedFill = fillRatio
            }
        }
        .onChange(of: calories) {
            withAnimation(LingXiAnimations.dewFill) {
                animatedFill = fillRatio
            }
        }
    }

    // MARK: - 环形进度 + 瓶子

    private var progressRing: some View {
        ZStack {
            // 呼吸光晕
            Circle()
                .fill(
                    RadialGradient(
                        colors: [LingXiColors.gold.opacity(isFull ? 0.12 : 0.06), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 38
                    )
                )
                .scaleEffect(breathing ? 1.1 : 0.9)
                .animation(LingXiAnimations.waterWave, value: breathing)

            // 底环
            Circle()
                .stroke(LingXiColors.gold.opacity(0.08), lineWidth: 5)

            // 进度弧
            Circle()
                .trim(from: 0, to: animatedFill)
                .stroke(
                    AngularGradient(
                        colors: [LingXiColors.tealDim, LingXiColors.teal, LingXiColors.gold],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: LingXiColors.gold.opacity(0.5), radius: 4)
                .animation(LingXiAnimations.dewFill, value: animatedFill)

            // 瓶子图片（小巧居中）
            Image(isFull ? "jade_vase_glow" : "jade_vase")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 36, height: 44)
                .blendMode(.screen)
                .shadow(color: isFull ? LingXiColors.gold.opacity(0.5) : .clear, radius: 6)
        }
    }
}
