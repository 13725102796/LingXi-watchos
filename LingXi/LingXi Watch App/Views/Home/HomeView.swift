import SwiftUI
import SwiftData

struct HomeView: View {

    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            LingXiColors.background.ignoresSafeArea()

            VStack(spacing: 4) {
                // 1. 状态文字（字距拉开，匹配原型 letter-spacing:4px）
                Text(appState.lotusState.spacedLabel)
                    .font(.system(size: 11, weight: .medium))
                    .tracking(3)
                    .foregroundStyle(appState.lotusState.color)
                    .padding(.top, 14)

                // 2. 莲花（含心率）
                HeartLotusView(state: appState.lotusState,
                               heartRate: appState.currentHR)

                // 3. 境界名称（serif 风格，字距拉开）
                Text(appState.realmName)
                    .font(.system(size: 15, weight: .light, design: .serif))
                    .tracking(2)
                    .foregroundStyle(LingXiColors.textPrimary)

                // 4. 修为进度条（细 4px + 下方标签）
                cultivationSection
                    .padding(.horizontal, 24)
                    .padding(.top, 2)

                // 5. 今日心率+HRV（tiny inline，匹配原型 health-data 行）
                healthRow
                    .padding(.top, 4)

                Spacer()
            }
        }
        .onAppear {
            HealthKitManager.shared.startHeartRateMonitoring { hr, hrv in
                appState.currentHR = hr
                appState.currentHRV = hrv
                let newState = CultivationEngine.computeLotusState(hr: hr, hrv: hrv)
                appState.lotusState = newState
                LingXiKeys.lotus = newState

                if CultivationEngine.shouldTriggerHeartDemon(currentState: newState) {
                    appState.showHeartDemonPopup = true
                    CultivationEngine.markHeartDemonTriggered()
                }
            }
        }
        .onDisappear {
            HealthKitManager.shared.stopHeartRateMonitoring()
        }
    }

    // MARK: - 修为进度条（4px 细条）

    private var cultivationSection: some View {
        VStack(spacing: 3) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(hex: "#1A1A1E"))
                        .frame(height: 4)
                    Capsule()
                        .fill(LingXiColors.progressGradient)
                        .frame(width: geo.size.width * progressRatio, height: 4)
                        .animation(LingXiAnimations.progressFill, value: progressRatio)
                }
            }
            .frame(height: 4)

            // 原型: "修为 320 / 600"
            Text("修为 \(appState.cultivation) / \(appState.nextThreshold)")
                .font(.system(size: 10))
                .foregroundStyle(LingXiColors.textSecondary)
                .tracking(1)
        }
    }

    private var progressRatio: CGFloat {
        guard appState.nextThreshold > 0 else { return 1.0 }
        return min(1.0, CGFloat(appState.cultivation) / CGFloat(appState.nextThreshold))
    }

    // MARK: - 心率 + HRV 行（原型 health-data 样式）

    private var healthRow: some View {
        HStack(spacing: 12) {
            // 心率
            HStack(spacing: 3) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(LingXiColors.lotusDemon.opacity(0.7))
                Text(appState.currentHR > 0 ? "\(Int(appState.currentHR))" : "--")
                    .font(.system(size: 11, weight: .light).monospacedDigit())
                    .foregroundStyle(LingXiColors.textPrimary)
            }
            // HRV
            HStack(spacing: 2) {
                Text("HRV")
                    .font(.system(size: 9))
                    .foregroundStyle(LingXiColors.textSecondary)
                Text(appState.currentHRV > 0 ? "\(Int(appState.currentHRV))ms" : "--")
                    .font(.system(size: 11, weight: .light).monospacedDigit())
                    .foregroundStyle(LingXiColors.textSecondary)
            }
        }
    }
}
