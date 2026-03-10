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
        TabView {
            // Page 1: 聚灵·玉净瓶
            JadeVaseSection(
                calories: appState.todayCalories,
                steps: appState.todaySteps
            )

            // Page 2: 云游·秘境奇遇
            EncounterSection(
                exerciseMinutes: appState.todayExercise,
                journeyDays: LingXiKeys.journeyDays
            )

            // Page 3: 周天·本命星图
            StarChartSection(
                standHours: appState.todayStand
            )
        }
        .tabViewStyle(.verticalPage)
        .onAppear {
            Task { await refreshActivity() }
        }
    }

    // MARK: - 数据

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
