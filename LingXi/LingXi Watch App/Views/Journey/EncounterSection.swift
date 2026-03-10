import SwiftUI

// MARK: - 云游·秘境奇遇（沉浸式全屏页）
// 未达标：水墨山影 + 雾气遮罩
// 达标：仙境全屏 + 仙境名 + 灵物掉落

struct EncounterSection: View {

    let exerciseMinutes: Int
    let journeyDays: Int

    private let goalMinutes: Int = 30

    private var isAchieved: Bool { true } // TODO: 恢复为 exerciseMinutes >= goalMinutes
    private var fillRatio: CGFloat {
        min(1.0, CGFloat(exerciseMinutes) / CGFloat(goalMinutes))
    }
    private var percent: Int { Int(fillRatio * 100) }

    private var latestScenery: SceneryDef? {
        StaticDataLoader.shared.unlockedSceneries(journeyDays: journeyDays).last
    }

    private var encounterItemId: String? {
        guard isAchieved else { return nil }
        let items = StaticDataLoader.shared.spiritItems
        guard !items.isEmpty else { return nil }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 1
        return items[dayOfYear % items.count].id
    }

    private var encounterItem: SpiritItemDef? {
        guard let id = encounterItemId else { return nil }
        return StaticDataLoader.shared.item(id: id)
    }

    @State private var animatedFill: CGFloat = 0
    @State private var breathing = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Layer 0: 全屏背景
                immersiveBackground(w: w, h: h)
                    .ignoresSafeArea()

                // Layer 1: 渐变遮罩
                gradientOverlays(h: h)
                    .ignoresSafeArea()

                // Layer 2: 浮动粒子
                floatingParticles
                    .ignoresSafeArea()

                // Layer 2.5: 未达标雾气遮罩
                if !isAchieved {
                    fogVeil
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }

                // Layer 3: 内容
                VStack(spacing: 0) {
                    // 顶部标题
                    topTitle(w: w)

                    Spacer()

                    // 中央内容
                    if isAchieved, let scenery = latestScenery {
                        achievedCenter(scenery: scenery)
                    } else {
                        fogCenter
                    }

                    Spacer()

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
        .onChange(of: exerciseMinutes) {
            withAnimation(LingXiAnimations.dewFill) {
                animatedFill = min(1.0, CGFloat(exerciseMinutes) / CGFloat(goalMinutes))
            }
        }
    }

    // MARK: - 全屏背景

