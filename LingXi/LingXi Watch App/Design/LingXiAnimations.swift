import SwiftUI

// 灵息动画预设
// 约束：watchOS 动画时长 ≤ 0.5s；呼吸动画除外（用于莲花持续状态）
enum LingXiAnimations {

    // MARK: - 莲花呼吸动画（持续循环）

    /// Calm 状态：舒缓呼吸，3秒一循环
    static let lotusCalm = Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)

    /// Ripple 状态：轻微涌动，1.5秒一循环
    static let lotusRipple = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)

    /// Demon 状态：急促跳动，0.8秒一循环
    static let lotusDemon = Animation.easeIn(duration: 0.8).repeatForever(autoreverses: true)

    // MARK: - 弹出动画

    /// 标准弹入（Sheet / 弹窗出现）
    static let popIn = Animation.spring(response: 0.4, dampingFraction: 0.7)

    /// 快速弹入（小元素出现）
    static let quickPop = Animation.spring(response: 0.25, dampingFraction: 0.8)

    // MARK: - 过渡动画

    /// 标准 ease（页面切换）
    static let standard = Animation.easeInOut(duration: 0.2)

    /// 慢速 ease（重要状态变化）
    static let slow = Animation.easeInOut(duration: 0.4)

    // MARK: - 修为进度条

    /// 进度条填充动画
    static let progressFill = Animation.easeOut(duration: 0.6)

    // MARK: - 粒子动画（境界突破）

    /// 粒子扩散动画
    static let particleSpread = Animation.easeOut(duration: 0.8)
}

// MARK: - 莲花状态枚举

enum LotusState: String, Codable {
    case calm = "calm"
    case ripple = "ripple"
    case demon = "demon"

    var animation: Animation {
        switch self {
        case .calm: return LingXiAnimations.lotusCalm
        case .ripple: return LingXiAnimations.lotusRipple
        case .demon: return LingXiAnimations.lotusDemon
        }
    }

    var color: Color {
        switch self {
        case .calm: return LingXiColors.lotusCalm
        case .ripple: return LingXiColors.lotusRipple
        case .demon: return LingXiColors.lotusDemon
        }
    }

    var scaleRange: ClosedRange<CGFloat> {
        switch self {
        case .calm: return 0.9...1.1
        case .ripple: return 0.85...1.15
        case .demon: return 0.8...1.2
        }
    }

    var label: String {
        switch self {
        case .calm: return "灵台清明"
        case .ripple: return "心绪微澜"
        case .demon: return "心魔暗生"
        }
    }

    /// 带字距的状态文字（对应原型 letter-spacing:4px 效果）
    var spacedLabel: String {
        switch self {
        case .calm:   return "灵 台 清 明"
        case .ripple: return "心 绪 微 澜"
        case .demon:  return "心 魔 暗 生"
        }
    }
}

// MARK: - 修炼奖励等级

enum SleepGrade: String, Codable {
    case immortal = "仙品"
    case superior = "上品"
    case medium = "中品"
    case poor = "未入定"
    case noData = "无数据"

    var spiritEnergyReward: Int {
        switch self {
        case .immortal: return 100
        case .superior: return 70
        case .medium: return 40
        case .poor: return 10
        case .noData: return 5
        }
    }

    var color: Color {
        switch self {
        case .immortal: return LingXiColors.gradeLegendary
        case .superior: return LingXiColors.gradeEpic
        case .medium: return LingXiColors.gradeMedium
        case .poor: return LingXiColors.gradeCommon
        case .noData: return LingXiColors.textSecondary
        }
    }
}

enum JourneyLevel: Int, Comparable {
    case none = 0
    case basic = 1      // 5000步 或 运动30分钟
    case full = 2       // 10000步 或 三环全闭合
    case legendary = 3  // 连续3日 full 达标

    static func < (lhs: JourneyLevel, rhs: JourneyLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var cultivationReward: Int {
        switch self {
        case .none: return 0
        case .basic: return 20
        case .full: return 30
        case .legendary: return 50
        }
    }
}
