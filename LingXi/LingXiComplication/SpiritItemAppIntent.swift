import AppIntents
import WidgetKit
import Foundation

// MARK: - 灵物实体（用于 AppIntent 选择器）

struct SpiritItemEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "灵物")
    static var defaultQuery = SpiritItemEntityQuery()

    var id: String
    var name: String
    var grade: String
    var gradeRank: Int
    var sfSymbol: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(grade)",
            image: .init(systemName: sfSymbol)
        )
    }

    /// 默认莲花（未选择灵物时）
    static let defaultLotus = SpiritItemEntity(
        id: "__default_lotus__",
        name: "心莲",
        grade: "",
        gradeRank: 0,
        sfSymbol: "leaf.fill"
    )

    /// 全部灵物（内置，不依赖 App Group）
    static let allItems: [SpiritItemEntity] = [
        // 神品
        .init(id: "hundunlingzhu",    name: "混沌灵珠", grade: "神品", gradeRank: 5, sfSymbol: "circle.hexagongrid.fill"),
        .init(id: "hongmengzhilu",    name: "鸿蒙之露", grade: "神品", gradeRank: 5, sfSymbol: "drop.fill"),
        .init(id: "jiutianxuantie",   name: "九天玄铁", grade: "神品", gradeRank: 5, sfSymbol: "shield.checkered"),
        .init(id: "pantao",           name: "蟠桃",     grade: "神品", gradeRank: 5, sfSymbol: "leaf.fill"),
        .init(id: "taixulingzhi",     name: "太虚灵芝", grade: "神品", gradeRank: 5, sfSymbol: "sparkle"),
        // 仙品
        .init(id: "tianshan_xuelian", name: "天山雪莲", grade: "仙品", gradeRank: 4, sfSymbol: "snowflake"),
        .init(id: "fenghuangyu",      name: "凤凰羽",   grade: "仙品", gradeRank: 4, sfSymbol: "flame.fill"),
        .init(id: "longxianxiang",    name: "龙涎香",   grade: "仙品", gradeRank: 4, sfSymbol: "smoke.fill"),
        .init(id: "qiongjiang",       name: "琼浆",     grade: "仙品", gradeRank: 4, sfSymbol: "wineglass.fill"),
        .init(id: "xingchensuipian",  name: "星辰碎片", grade: "仙品", gradeRank: 4, sfSymbol: "star.fill"),
        // 上品
        .init(id: "qingyunshi",       name: "青云石",   grade: "上品", gradeRank: 3, sfSymbol: "cloud.fill"),
        .init(id: "jinlvsi",          name: "金缕丝",   grade: "上品", gradeRank: 3, sfSymbol: "wand.and.rays"),
        .init(id: "yehua",            name: "夜华",     grade: "上品", gradeRank: 3, sfSymbol: "moon.stars.fill"),
        .init(id: "lingheyu",         name: "灵荷玉",   grade: "上品", gradeRank: 3, sfSymbol: "drop.triangle.fill"),
        // 中品
        .init(id: "baihualu",         name: "百花露",   grade: "中品", gradeRank: 2, sfSymbol: "camera.macro"),
        .init(id: "chenlu",           name: "晨露",     grade: "中品", gradeRank: 2, sfSymbol: "sunrise.fill"),
        .init(id: "yusui",            name: "玉髓",     grade: "中品", gradeRank: 2, sfSymbol: "diamond.fill"),
        .init(id: "bibozhu",          name: "碧波珠",   grade: "中品", gradeRank: 2, sfSymbol: "circle.fill"),
        // 下品
        .init(id: "songfeng",         name: "松风",     grade: "下品", gradeRank: 1, sfSymbol: "wind"),
        .init(id: "qingquan",         name: "清泉",     grade: "下品", gradeRank: 1, sfSymbol: "drop.degreesign.fill"),
    ]
}

// MARK: - 灵物查询

struct SpiritItemEntityQuery: EntityStringQuery {

    func entities(for identifiers: [String]) async throws -> [SpiritItemEntity] {
        let all = Self.allWithDefault
        return all.filter { identifiers.contains($0.id) }
    }

    func entities(matching string: String) async throws -> [SpiritItemEntity] {
        guard !string.isEmpty else { return Self.allWithDefault }
        return Self.allWithDefault.filter { $0.name.localizedCaseInsensitiveContains(string) }
    }

    func suggestedEntities() async throws -> [SpiritItemEntity] {
        Self.allWithDefault
    }

    func defaultResult() async -> SpiritItemEntity? {
        nil  // 返回 nil，让每个 Widget 的 Provider 自行决定默认灵物
    }

    private static var allWithDefault: [SpiritItemEntity] {
        [SpiritItemEntity.defaultLotus] + SpiritItemEntity.allItems
    }
}

// MARK: - 配置意图

struct SelectSpiritItemIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "选择灵物"
    static var description = IntentDescription("选择要在表盘上展示的灵物")

    @Parameter(title: "灵物")
    var spiritItem: SpiritItemEntity?
}
