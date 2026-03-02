import SwiftUI
import WatchKit

struct HeartDemonPopup: View {

    let onDismiss: () -> Void

    @State private var pulseScale: CGFloat = 1.0
    private let triggerLine = StaticDataLoader.shared.copywriting?.heartDemon.triggers.randomElement()
                              ?? "心魔侵扰！速速调息！"

    var body: some View {
        ZStack {
            LingXiColors.demonGradient.ignoresSafeArea()
            LingXiColors.background.opacity(0.85).ignoresSafeArea()

            VStack(spacing: 10) {
                // 脉动朱砂莲
                ZStack {
                    Circle()
                        .fill(LingXiColors.danger.opacity(0.2))
                        .frame(width: 70, height: 70)
                        .scaleEffect(pulseScale)
                        .animation(LingXiAnimations.lotusDemon, value: pulseScale)

                    Image(systemName: "heart.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(LingXiColors.danger)
                        .shadow(color: LingXiColors.danger.opacity(0.8), radius: 8)
                }

                Text("心魔侵扰")
                    .font(LingXiFonts.pageTitle)
                    .foregroundStyle(LingXiColors.danger)

                Text(triggerLine)
                    .font(LingXiFonts.caption)
                    .foregroundStyle(LingXiColors.textSecondary)
                    .multilineTextAlignment(.center)

                // 调息按钮（主要操作）
                Button("立即调息") {
                    WKInterfaceDevice.current().play(.notification)
                    onDismiss()
                }
                .font(LingXiFonts.cardTitle)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(LingXiColors.danger)
                .clipShape(Capsule())

                // 忽略按钮
                Button("稍后") {
                    onDismiss()
                }
                .font(LingXiFonts.caption)
                .foregroundStyle(LingXiColors.textSecondary)
                .frame(minWidth: 44, minHeight: 44)
            }
            .padding(.horizontal, 10)
        }
        .onAppear {
            pulseScale = 1.2
            WKInterfaceDevice.current().play(.notification)
        }
    }
}
