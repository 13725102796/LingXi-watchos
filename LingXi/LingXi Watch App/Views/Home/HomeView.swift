import SwiftUI
import SwiftData

struct HomeView: View {

    @Environment(AppState.self) private var appState
    @Query private var profiles: [CultivationProfile]
    @State private var lotusCalmSeconds: Int = 0
    @State private var calmTimer: Timer?

    var body: some View {
        ZStack {
            LingXiColors.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    // 境界标题
                    realmHeader

                    // 莲花心率
                    HeartLotusView(state: appState.lotusState,
                                   heartRate: appState.currentHR)
                        .padding(.vertical, 4)

                    // 莲花状态文字
                    Text(appState.lotusState.label)
                        .font(LingXiFonts.caption)
                        .foregroundStyle(appState.lotusState.color)

                    // 修为进度条
                    cultivationBar

                    // 今日数据摘要
                    todaySummary
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
        }
        .onAppear {
            HealthKitManager.shared.startHeartRateMonitoring { hr, hrv in
                appState.currentHR = hr
                let newState = CultivationEngine.computeLotusState(hr: hr, hrv: hrv)
                appState.lotusState = newState
                LingXiKeys.lotus = newState

                if CultivationEngine.shouldTriggerHeartDemon(currentState: newState) {
                    appState.showHeartDemonPopup = true
                    CultivationEngine.markHeartDemonTriggered()
                }
            }
            startCalmTimer()
        }
        .onDisappear {
            HealthKitManager.shared.stopHeartRateMonitoring()
            calmTimer?.invalidate()
            calmTimer = nil
        }
    }

    // MARK: - 境界标题

    private var realmHeader: some View {
        VStack(spacing: 2) {
            Text(appState.realmName)
                .realmTitleStyle()
            Text("第\(appState.realmLevel)境")
                .font(LingXiFonts.caption)
                .foregroundStyle(LingXiColors.textSecondary)
        }
    }

    // MARK: - 修为进度条

    private var cultivationBar: some View {
        VStack(spacing: 4) {
            HStack {
                Text("修为")
                    .font(LingXiFonts.label)
                    .foregroundStyle(LingXiColors.textSecondary)
                Spacer()
                Text("\(appState.cultivation)")
                    .cultivationValueStyle()
                Text("/ \(appState.nextThreshold)")
                    .font(LingXiFonts.caption)
                    .foregroundStyle(LingXiColors.textSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LingXiColors.border)
                        .frame(height: 6)
                    Capsule()
                        .fill(
                            LinearGradient(colors: [LingXiColors.teal, LingXiColors.gold],
                                          startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: geo.size.width * progressRatio, height: 6)
                        .animation(LingXiAnimations.progressFill, value: progressRatio)
                }
            }
            .frame(height: 6)
        }
    }

    private var progressRatio: CGFloat {
        guard appState.nextThreshold > 0 else { return 1.0 }
        return min(1.0, CGFloat(appState.cultivation) / CGFloat(appState.nextThreshold))
    }

    // MARK: - 今日数据摘要

    private var todaySummary: some View {
        HStack(spacing: 0) {
            summaryItem(icon: "figure.walk", value: "\(appState.todaySteps)", unit: "步")
            Divider().frame(height: 24)
            summaryItem(icon: "flame.fill", value: String(format: "%.0f", appState.todayCalories), unit: "卡")
            Divider().frame(height: 24)
            summaryItem(icon: "clock.fill", value: "\(appState.todayExercise)", unit: "分")
        }
        .padding(.vertical, 6)
        .background(LingXiColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func summaryItem(icon: String, value: String, unit: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(LingXiColors.teal)
            Text(value)
                .font(LingXiFonts.label)
                .foregroundStyle(LingXiColors.textPrimary)
            Text(unit)
                .font(.system(size: 9))
                .foregroundStyle(LingXiColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 灵台清明计时（calm 状态计时修为）

    private func startCalmTimer() {
        calmTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            guard appState.lotusState == .calm else { return }
            lotusCalmSeconds += 60
        }
    }
}
