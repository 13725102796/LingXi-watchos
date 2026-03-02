import SwiftUI

// MARK: - 莲花心率组件
//
// 花瓣形态完全匹配 prototype.html 的 SVG 莲花：
//   7片椭圆花瓣，以 72pt 坐标系为参考：
//     cx=36 cy=26 rx=7 ry=22，以 SVG 中心(36,36)为旋转轴
//   通过 .offset(y: -petalOffset) + .rotationEffect 实现
//   SwiftUI 中 offset 不改变布局 frame，故旋转始终绕 ZStack 中心

struct HeartLotusView: View {

    let state: LotusState
    let heartRate: Double

    @State private var breathScale: CGFloat = 1.0

    // 花瓣角度与透明度（对应 SVG rotate + opacity）
    private let petals: [(angle: Double, opacity: Double)] = [
        (90,  0.45), (-90, 0.45),
        (60,  0.60), (-60, 0.60),
        (30,  0.80), (-30, 0.80),
        (0,   0.90)
    ]

    // SVG 基准 72pt，目标显示 76pt
    private let viewSize: CGFloat = 76
    private var s: CGFloat { viewSize / 72 }

    var body: some View {
        ZStack {
            // 环境光晕（随状态颜色变化）
            Circle()
                .fill(state.color.opacity(0.10))
                .frame(width: viewSize * 1.35, height: viewSize * 1.35)
                .scaleEffect(breathScale)
                .animation(state.animation, value: breathScale)

            // 莲花主体 ZStack（所有子 view 共享中心，旋转均围绕此中心）
            ZStack {
                // 7片椭圆花瓣
                ForEach(petals.indices, id: \.self) { i in
                    Ellipse()
                        .fill(petalGradient(opacity: petals[i].opacity))
                        .frame(width: 7 * s * 2, height: 22 * s * 2)
                        // offset 将椭圆圆心上移到 cy=26 处（距中心 -10）
                        // 但布局 frame 仍在中心，故旋转轴保持在 ZStack 中心
                        .offset(y: -(10 * s))
                        .rotationEffect(.degrees(petals[i].angle))
                }

                // 高光椭圆（prototype cx=36,cy=22, rx=4,ry=12）
                Ellipse()
                    .fill(.white.opacity(0.22))
                    .frame(width: 4 * s * 2, height: 12 * s * 2)
                    .offset(y: -(14 * s))

                // 中心圆（prototype r=6，渐变：白→state色）
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.75),
                                state.color.opacity(0.20)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 6 * s
                        )
                    )
                    .frame(width: 6 * s * 2, height: 6 * s * 2)

                // 心率数字（叠在中心圆上方）
                VStack(spacing: 0) {
                    if heartRate > 0 {
                        Text("\(Int(heartRate))")
                            .font(.system(size: 11, weight: .semibold).monospacedDigit())
                            .foregroundStyle(state.color)
                        Text("bpm")
                            .font(.system(size: 7))
                            .foregroundStyle(LingXiColors.textSecondary)
                    } else {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(state.color.opacity(0.9))
                    }
                }
            }
            .frame(width: viewSize, height: viewSize)
            .scaleEffect(breathScale)
            .animation(state.animation, value: breathScale)
        }
        .frame(width: viewSize, height: viewSize)
        .onAppear { startBreathing() }
        .onChange(of: state) { startBreathing() }
    }

    // MARK: - 花瓣渐变（仿原型 SVG linearGradient）
    private func petalGradient(opacity: Double) -> LinearGradient {
        switch state {
        case .calm:
            return LinearGradient(
                stops: [
                    .init(color: LingXiColors.lotusCalmLight.opacity(opacity * 0.95), location: 0),
                    .init(color: LingXiColors.lotusCalm.opacity(opacity * 0.55), location: 0.6),
                    .init(color: LingXiColors.lotusCalm.opacity(opacity * 0.15), location: 1.0)
                ],
                startPoint: .top, endPoint: .bottom
            )
        case .ripple:
            return LinearGradient(
                stops: [
                    .init(color: LingXiColors.lotusCalmLight.opacity(opacity * 0.9), location: 0),
                    .init(color: LingXiColors.lotusRipple.opacity(opacity * 0.55), location: 0.6),
                    .init(color: LingXiColors.lotusRipple.opacity(opacity * 0.15), location: 1.0)
                ],
                startPoint: .top, endPoint: .bottom
            )
        case .demon:
            return LinearGradient(
                stops: [
                    .init(color: LingXiColors.lotusDemon.opacity(opacity * 0.75), location: 0),
                    .init(color: LingXiColors.lotusDemon.opacity(opacity * 0.35), location: 0.6),
                    .init(color: Color(hex: "#0A0E14").opacity(opacity * 0.40), location: 1.0)
                ],
                startPoint: .top, endPoint: .bottom
            )
        }
    }

    private func startBreathing() {
        breathScale = state.scaleRange.lowerBound
        withAnimation(state.animation) {
            breathScale = state.scaleRange.upperBound
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        HeartLotusView(state: .calm,   heartRate: 65)
        HeartLotusView(state: .ripple, heartRate: 88)
        HeartLotusView(state: .demon,  heartRate: 110)
    }
    .padding()
    .background(LingXiColors.background)
}
