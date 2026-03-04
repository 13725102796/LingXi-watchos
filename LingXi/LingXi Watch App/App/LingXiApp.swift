import SwiftUI
import SwiftData
import WidgetKit

@main
struct LingXiApp: App {

    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentRootView()
                .environment(appState)
                .modelContainer(for: [
                    CultivationProfile.self,
                    CollectedItem.self,
                    DailyRecord.self
                ])
        }
    }
}

// MARK: - 根视图（Onboarding vs 主界面路由）

struct ContentRootView: View {

    @Environment(AppState.self) private var appState
    @Query private var profiles: [CultivationProfile]

    var body: some View {
        if appState.hasOnboarded {
            MainTabView()
                .task { await loadProfile() }
                .task { await checkMorningSettlement() }
                .onOpenURL { url in handleDeepLink(url) }
        } else {
            OnboardingView()
        }
    }

    // MARK: - 深链接路由（表盘组件点击）
    // lingxi://tab/0  → 首页
    // lingxi://tab/1  → 历练
    // lingxi://tab/2  → 灵物图鉴
    // lingxi://item/tianshan_xuelian → 灵物详情

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "lingxi" else { return }

        switch url.host {
        case "tab":
            if let tabStr = url.pathComponents.last, let tab = Int(tabStr) {
                appState.deepLinkTab = tab
            }
        case "item":
            if let itemId = url.pathComponents.last {
                appState.deepLinkTab = 2           // 先跳到灵物图鉴
                appState.deepLinkItemId = itemId   // 再打开详情
            }
        default:
            break
        }
    }

    // MARK: - 加载用户档案

    private func loadProfile() async {
        guard let profile = profiles.first else { return }
        await MainActor.run {
            appState.sync(from: profile)
        }
    }

    // MARK: - 晨起结算（进入前台时检查）

    private func checkMorningSettlement() async {
        let today = LingXiKeys.todayKey()
        guard LingXiKeys.lastSleepDate != today else { return }

        guard let sleepData = await HealthKitManager.shared.fetchLastNightSleep() else {
            LingXiKeys.lastSleepDate = today
            return
        }

        let grade = CultivationEngine.gradeSleep(hours: sleepData.totalHours,
                                                  deepPercent: sleepData.deepSleepPercent)
        let reward = CultivationEngine.computeSleepReward(
            grade: grade,
            allItems: StaticDataLoader.shared.spiritItems
        )

        let copy = StaticDataLoader.shared.copywriting?.sleep.lines(for: grade).randomElement() ?? ""

        await MainActor.run {
            appState.pendingSleepReward = SleepRewardData(
                grade: grade,
                sleepHours: sleepData.totalHours,
                spiritEnergyGained: reward.spiritEnergy,
                cultivationGained: reward.cultivationGain,
                newItemIds: reward.itemIds,
                copywritingLine: copy
            )
            LingXiKeys.lastSleepDate = today
        }
    }
}
