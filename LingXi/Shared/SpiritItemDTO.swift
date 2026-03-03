import Foundation

/// 灵物轻量 DTO，用于 App ↔ Widget 跨进程传输（经 UserDefaults JSON 序列化）
struct SpiritItemDTO: Codable, Identifiable, Hashable {
    let id: String          // "tianshan_xuelian"
    let name: String        // "天山雪莲"
    let grade: String       // "仙品"
    let gradeRank: Int      // 1~5
    let sfSymbol: String    // SF Symbol 名称
    let obtainedDate: Date
}
