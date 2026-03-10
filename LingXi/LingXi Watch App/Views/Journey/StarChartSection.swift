import SwiftUI

// MARK: - 周天·本命星图（沉浸式全屏页）
// 站立次数 → 12 生肖萌系图标逐一点亮

struct StarChartSection: View {

    let standHours: Int

    private let totalStars = 12
    @State private var litCount: Int = 0
    @State private var breathing = false

    // 生肖图片资源名（子→亥顺序）
    private let zodiacImages = [
        "zodiac_rat",    "zodiac_ox",      "zodiac_tiger",  "zodiac_rabbit",
        "zodiac_dragon", "zodiac_snake",   "zodiac_horse",  "zodiac_goat",
        "zodiac_monkey", "zodiac_rooster", "zodiac_dog",    "zodiac_pig"
    ]

    // 粉彩主色
    private let accentPink = Color(hex: "#F5A9C0")
    private let accentLavender = Color(hex: "#C9A8E8")

    private var effectiveStand: Int { standHours }
    private var isAllLit: Bool { effectiveStand >= totalStars }

    private var caption: String {
        let copy = StaticDataLoader.shared.copywriting?.journeyView.star
        if effectiveStand == 0 { return copy?.none ?? "" }
        if effectiveStand >= totalStars { return copy?.full ?? "" }
        return copy?.partial ?? ""
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Layer 0: 背景
                background(w: w, h: h)
                    .ignoresSafeArea()

                // Layer 1: 渐变遮罩
                gradientOverlays(h: h)
                    .ignoresSafeArea()

                // Layer 2: 浮动粒子
                floatingParticles
                    .ignoresSafeArea()

                // Layer 3: 内容
                VStack(spacing: 0) {
                    // 顶部标题
                    topTitle(w: w)

                    Spacer()

                    // 中心星图
                    zodiacRing(w: w, h: h)

                    Spacer()

                    // 底部文案
                    Text(caption)
                        .font(.system(size: 10, design: .serif))
                        .foregroundStyle(LingXiColors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, w * 0.1)
                        .padding(.bottom, h * 0.04)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            breathing = true
            animateStars()
        }
        .onChange(of: standHours) { animateStars() }
    }

    // MARK: - 背景

    private func background(w: CGFloat, h: CGFloat) -> some View {
        Color.black
            .overlay {
                Image("zhoutian_background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(0.35)
            }
            .clipped()
    }

    // MARK: - 渐变遮罩

    private func gradientOverlays(h: CGFloat) -> some View {
        ZStack {
            VStack {
                LinearGradient(
                    colors: [
                        Color(hex: "#0A0A0F").opacity(0.85),
                        Color(hex: "#0A0A0F").opacity(0.4),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: h * 0.25)
                Spacer()
            }
            VStack {
                Spacer()
                LinearGradient(
                    colors: [
                        .clear,
                        Color(hex: "#0A0A0F").opacity(0.5),
                        Color(hex: "#0A0A0F").opacity(0.92)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: h * 0.30)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - 浮动粒子

    private var floatingParticles: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for i in 0..<8 {
                    let seed = Double(i) * 137.5
                    let x = ((sin(seed) + 1) / 2) * size.width
                    let period = 7.0 + (seed.truncatingRemainder(dividingBy: 4))
                    let y = size.height - (t.truncatingRemainder(dividingBy: period) / period) * (size.height + 40)
                    let alpha = 0.08 + 0.12 * sin(t * 0.6 + seed)
                    let r = 1.0 + sin(seed * 0.3) * 0.5

                    context.opacity = alpha
                    let color: Color = i % 2 == 0 ? .pink.opacity(0.6) : .purple.opacity(0.5)
                    let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                    context.fill(Ellipse().path(in: rect), with: .color(color))
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - 顶部标题

    private func topTitle(w: CGFloat) -> some View {
        VStack(spacing: 2) {
            Text("STAR CHART")
                .font(.system(size: max(6, w * 0.035), weight: .light))
                .tracking(3)
                .foregroundStyle(LingXiColors.textSecondary)

            Text("周 天")
                .font(.system(size: max(13, w * 0.076), weight: .regular, design: .serif))
                .tracking(5)
                .foregroundStyle(accentPink)
        }
    }

    // MARK: - 生肖环形布局

    private func zodiacRing(w: CGFloat, h: CGFloat) -> some View {
        let ringSize = min(w, h * 0.7)
        let iconSize: CGFloat = ringSize * 0.22
        let radius: CGFloat = ringSize * 0.42

        return ZStack {
            // 12 生肖图标环形排列
            ForEach(0..<12, id: \.self) { i in
                let angle = Angle.degrees(Double(i) * 30 - 90) // 从12点位开始
                let x = cos(angle.radians) * radius
                let y = sin(angle.radians) * radius
                let isLit = i < litCount

                zodiacIcon(index: i, isLit: isLit, size: iconSize)
                    .offset(x: x, y: y)
            }

            // 中心图标
            centerIcon(size: ringSize * 0.32)
        }
        .frame(width: ringSize, height: ringSize)
    }

    // MARK: - 生肖图标

    private func zodiacIcon(index: Int, isLit: Bool, size: CGFloat) -> some View {
        Image(zodiacImages[index])
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .opacity(isLit ? 0.95 : 0.15)
            .saturation(isLit ? 1.0 : 0)
            .shadow(
                color: isLit ? accentPink.opacity(0.4) : .clear,
                radius: isLit ? 6 : 0
            )
            .scaleEffect(isLit && breathing ? 1.03 : 1.0)
            .animation(
                isLit ? Animation.easeInOut(duration: 2.5 + Double(index) * 0.15).repeatForever(autoreverses: true) : .default,
                value: breathing
            )
    }

    // MARK: - 中心图标

    private func centerIcon(size: CGFloat) -> some View {
        let imageName = isAllLit ? "zhoutian_center_lotus" : "zhoutian_center_bud"

        return Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .opacity(isAllLit ? 1.0 : 0.5)
            .saturation(isAllLit ? 1.2 : 0.6)
            .shadow(
                color: isAllLit ? accentPink.opacity(0.5) : accentLavender.opacity(0.2),
                radius: isAllLit ? 12 : 4
            )
            .scaleEffect(breathing ? 1.04 : 0.96)
            .animation(
                Animation.easeInOut(duration: 3).repeatForever(autoreverses: true),
                value: breathing
            )
    }

    // MARK: - 逐颗点亮动画

    private func animateStars() {
        litCount = 0
        for i in 0..<min(effectiveStand, totalStars) {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                withAnimation(LingXiAnimations.starLight) {
                    litCount = i + 1
                }
            }
        }
    }
}
