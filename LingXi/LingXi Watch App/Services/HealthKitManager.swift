import HealthKit
import Observation

// MARK: - HealthKit 数据结构

struct SleepData {
    let totalHours: Double
    let deepSleepPercent: Double
}

// MARK: - HealthKitManager（单例，@Observable）

@Observable final class HealthKitManager {

    static let shared = HealthKitManager()
    private let store = HKHealthStore()
    private var heartRateQuery: HKAnchoredObjectQuery?

    // HealthKit 授权状态
    private(set) var isAuthorized: Bool = false
    private(set) var authError: Error?

    // 7 种需要读取的数据类型
    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        let ids: [HKQuantityTypeIdentifier] = [
            .heartRate,
            .heartRateVariabilitySDNN,
            .stepCount,
            .activeEnergyBurned,
            .appleExerciseTime
        ]
        ids.compactMap { HKObjectType.quantityType(forIdentifier: $0) }
           .forEach { types.insert($0) }
        // appleStandHour 是 CategoryType，单独添加
        if let standType = HKObjectType.categoryType(forIdentifier: .appleStandHour) {
            types.insert(standType)
        }
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepType)
        }
        return types
    }()

    private init() {}

    // MARK: - 授权申请（Onboarding 阶段调用一次）

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try await store.requestAuthorization(toShare: [], read: readTypes)
        await MainActor.run { isAuthorized = true }
    }

    // MARK: - 前台实时心率监听（HomeView 激活时开启，离开时停止）

    func startHeartRateMonitoring(handler: @escaping @Sendable (Double, Double) -> Void) {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }

        let anchor = HKQueryAnchor(fromValue: 0)
        let query = HKAnchoredObjectQuery(
            type: hrType,
            predicate: nil,
            anchor: anchor,
            limit: HKObjectQueryNoLimit
        ) { _, samples, _, _, _ in
            guard let latest = (samples as? [HKQuantitySample])?.last else { return }
            let hr = latest.quantity.doubleValue(for: .init(from: "count/min"))
            Task { @MainActor in
                handler(hr, 0)  // HRV 异步单独获取
            }
        }

        query.updateHandler = { _, samples, _, _, _ in
            guard let latest = (samples as? [HKQuantitySample])?.last else { return }
            let hr = latest.quantity.doubleValue(for: .init(from: "count/min"))
            Task { @MainActor in
                handler(hr, 0)
            }
        }

        store.execute(query)
        self.heartRateQuery = query
    }

    func stopHeartRateMonitoring() {
        if let q = heartRateQuery {
            store.stop(q)
            heartRateQuery = nil
        }
    }

    // MARK: - 昨晚睡眠数据（晨起结算）

    func fetchLastNightSleep() async -> SleepData? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }

        let calendar = Calendar.current
        let now = Date()
        // 昨晚 22:00 ~ 今天 10:00
        let startOfWindow: Date = {
            var comps = calendar.dateComponents([.year, .month, .day], from: now)
            comps.day! -= 1
            comps.hour = 22
            comps.minute = 0
            return calendar.date(from: comps) ?? now.addingTimeInterval(-43200)
        }()
        let endOfWindow = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now) ?? now

        let predicate = HKQuery.predicateForSamples(withStart: startOfWindow,
                                                     end: endOfWindow,
                                                     options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: [sort]) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample], !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                var asleepSeconds: Double = 0
                var deepSeconds: Double = 0
                for s in samples {
                    let dur = s.endDate.timeIntervalSince(s.startDate)
                    if s.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                       s.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                       s.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                       s.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue {
                        asleepSeconds += dur
                    }
                    if s.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue {
                        deepSeconds += dur
                    }
                }

                let totalHours = asleepSeconds / 3600
                let deepPercent = asleepSeconds > 0 ? deepSeconds / asleepSeconds : 0
                continuation.resume(returning: SleepData(totalHours: totalHours,
                                                          deepSleepPercent: deepPercent))
            }
            store.execute(query)
        }
    }

    // MARK: - 今日运动数据（历练系统）

    func fetchTodayActivity() async -> CultivationEngine.ActivityData {
        async let steps    = fetchTodayQuantity(.stepCount, unit: .count())
        async let calories = fetchTodayQuantity(.activeEnergyBurned, unit: .kilocalorie())
        async let exercise = fetchTodayQuantity(.appleExerciseTime, unit: .minute())
        async let stand    = fetchTodayStandHours()  // appleStandHour 用独立 Category 查询

        let (s, c, e, st) = await (steps, calories, exercise, stand)
        return CultivationEngine.ActivityData(
            steps: Int(s),
            calories: c,
            exerciseMinutes: Int(e),
            standHours: Int(st)
        )
    }

    private func fetchTodayStandHours() async -> Double {
        guard let type = HKObjectType.categoryType(forIdentifier: .appleStandHour) else { return 0 }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate,
                                      limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let stood = (samples as? [HKCategorySample])?
                    .filter { $0.value == HKCategoryValueAppleStandHour.stood.rawValue }
                    .count ?? 0
                continuation.resume(returning: Double(stood))
            }
            store.execute(query)
        }
    }

    private func fetchTodayQuantity(_ id: HKQuantityTypeIdentifier,
                                     unit: HKUnit) async -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: id) else { return 0 }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay,
                                                     end: Date(),
                                                     options: .strictStartDate)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type,
                                           quantitySamplePredicate: predicate,
                                           options: .cumulativeSum) { _, stats, _ in
                let value = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    // MARK: - 后台 HRV 观察（注册 HKObserverQuery，系统推送）

    func registerHRVObserver(handler: @escaping () -> Void) {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        let query = HKObserverQuery(sampleType: hrvType, predicate: nil) { _, completionHandler, error in
            guard error == nil else { completionHandler(); return }
            handler()
            completionHandler()
        }
        store.execute(query)
        store.enableBackgroundDelivery(for: hrvType, frequency: .immediate) { _, _ in }
    }
}
