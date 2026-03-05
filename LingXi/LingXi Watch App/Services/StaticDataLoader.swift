import Foundation

// MARK: - 静态配置数据类型

struct SpiritItemDef: Codable, Identifiable {
    let id: String
    let name: String
    let grade: String
    let gradeRank: Int        // 1下品 2中品 3上品 4仙品 5神品
    let source: String
    let iconName: String
    let description: String
    let weight: Int           // 随机权重，越高越容易获得
}

struct RealmDef: Codable {
    let level: Int
    let name: String
    let stage: String         // "练气期" / "筑基期" 等
    let requiredCultivation: Int
    let unlockText: String
    let complicationLabel: String
}

struct SceneryDef: Codable, Identifiable {
    let id: String
    let name: String
    let unlockDays: Int
    let imageName: String
    let description: String
    let mood: String
}

struct Copywriting: Codable {
    let sleep: SleepCopy
    let heartDemon: HeartDemonCopy
    let journey: JourneyCopy
    let breakthrough: [String]
    let lotus: LotusCopy
    let journeyView: JourneyViewCopy
    let onboarding: OnboardingCopy

    struct SleepCopy: Codable {
        let immortal: [String]
        let superior: [String]
        let medium: [String]
        let poor: [String]
        let noData: [String]

        func lines(for grade: SleepGrade) -> [String] {
            switch grade {
            case .immortal: return immortal
            case .superior: return superior
            case .medium:   return medium
            case .poor:     return poor
            case .noData:   return noData
            }
        }
    }

    struct HeartDemonCopy: Codable {
        let triggers: [String]
        let calm: [String]
    }

    struct JourneyCopy: Codable {
        let basic: [String]
        let full: [String]
        let legendary: [String]
    }

    struct LotusCopy: Codable {
        let calm: [String]
        let ripple: [String]
        let demon: [String]
    }

    struct JourneyViewCopy: Codable {
        let vase: VaseCopy
        let encounter: EncounterCopy
        let star: StarCopy

        struct VaseCopy: Codable {
            let empty: String
            let partial: String
            let full: String
        }
        struct EncounterCopy: Codable {
            let empty: String
            let achieved: [String]
        }
        struct StarCopy: Codable {
            let none: String
            let partial: String
            let full: String
        }
    }

    struct OnboardingCopy: Codable {
        let page1: OnboardingPage
        let page2: OnboardingPage
        let page3: OnboardingPage

        struct OnboardingPage: Codable {
            let title: String
            let body: String
            var subtitle: String? = nil
        }
    }
}

// MARK: - StaticDataLoader（启动时一次性加载）

@Observable final class StaticDataLoader {

    private(set) var spiritItems: [SpiritItemDef] = []
    private(set) var realms: [RealmDef] = []
    private(set) var sceneries: [SceneryDef] = []
    private(set) var copywriting: Copywriting?

    static let shared = StaticDataLoader()

    private init() {
        loadAll()
    }

    private func loadAll() {
        spiritItems = load("spirit_items")
        realms      = load("realms")
        sceneries   = load("sceneries")
        copywriting = load("copywriting")
    }

    private func load<T: Decodable>(_ name: String) -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            fatalError("❌ 找不到资源文件 \(name).json，请检查 Target Membership。")
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            fatalError("❌ 解析 \(name).json 失败：\(error)")
        }
    }

    // MARK: - 便捷查询

    func realm(level: Int) -> RealmDef? {
        realms.first { $0.level == level }
    }

    func realm(after level: Int) -> RealmDef? {
        realms.first { $0.level == level + 1 }
    }

    func item(id: String) -> SpiritItemDef? {
        spiritItems.first { $0.id == id }
    }

    func scenery(id: String) -> SceneryDef? {
        sceneries.first { $0.id == id }
    }

    /// 按天数获取已解锁仙境
    func unlockedSceneries(journeyDays: Int) -> [SceneryDef] {
        sceneries.filter { $0.unlockDays <= journeyDays }
    }

    /// 按权重随机抽取灵物 ID
    func randomItems(from pool: [SpiritItemDef], count: Int) -> [String] {
        guard !pool.isEmpty else { return [] }
        var result: [String] = []
        let totalWeight = pool.reduce(0) { $0 + $1.weight }
        for _ in 0..<count {
            var rand = Int.random(in: 0..<totalWeight)
            for item in pool {
                rand -= item.weight
                if rand < 0 {
                    result.append(item.id)
                    break
                }
            }
        }
        return result
    }
}
