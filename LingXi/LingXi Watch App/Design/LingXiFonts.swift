import SwiftUI

// 灵息字体规范
// watchOS 最小可读字号：footnote (13pt)
// 使用系统字体，通过 weight/design 实现古风气质
enum LingXiFonts {

    // MARK: - 标题系列

    /// 境界大标题（境界突破弹窗）— title2 + bold
    static let realmTitle: Font = .title2.weight(.bold)

    /// 页面主标题 — headline + semibold
    static let pageTitle: Font = .headline.weight(.semibold)

    /// 卡片标题 — subheadline + medium
    static let cardTitle: Font = .subheadline.weight(.medium)

    // MARK: - 正文系列

    /// 主要正文 — body
    static let body: Font = .body

    /// 修为数值大字（首页核心展示）— title3 + bold + monospaced
    static let cultivationValue: Font = .title3.weight(.bold).monospacedDigit()

    /// 心率数值 — title2 + light（强调轻盈感）
    static let heartRateValue: Font = .title2.weight(.light).monospacedDigit()

    /// 步数大字（历练页）— title + bold
    static let stepsValue: Font = .title.weight(.bold).monospacedDigit()

    // MARK: - 辅助文字

    /// 说明文字 — footnote（最小可读）
    static let caption: Font = .footnote

    /// 标签/品级文字 — caption2 + medium
    static let label: Font = .caption2.weight(.medium)

    /// Complication 文字 — caption2
    static let complication: Font = .caption2.monospacedDigit()
}

// MARK: - 修饰符便捷扩展

extension View {

    /// 境界名标题样式（金色 + bold）
    func realmTitleStyle() -> some View {
        self.font(LingXiFonts.realmTitle)
            .foregroundStyle(LingXiColors.gold)
    }

    /// 修为数值样式（青瓷色 + monospaced）
    func cultivationValueStyle() -> some View {
        self.font(LingXiFonts.cultivationValue)
            .foregroundStyle(LingXiColors.teal)
    }

    /// 灵物品级标签样式
    func gradeLabelStyle(grade: String) -> some View {
        self.font(LingXiFonts.label)
            .foregroundStyle(LingXiColors.gradeColor(for: grade))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(LingXiColors.gradeColor(for: grade).opacity(0.2))
            )
    }
}
