import SwiftUI

// 灵息修仙美学色彩系统
// 主背景：墨渊 #0A0A0F  金色强调：#C8A96E  青瓷：#4ECDC4
enum LingXiColors {

    // MARK: - 背景层

    /// 主背景 — 墨渊 #0A0A0F
    static let background = Color(hex: "#0A0A0F")
    /// 卡片/面板背景 — 玄夜 #12121A
    static let surface = Color(hex: "#12121A")
    /// 分隔线/边框 — 暗幕 #1E1E2E
    static let border = Color(hex: "#1E1E2E")

    // MARK: - 主题色

    /// 金色强调 — 月华金 #C8A96E
    static let gold = Color(hex: "#C8A96E")
    /// 金色暗淡版（禁用/次要）
    static let goldDim = Color(hex: "#7A6340")
    /// 青瓷强调 #4ECDC4
    static let teal = Color(hex: "#4ECDC4")
    /// 青瓷暗淡版
    static let tealDim = Color(hex: "#2A7A76")

    // MARK: - 文字

    /// 主文字 — 月白 #F0EDE4
    static let textPrimary = Color(hex: "#F0EDE4")
    /// 次要文字 — 烟云灰 #8A8A9A
    static let textSecondary = Color(hex: "#8A8A9A")
    /// 禁用文字
    static let textDisabled = Color(hex: "#4A4A5A")

    // MARK: - 境界品级色

    /// 下品 — 石青
    static let gradeCommon = Color(hex: "#6B8CAE")
    /// 中品 — 翡翠绿
    static let gradeMedium = Color(hex: "#4ECDC4")
    /// 上品 — 皇室紫
    static let gradeRare = Color(hex: "#9B6FE8")
    /// 仙品 — 日光金
    static let gradeEpic = Color(hex: "#C8A96E")
    /// 神品 — 朱砂红
    static let gradeLegendary = Color(hex: "#FF6B6B")

    // MARK: - 莲花系统（色彩与原型 HTML 保持一致）

    /// 莲花平静态 — 青瓷 #A8D8D8（--qingCi）
    static let lotusCalm = Color(hex: "#A8D8D8")
    /// 莲花平静高光（接近白色的浅青）
    static let lotusCalmLight = Color(hex: "#D6ECF0")
    /// 莲花波动态 — 藕荷粉 #E0B4C8（--ouHe）
    static let lotusRipple = Color(hex: "#E0B4C8")
    /// 莲花心魔态 — 朱砂红 #D4605A（--zhuSha）
    static let lotusDemon = Color(hex: "#D4605A")

    // MARK: - 功能色

    /// 成功 / 完成
    static let success = Color(hex: "#2ECC71")
    /// 警告
    static let warning = Color(hex: "#F7B731")
    /// 危险 / 心魔
    static let danger = Color(hex: "#FF4757")

    // MARK: - 渐变

    /// 主背景渐变（从墨渊到玄夜）
    static let backgroundGradient = LinearGradient(
        colors: [Color(hex: "#0A0A0F"), Color(hex: "#0F0F1A")],
        startPoint: .top,
        endPoint: .bottom
    )

    /// 修为进度条渐变（藕荷 → 青瓷，匹配原型）
    static let progressGradient = LinearGradient(
        colors: [Color(hex: "#E0B4C8"), Color(hex: "#A8D8D8")],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// 金色光晕渐变
    static let goldGlow = RadialGradient(
        colors: [Color(hex: "#C8A96E").opacity(0.4), .clear],
        center: .center,
        startRadius: 0,
        endRadius: 60
    )

    /// 心魔危险渐变
    static let demonGradient = RadialGradient(
        colors: [Color(hex: "#FF4757").opacity(0.3), .clear],
        center: .center,
        startRadius: 0,
        endRadius: 80
    )
}

// MARK: - 品级颜色助手

extension LingXiColors {
    static func gradeColor(for rank: Int) -> Color {
        switch rank {
        case 1: return gradeCommon
        case 2: return gradeMedium
        case 3: return gradeRare
        case 4: return gradeEpic
        case 5: return gradeLegendary
        default: return textSecondary
        }
    }

    static func gradeColor(for grade: String) -> Color {
        switch grade {
        case "下品": return gradeCommon
        case "中品": return gradeMedium
        case "上品": return gradeRare
        case "仙品": return gradeEpic
        case "神品": return gradeLegendary
        default: return textSecondary
        }
    }
}

// MARK: - Hex 颜色扩展

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            (r, g, b) = (Double((int >> 16) & 0xFF) / 255,
                         Double((int >> 8) & 0xFF) / 255,
                         Double(int & 0xFF) / 255)
        default:
            (r, g, b) = (1, 1, 1)
        }
        self.init(red: r, green: g, blue: b)
    }
}
