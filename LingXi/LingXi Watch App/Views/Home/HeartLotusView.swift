import SwiftUI

// MARK: - 莲花动态组件（三态：calm / ripple / demon）

struct HeartLotusView: View {

    let state: LotusState
    let heartRate: Double

    @State private var scale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // 光晕层
            Circle()
                .fill(state.color.opacity(glowOpacity))
                .frame(width: 80, height: 80)
                .scaleEffect(scale * 1.4)
                .animation(state.animation, value: scale)

            // 莲花主体
            ZStack {
                // 外层花瓣（6片）
                ForEach(0..<6, id: \.self) { i in
                    Capsule()
                        .fill(state.color.opacity(0.6))
                        .frame(width: 14, height: 28)
                        .offset(y: -22)
                        .rotationEffect(.degrees(Double(i) * 60 + rotation))
                }

                // 内层花瓣（6片）
                ForEach(0..<6, id: \.self) { i in
                    Capsule()
                        .fill(state.color.opacity(0.85))
                        .frame(width: 10, height: 20)
                        .offset(y: -16)
                        .rotationEffect(.degrees(Double(i) * 60 + 30 + rotation))
                }

                // 花心 — 心率数值
                Circle()
                    .fill(LingXiColors.surface)
                    .frame(width: 36, height: 36)

                VStack(spacing: 0) {
                    if heartRate > 0 {
                        Text("\(Int(heartRate))")
                            .font(.system(size: 14, weight: .bold).monospacedDigit())
                            .foregroundStyle(state.color)
                        Text("bpm")
                            .font(.system(size: 8))
                            .foregroundStyle(LingXiColors.textSecondary)
                    } else {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(state.color)
                    }
                }
            }
            .frame(width: 80, height: 80)
            .scaleEffect(scale)
        }
        .onAppear { startAnimation() }
        .onChange(of: state) { startAnimation() }
    }

    private func startAnimation() {
        let range = state.scaleRange
        withAnimation(state.animation) {
            scale = range.upperBound
        }
        withAnimation(state.animation) {
            glowOpacity = state == .demon ? 0.5 : 0.25
        }
        if state == .demon {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        } else {
            withAnimation(state.animation) {
                rotation = 0
            }
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        HeartLotusView(state: .calm, heartRate: 65)
        HeartLotusView(state: .ripple, heartRate: 88)
        HeartLotusView(state: .demon, heartRate: 110)
    }
    .background(LingXiColors.background)
}
