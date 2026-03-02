import SwiftUI
import WatchKit
import WidgetKit

struct BreakthroughPopup: View {

    let data: BreakthroughData
    let onDismiss: () -> Void

    @State private var particleVisible = false
    @State private var textVisible = false
    @State private var realmScale: CGFloat = 0.5

    private let particleCount = 12

    var body: some View {
        ZStack {
            LingXiColors.background.ignoresSafeArea()

            // 粒子层
            particleLayer

            // 金色光晕
            Circle()
                .fill(LingXiColors.goldGlow)
                .frame(width: 120, height: 120)
                .opacity(particleVisible ? 1 : 0)
                .animation(LingXiAnimations.particleSpread, value: particleVisible)

            VStack(spacing: 10) {
                Spacer()

                // 境界名（主角）
                VStack(spacing: 4) {
                    Text("境界突破")
                        .font(LingXiFonts.label)
                        .foregroundStyle(LingXiColors.textSecondary)
                        .opacity(textVisible ? 1 : 0)

                    Text(data.newRealmName)
                        .font(.title2.bold())
                        .foregroundStyle(LingXiColors.gold)
                        .shadow(color: LingXiColors.gold.opacity(0.8), radius: 10)
                        .scaleEffect(realmScale)
                        .animation(LingXiAnimations.popIn.delay(0.2), value: realmScale)

                    Text(data.newRealmStage)
                        .font(LingXiFonts.cardTitle)
                        .foregroundStyle(LingXiColors.textSecondary)
                        .opacity(textVisible ? 1 : 0)
                }

                // 解锁文案
                Text(data.unlockText)
                    .font(LingXiFonts.caption)
                    .foregroundStyle(LingXiColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .italic()
                    .opacity(textVisible ? 1 : 0)
                    .animation(LingXiAnimations.popIn.delay(0.4), value: textVisible)

                Spacer()

                Button("飞升！") {
                    onDismiss()
                }
                .font(.headline.bold())
                .foregroundStyle(LingXiColors.background)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    LinearGradient(colors: [LingXiColors.gold, LingXiColors.teal],
                                  startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(Capsule())
                .padding(.horizontal, 10)
                .padding(.bottom, 6)
            }
        }
        .onAppear {
            WKInterfaceDevice.current().play(.success)
            // 刷新表盘组件
            WidgetCenter.shared.reloadTimelines(ofKind: "LingXiComplication")
            withAnimation { particleVisible = true }
            withAnimation(LingXiAnimations.popIn.delay(0.1)) { textVisible = true }
            withAnimation(LingXiAnimations.popIn.delay(0.2)) { realmScale = 1.0 }
        }
    }

    // MARK: - 粒子层

    private var particleLayer: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { i in
                Circle()
                    .fill(i % 2 == 0 ? LingXiColors.gold : LingXiColors.teal)
                    .frame(width: CGFloat.random(in: 3...7),
                           height: CGFloat.random(in: 3...7))
                    .offset(
                        x: particleVisible ? CGFloat.random(in: -70...70) : 0,
                        y: particleVisible ? CGFloat.random(in: -80...80) : 0
                    )
                    .opacity(particleVisible ? Double.random(in: 0.4...0.9) : 0)
                    .animation(
                        LingXiAnimations.particleSpread
                            .delay(Double(i) * 0.05)
                            .repeatCount(1, autoreverses: false),
                        value: particleVisible
                    )
            }
        }
    }
}
