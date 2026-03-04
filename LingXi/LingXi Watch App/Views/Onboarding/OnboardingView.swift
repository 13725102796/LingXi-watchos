import SwiftUI
import SwiftData
import WidgetKit

struct OnboardingView: View {

    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var currentPage = 0
    @State private var isRequestingAuth = false
    @State private var authError: String?

    private let copy = StaticDataLoader.shared.copywriting?.onboarding

    var body: some View {
        ZStack {
            LingXiColors.background.ignoresSafeArea()

            TabView(selection: $currentPage) {
                page1.tag(0)
                page2.tag(1)
                page3.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(LingXiAnimations.standard, value: currentPage)
        }
    }

    // MARK: - 第1页：欢迎（匹配原型：莲花 SVG + 欢迎标题）

    private var page1: some View {
        VStack(spacing: 6) {
            Spacer()
            // 与 HomeView 共用莲花组件，展示 calm 态（无心率数字）
            HeartLotusView(state: .calm, heartRate: 0)
                .padding(.bottom, 4)

            Text("欢迎踏入")
                .font(.system(size: 16, weight: .light, design: .serif))
                .tracking(2)
                .foregroundStyle(LingXiColors.textSecondary)

            Text("灵息世界")
                .font(.system(size: 19, weight: .light, design: .serif))
                .tracking(3)
                .foregroundStyle(LingXiColors.textPrimary)

            Spacer()
            nextButton(label: "踏入仙途") { currentPage = 1 }
        }
        .padding(.horizontal, 10)
    }

    // MARK: - 第2页：功能介绍

    private var page2: some View {
        VStack(spacing: 6) {
            Text("三大修炼系统")
                .font(LingXiFonts.pageTitle)
                .foregroundStyle(LingXiColors.gold)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 8) {
                featureRow(icon: "moon.stars.fill", title: "驻颜闭关", desc: "以睡眠养元神")
                featureRow(icon: "heart.fill",      title: "灵台清心", desc: "以平和聚灵力")
                featureRow(icon: "figure.walk",     title: "云游历练", desc: "以运动炼体魄")
            }

            Spacer()
            nextButton(label: "了解灵物") { currentPage = 2 }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - 第3页：授权

    private var page3: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 32))
                .foregroundStyle(LingXiColors.teal)

            Text("授权健康数据")
                .font(LingXiFonts.pageTitle)
                .foregroundStyle(LingXiColors.textPrimary)

            Text("数据仅存于本机，绝不上传")
                .font(LingXiFonts.caption)
                .foregroundStyle(LingXiColors.textSecondary)
                .multilineTextAlignment(.center)

            if let err = authError {
                Text(err)
                    .font(LingXiFonts.caption)
                    .foregroundStyle(LingXiColors.danger)
                    .multilineTextAlignment(.center)
            }

            Spacer()
            nextButton(label: isRequestingAuth ? "授权中…" : "授权并开始") {
                Task { await requestAuth() }
            }
            .disabled(isRequestingAuth)

            // 跳过按钮（降级模式：纯签到养成）
            Button("暂不授权") { completeOnboarding() }
                .font(LingXiFonts.caption)
                .foregroundStyle(LingXiColors.textSecondary)
                .frame(minWidth: 44, minHeight: 44)
        }
        .padding(.horizontal, 8)
    }

    // MARK: - 辅助组件

    private func featureRow(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(LingXiColors.teal)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(LingXiFonts.cardTitle).foregroundStyle(LingXiColors.textPrimary)
                Text(desc).font(LingXiFonts.caption).foregroundStyle(LingXiColors.textSecondary)
            }
        }
    }

    private func nextButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(LingXiFonts.cardTitle)
                .foregroundStyle(LingXiColors.background)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(LingXiColors.gold)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 授权逻辑

    private func requestAuth() async {
        isRequestingAuth = true
        authError = nil
        do {
            try await HealthKitManager.shared.requestAuthorization()
        } catch {
            authError = "授权失败，可在设置中手动开启"
        }
        isRequestingAuth = false
        completeOnboarding()
    }

    private func completeOnboarding() {
        LingXiKeys.hasOnboarded = true
        appState.hasOnboarded = true
        // 初始化默认 UserDefaults 供 Widget 读取
        LingXiKeys.realmLevel = 1
        LingXiKeys.realmName = "凡心初悟"
        LingXiKeys.cultivation = 0
        LingXiKeys.nextThreshold = 100

        // 赠送 3 个初始灵物
        let starterItems = ["qingquan", "songfeng", "chenlu"]  // 清泉、松风、晨露
        for itemId in starterItems {
            let collected = CollectedItem(itemId: itemId, obtainSource: "踏入仙途")
            modelContext.insert(collected)
        }
        try? modelContext.save()

        // 同步到 UserDefaults 供 Widget 选择
        let dtos: [SpiritItemDTO] = starterItems.compactMap { itemId in
            guard let def = StaticDataLoader.shared.item(id: itemId) else { return nil }
            return SpiritItemDTO(
                id: def.id, name: def.name, grade: def.grade,
                gradeRank: def.gradeRank,
                sfSymbol: SpiritItemSymbolMap.sfSymbol(for: def.id),
                obtainedDate: Date()
            )
        }
        LingXiKeys.syncCollectedItems(dtos)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