    private func immersiveBackground(w: CGFloat, h: CGFloat) -> some View {
        Color.black
            .overlay {
                if isAchieved, let scenery = latestScenery {
                    // 达标：仙境图高亮
                    Image(scenery.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .blendMode(.screen)
                        .opacity(0.55)
                } else {
                    // 未达标：水墨山影暗淡模糊
                    Image("ink_mountains_empty")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .blur(radius: 1)
                        .blendMode(.screen)
                        .opacity(0.15)
                }
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
                .frame(height: h * 0.29)
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
                .frame(height: h * 0.37)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - 浮动粒子

    private var floatingParticles: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let color = isAchieved ? LingXiColors.teal : LingXiColors.teal.opacity(0.5)
                for i in 0..<6 {
                    let seed = Double(i) * 137.5
                    let x = ((sin(seed) + 1) / 2) * size.width
                    let period = 6.0 + (seed.truncatingRemainder(dividingBy: 4))
                    let y = size.height - (t.truncatingRemainder(dividingBy: period) / period) * (size.height + 40)
                    let alpha = 0.1 + 0.15 * sin(t * 0.8 + seed)
                    let r = 1.0 + sin(seed * 0.3) * 0.5

                    context.opacity = alpha
                    let rect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                    context.fill(Ellipse().path(in: rect), with: .color(color))
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - 雾气遮罩（未达标）

    private var fogVeil: some View {
        RadialGradient(
            colors: [
                Color(hex: "#0A0A0F").opacity(0.3),
                Color(hex: "#0A0A0F").opacity(0.75)
            ],
            center: .center,
            startRadius: 0,
            endRadius: 160
        )
        .allowsHitTesting(false)
    }

    // MARK: - 顶部标题

    private func topTitle(w: CGFloat) -> some View {
        VStack(spacing: 2) {
            Text("CLOUD JOURNEY")
                .font(.system(size: max(6, w * 0.035), weight: .light))
                .tracking(3)
                .foregroundStyle(LingXiColors.textSecondary)

            Text("云 游")
                .font(.system(size: max(13, w * 0.076), weight: .regular, design: .serif))
                .tracking(5)
                .foregroundStyle(LingXiColors.teal)
        }
    }

    // MARK: - 达标中央内容

    private func achievedCenter(scenery: SceneryDef) -> some View {
        VStack(spacing: 2) {
            Text(scenery.name)
                .font(.system(size: 18, weight: .regular, design: .serif))
                .tracking(4)
                .foregroundStyle(LingXiColors.textPrimary)
                .shadow(color: .black.opacity(0.8), radius: 10)

            Text(scenery.description)
                .font(.system(size: 10, weight: .light))
                .foregroundStyle(LingXiColors.textSecondary)
                .tracking(1)
                .shadow(color: .black.opacity(0.8), radius: 5)
                .padding(.bottom, 10)

            // 灵物掉落 badge
            if let item = encounterItem {
                lootBadge(item: item)
            }
        }
    }

    // MARK: - 灵物 badge

    private func lootBadge(item: SpiritItemDef) -> some View {
        HStack(spacing: 5) {
            Image(systemName: SpiritItemSymbolMap.sfSymbol(for: item.id))
                .font(.system(size: 12))
            Text(item.name)
                .font(.system(size: 10, design: .serif))
                .tracking(1)
        }
        .foregroundStyle(LingXiColors.teal)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(LingXiColors.teal.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(LingXiColors.teal.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: LingXiColors.teal.opacity(0.15), radius: 8)
        .scaleEffect(breathing ? 1.02 : 0.98)
        .animation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true), value: breathing)
    }

    // MARK: - 未达标中央

    private var fogCenter: some View {
        VStack(spacing: 6) {
            Text("☁")
                .font(.system(size: 28))
                .opacity(0.25)
                .scaleEffect(breathing ? 1.05 : 1.0)
                .offset(y: breathing ? -4 : 0)
                .animation(Animation.easeInOut(duration: 4).repeatForever(autoreverses: true), value: breathing)

            Text("云深不知处")
                .font(.system(size: 12, weight: .regular, design: .serif))
                .tracking(3)
                .foregroundStyle(LingXiColors.textSecondary)
                .opacity(0.6)

            Text("待仙子探寻")
                .font(.system(size: 9))
                .foregroundStyle(LingXiColors.textDisabled)
                .tracking(2)
        }
    }

    // MARK: - 底部统计

    private var bottomStats: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Text("历练")
                    .font(.system(size: 10))
                    .foregroundStyle(LingXiColors.textSecondary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 3)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [LingXiColors.tealDim, LingXiColors.teal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * animatedFill, height: 3)
                            .shadow(color: isAchieved ? LingXiColors.teal.opacity(0.3) : .clear, radius: 4)
                    }
                }
                .frame(height: 3)

                Text("\(percent)%")
                    .font(.system(size: 11, design: .serif).monospacedDigit())
                    .foregroundStyle(isAchieved ? LingXiColors.teal : LingXiColors.textSecondary)
            }

            HStack {
                HStack(spacing: 2) {
                    Text("⏱")
                        .font(.system(size: 9))
                    Text("\(exerciseMinutes)")
                        .font(.system(size: 10).monospacedDigit())
                        .foregroundStyle(isAchieved ? LingXiColors.teal : LingXiColors.textSecondary)
                    Text("/ \(goalMinutes) 分钟")
                        .font(.system(size: 9))
                        .foregroundStyle(LingXiColors.textDisabled)
                }
                Spacer()
            }
        }
    }
}
