import SwiftUI

// MARK: - 主 TabView（垂直页面式，符合 watchOS HIG）

struct MainTabView: View {

    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            LingXiColors.background.ignoresSafeArea()

            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)

                JourneyView()
                    .tag(1)

                CollectionView()
                    .tag(2)
            }
            .tabViewStyle(.verticalPage)
            .background(LingXiColors.background)

            // MARK: 弹窗覆盖层
            popupOverlay
        }
        .onChange(of: appState.deepLinkTab) { _, newTab in
            guard let tab = newTab else { return }
            withAnimation { selectedTab = tab }
            appState.deepLinkTab = nil   // 消费完毕
        }
    }

    @ViewBuilder
    private var popupOverlay: some View {
        if let sleepReward = appState.pendingSleepReward {
            SleepRewardView(data: sleepReward) {
                appState.pendingSleepReward = nil
            }
            .transition(.opacity.combined(with: .scale))
            .zIndex(10)
        }

        if let journeyReward = appState.pendingJourneyReward {
            JourneyRewardPopup(data: journeyReward) {
                appState.pendingJourneyReward = nil
            }
            .transition(.opacity.combined(with: .scale))
            .zIndex(10)
        }

        if let breakthrough = appState.pendingBreakthrough {
            BreakthroughPopup(data: breakthrough) {
                appState.pendingBreakthrough = nil
            }
            .transition(.opacity.combined(with: .scale))
            .zIndex(11)
        }

        if appState.showHeartDemonPopup {
            HeartDemonPopup {
                appState.showHeartDemonPopup = false
            }
            .transition(.opacity.combined(with: .scale))
            .zIndex(12)
        }
    }
}
