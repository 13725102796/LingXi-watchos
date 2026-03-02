import SwiftUI
import SwiftData

struct JourneyView: View {

    @Environment(AppState.self) private var appState
    @Query private var profiles: [CultivationProfile]

    private var journeyLevel: JourneyLevel {
        CultivationEngine.evaluateJourney(
            CultivationEngine.ActivityData(
                steps: appState.todaySteps,
                calories: appState.todayCalories,
                exerciseMinutes: appState.todayExercise,
                standHours: appState.todayStand
            ),
            consecutiveDays: LingXiKeys.journeyDays
        )
    }

    var body: some View {
        ZStack {
            LingXiColors.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 10) {
                    // 步数大字
                    stepsHeader

                    // 三环
                    HStack(spacing: 12) {
                        ActivityRingView(
                            calories: appState.todayCalories,
                            exercise: appState.todayExercise,
                            stand: appState.todayStand
                        )

                        VStack(alignment: .leading, spacing: 6) {
                            ringLegend(color: LingXiColors.gold, label: "活动", value: String(format: "%.0f/400", appState.todayCalories))
                            ringLegend(color: LingXiColors.teal, label: "运动", value: "\(appState.todayExercise)/30")
                            ringLegend(color: .cyan, label: "站立", value: "\(appState.todayStand)/12")
                        }
                    }
                    .padding(.horizontal, 4)

                    // 历练状态
                    journeyStatusCard

                    // 连续达标天数
                    consecutiveDaysCard

                    // 解锁仙境预览
                    if let scenery = latestUnlockedScenery {
                        sceneryCard(scenery)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
        }
        .onAppear {
            Task { await refreshActivity() }
        }
    }

    // MARK: - 步数大字

    private var stepsHeader: some View {
        VStack(spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(appState.todaySteps)")
                    .font(LingXiFonts.stepsValue)
                    .foregroundStyle(LingXiColors.textPrimary)
                Text("步")
                    .font(LingXiFonts.caption)
                    .foregroundStyle(LingXiColors.textSecondary)
            }
            Text("云游历练")
                .font(LingXiFonts.label)
                .foregroundStyle(LingXiColors.textSecondary)
        }
    }

    // MARK: - 历练状态卡片

    private var journeyStatusCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(journeyLevel == .none ? "继续加油" : "已完成历练")
                    .font(LingXiFonts.cardTitle)
                    .foregroundStyle(journeyLevel == .none ? LingXiColors.textSecondary : LingXiColors.gold)
                Text(journeyLevelLabel)
                    .font(LingXiFonts.caption)
                    .foregroundStyle(LingXiColors.textSecondary)
            }
            Spacer()
            if journeyLevel > .none {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(LingXiColors.success)
                    .font(.title3)
            }
        }
        .padding(10)
        .background(LingXiColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var journeyLevelLabel: String {
        switch journeyLevel {
        case .none:      return "步行5000步或运动30分钟"
        case .basic:     return "基础历练完成"
        case .full:      return "全力历练完成 +\(journeyLevel.cultivationReward)修为"
        case .legendary: return "传说历练！+\(journeyLevel.cultivationReward)修为"
        }
    }

    // MARK: - 连续达标天数

    private var consecutiveDaysCard: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundStyle(LingXiColors.danger)
            Text("连续达标")
                .font(LingXiFonts.caption)
                .foregroundStyle(LingXiColors.textSecondary)
            Spacer()
            Text("\(LingXiKeys.journeyDays) 天")
                .font(LingXiFonts.cardTitle)
                .foregroundStyle(LingXiColors.gold)
        }
        .padding(10)
        .background(LingXiColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - 仙境卡片

    private func sceneryCard(_ scenery: SceneryDef) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("最新仙境")
                .font(LingXiFonts.label)
                .foregroundStyle(LingXiColors.textSecondary)
            HStack {
                Image(systemName: "mountain.2.fill")
                    .foregroundStyle(LingXiColors.teal)
                Text(scenery.name)
                    .font(LingXiFonts.cardTitle)
                    .foregroundStyle(LingXiColors.textPrimary)
            }
            Text(scenery.description)
                .font(LingXiFonts.caption)
                .foregroundStyle(LingXiColors.textSecondary)
                .lineLimit(2)
        }
        .padding(10)
        .background(LingXiColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func ringLegend(color: Color, label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.system(size: 9)).foregroundStyle(LingXiColors.textSecondary)
            Spacer()
            Text(value).font(.system(size: 9).monospacedDigit()).foregroundStyle(LingXiColors.textPrimary)
        }
    }

    // MARK: - 数据

    private var latestUnlockedScenery: SceneryDef? {
        StaticDataLoader.shared.unlockedSceneries(journeyDays: LingXiKeys.journeyDays).last
    }

    private func refreshActivity() async {
        let data = await HealthKitManager.shared.fetchTodayActivity()
        await MainActor.run {
            appState.todaySteps    = data.steps
            appState.todayCalories = data.calories
            appState.todayExercise = data.exerciseMinutes
            appState.todayStand    = data.standHours
        }
    }
}
