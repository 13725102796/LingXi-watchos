import SwiftUI

// MARK: - 聚灵·玉净瓶（沉浸式全屏页）
// 未达标：粒子凝聚 + 背景瓶影
// 满溢：发光瓶子 + 光晕

struct JadeVaseSection: View {

    let calories: Double
    let steps: Int

    private let goalCalories: Double = 400

    @State private var animatedFill: CGFloat = 0
    @State private var breathing = false

    private var fillRatio: CGFloat {
        min(1.0, CGFloat(calories / goalCalories))
    }
    private var isFull: Bool { fillRatio >= 1.0 }
    private var percent: Int { Int(fillRatio * 100) }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Layer 0: 全屏背景（铺满到屏幕边缘）
                immersiveBackground(w: w, h: h)
                    .ignoresSafeArea()

                // Layer 1: 上下渐变遮罩
                gradientOverlays(h: h)
                    .ignoresSafeArea()

                // Layer 2: 背景粒子上升
                backgroundParticles
                    .ignoresSafeArea()

                // Layer 3: 内容
                VStack(spacing: 0) {
                    // 顶部标题
                    topTitle(w: w)

                    // 中央：凝聚效果 或 瓶子（填满中间区域）
                    if isFull {
                        Spacer()
                        fullVaseView(w: w, h: h)
                        Spacer()
                    } else {
                        convergeView(w: w, h: h)
                    }

                    // Badge
                    badgeLabel
                        .padding(.bottom, 8)

                    // 底部统计
                    bottomStats
                        .padding(.horizontal, w * 0.07)
                        .padding(.bottom, h * 0.04)
                }
            }
        }
        .ignoresSafeArea()
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

    // MARK: - 全屏背景

    private func immersiveBackground(w: CGFloat, h: CGFloat) -> some View {
        Color.black
            .overlay {
                Image("jade_vase_glow_v2")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .offset(y: -h * 0.05)
                    .blendMode(.screen)
                    .opacity(isFull ? 0.12 : 0.08)
            }
            .clipped()
    }

    // MARK: - 渐变遮罩

    private func gradientOverlays(h: CGFloat) -> some View {
        ZStack {
            // 上方
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
                .frame(height: h * 0.29)
                Spacer()
            }
            // 下方
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
                .frame(height: h * 0.37)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - 背景粒子上升

    private var backgroundParticles: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for i in 0..<8 {
                    let seed = Double(i) * 137.5
                    let x = ((sin(seed) + 1) / 2) * size.width
                    let period = 6.0 + (seed.truncatingRemainder(dividingBy: 4))
                    let y = size.height - (t.truncatingRemainder(dividingBy: period) / period) * (size.height + 40)
                    let alpha = 0.15 + 0.15 * sin(t * 0.8 + seed)
                    let r = 1.0 + sin(seed * 0.3) * 0.5

                    context.opacity = alpha
                    let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                    context.fill(Ellipse().path(in: rect), with: .color(LingXiColors.gold))
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - 顶部标题

    private func topTitle(w: CGFloat) -> some View {
        VStack(spacing: 2) {
            Text("SPIRIT GATHERING")
                .font(.system(size: max(6, w * 0.035), weight: .light))
                .tracking(3)
                .foregroundStyle(LingXiColors.textSecondary)

            Text("聚 灵")
                .font(.system(size: max(13, w * 0.076), weight: .regular, design: .serif))
                .tracking(5)
                .foregroundStyle(LingXiColors.gold)
        }
    }

    // MARK: - 满溢：发光瓶子

    private func fullVaseView(w: CGFloat, h: CGFloat) -> some View {
        let vaseW = w * 0.35
        let vaseH = vaseW * 1.28
        let auraSize = w * 0.6

        return ZStack {
            // 呼吸光晕
            Circle()
                .fill(
                    RadialGradient(
                        colors: [LingXiColors.gold.opacity(0.2), LingXiColors.gold.opacity(0.05), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: auraSize / 2
                    )
                )
                .frame(width: auraSize, height: auraSize)
                .scaleEffect(breathing ? 1.15 : 0.9)
                .animation(LingXiAnimations.waterWave, value: breathing)

            // 瓶子图片
            ZStack {
                Color.black
                Image("jade_vase_glow_v2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .blendMode(.screen)
            }
            .frame(width: vaseW, height: vaseH)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: LingXiColors.gold.opacity(0.25), radius: 15)
            .offset(y: breathing ? -4 : 0)
            .animation(Animation.easeInOut(duration: 3.5).repeatForever(autoreverses: true), value: breathing)
        }
    }

    // MARK: - 未达标：粒子凝聚效果

    private func convergeView(w: CGFloat, h: CGFloat) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let cx = size.width / 2
                let cy = size.height * 0.8

                // 涟漪环
                let ringRadius = size.width * 0.3
                for ring in 0..<3 {
                    let phase = (t + Double(ring)).truncatingRemainder(dividingBy: 3.0) / 3.0
                    let scale = 0.2 + phase * 1.6
                    let alpha = 0.2 * (1.0 - phase)
                    let r = ringRadius * scale
                    let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
                    context.opacity = alpha
                    context.stroke(
                        Ellipse().path(in: rect),
                        with: .color(LingXiColors.gold),
                        lineWidth: 0.8
                    )
                }

                // 中心露珠
                let dewBaseR = size.width * 0.06
                let dewScale = 0.85 + 0.3 * (0.5 + 0.5 * sin(t * 2.5))
                let dewR = dewBaseR * dewScale
                let dewRect = CGRect(x: cx - dewR, y: cy - dewR, width: dewR * 2, height: dewR * 2)
                context.opacity = 0.6 + 0.4 * (0.5 + 0.5 * sin(t * 2.5))

                // 露珠光晕
                context.fill(
                    Ellipse().path(in: dewRect.insetBy(dx: -8, dy: -8)),
                    with: .color(LingXiColors.gold.opacity(0.15))
                )
                // 露珠本体
                let dewGrad = Gradient(colors: [
                    LingXiColors.gold.opacity(0.9),
                    LingXiColors.gold.opacity(0.3),
                    .clear
                ])
                context.fill(
                    Ellipse().path(in: dewRect),
                    with: .radialGradient(dewGrad, center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: dewR)
                )

                // 汇聚粒子 — 散布范围取屏幕宽度的 0.5
                let particleDist = size.width * 0.5
                for i in 0..<16 {
                    let seed = Double(i) * 137.5
                    let angle = (Double.pi * 2 / 16) * Double(i) + seed * 0.01
                    let dist = particleDist + sin(seed) * (particleDist * 0.3)

                    let dur = 2.5 + (seed.truncatingRemainder(dividingBy: 2))
                    let delay = (seed.truncatingRemainder(dividingBy: 3))
                    let phase = ((t + delay).truncatingRemainder(dividingBy: dur)) / dur

                    let progress = 1.0 - phase
                    let px = cx + cos(angle) * dist * progress
                    let py = cy + sin(angle) * dist * progress

                    let alpha = phase < 0.1 ? phase * 9 : (phase > 0.85 ? (1.0 - phase) * 6.7 : 0.8)
                    let pSize = (2.0 + sin(seed * 0.3) * 1.5) * (0.3 + progress * 0.7)

                    let isGold = i % 4 != 0
                    let color = isGold ? LingXiColors.gold : LingXiColors.teal

                    context.opacity = alpha
                    let glowRect = CGRect(x: px - pSize * 2, y: py - pSize * 2, width: pSize * 4, height: pSize * 4)
                    context.fill(Ellipse().path(in: glowRect), with: .color(color.opacity(0.2)))
                    let pRect = CGRect(x: px - pSize, y: py - pSize, width: pSize * 2, height: pSize * 2)
                    context.fill(Ellipse().path(in: pRect), with: .color(color))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Badge

    private var badgeLabel: some View {
        HStack(spacing: 4) {
            Text("✦")
                .font(.system(size: 8))
                .opacity(0.8)
            Text(isFull ? "仙露已满·圆满" : "仙露凝聚中")
                .font(.system(size: 9, design: .serif))
                .tracking(1)
        }
        .foregroundStyle(LingXiColors.gold)
        .padding(.horizontal, 10)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(LingXiColors.gold.opacity(isFull ? 0.15 : 0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(LingXiColors.gold.opacity(isFull ? 0.25 : 0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - 底部统计

    private var bottomStats: some View {
        VStack(spacing: 6) {
            // 进度条行
            HStack(spacing: 8) {
                Text("灵力")
                    .font(.system(size: 8))
                    .foregroundStyle(LingXiColors.textSecondary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 2)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [LingXiColors.tealDim, LingXiColors.gold],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * animatedFill, height: 2)
                            .shadow(color: isFull ? LingXiColors.gold.opacity(0.3) : .clear, radius: 4)
                    }
                }
                .frame(height: 2)

                Text("\(percent)%")
                    .font(.system(size: 9, design: .serif).monospacedDigit())
                    .foregroundStyle(LingXiColors.gold)
            }

            // 卡路里 + 步数
            HStack {
                HStack(spacing: 2) {
                    Text("🔥")
                        .font(.system(size: 7))
                    Text("\(Int(calories))")
                        .font(.system(size: 8).monospacedDigit())
                        .foregroundStyle(LingXiColors.gold)
                    Text("千卡")
                        .font(.system(size: 7))
                        .foregroundStyle(LingXiColors.textDisabled)
                }
                Spacer()
                HStack(spacing: 2) {
                    Text("👣")
                        .font(.system(size: 7))
                    Text("\(steps)")
                        .font(.system(size: 8).monospacedDigit())
                        .foregroundStyle(LingXiColors.textPrimary)
                    Text("步")
                        .font(.system(size: 7))
                        .foregroundStyle(LingXiColors.textDisabled)
                }
            }
        }
    }
}
