import SwiftUI

// MARK: - 三环组件（仿 Apple Activity Rings）

struct ActivityRingView: View {

    let calories: Double      // 目标 400 kcal
    let exercise: Int         // 目标 30 min
    let stand: Int            // 目标 12 h

    var body: some View {
        ZStack {
            // 站立环（外圈）
            ring(progress: standProgress, color: .cyan,        width: 8, diameter: 80)
            // 运动环（中圈）
            ring(progress: exerciseProgress, color: LingXiColors.teal, width: 8, diameter: 62)
            // 卡路里环（内圈）
            ring(progress: caloriesProgress, color: LingXiColors.gold, width: 8, diameter: 44)
        }
        .frame(width: 90, height: 90)
    }

    private func ring(progress: CGFloat,
                      color: Color,
                      width: CGFloat,
                      diameter: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: width)
                .frame(width: diameter, height: diameter)
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .round))
                .frame(width: diameter, height: diameter)
                .rotationEffect(.degrees(-90))
                .animation(LingXiAnimations.progressFill, value: progress)
        }
    }

    private var caloriesProgress: CGFloat { CGFloat(calories) / 400 }
    private var exerciseProgress: CGFloat { CGFloat(exercise) / 30 }
    private var standProgress: CGFloat    { CGFloat(stand) / 12 }
}
