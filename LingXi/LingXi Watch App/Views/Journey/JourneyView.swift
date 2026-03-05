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
                VStack(spacing: 12) {
                    JadeVaseSection(
                        calories: appState.todayCalories,
                        steps: appState.todaySteps
                    )

                    EncounterSection(
                        exerciseMinutes: appState.todayExercise,
                        journeyDays: LingXiKeys.journeyDays
                    )

                    StarChartSection(
                        standHours: appState.todayStand
                    )

                    Spacer().frame(height: 12)
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
            }
        }
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
