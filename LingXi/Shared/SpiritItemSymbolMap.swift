import Foundation

/// 灵物 ID → SF Symbol 映射（因 xcassets 尚无实际图片，用 SF Symbol 代替）
enum SpiritItemSymbolMap {

    static func sfSymbol(for itemId: String) -> String {
        switch itemId {
        // 神品 gradeRank=5
        case "hundunlingzhu":    return "circle.hexagongrid.fill"  // 混沌灵珠
        case "hongmengzhilu":    return "drop.fill"                // 鸿蒙之露
        case "jiutianxuantie":   return "shield.checkered"         // 九天玄铁
        case "pantao":           return "leaf.fill"                // 蟠桃
        case "taixulingzhi":     return "sparkle"                  // 太虚灵芝

        // 仙品 gradeRank=4
        case "tianshan_xuelian": return "snowflake"                // 天山雪莲
        case "fenghuangyu":      return "flame.fill"               // 凤凰羽
        case "longxianxiang":    return "smoke.fill"               // 龙涎香
        case "qiongjiang":       return "wineglass.fill"           // 琼浆
        case "xingchensuipian":  return "star.fill"                // 星辰碎片

        // 上品 gradeRank=3
        case "qingyunshi":      return "cloud.fill"                // 青云石
        case "jinlvsi":         return "wand.and.rays"             // 金缕丝
        case "yehua":           return "moon.stars.fill"           // 夜华
        case "lingheyu":        return "drop.triangle.fill"        // 灵荷玉

        // 中品 gradeRank=2
        case "baihualu":        return "camera.macro"              // 百花露
        case "chenlu":          return "sunrise.fill"              // 晨露
        case "yusui":           return "diamond.fill"              // 玉髓
        case "bibozhu":         return "circle.fill"               // 碧波珠

        // 下品 gradeRank=1
        case "songfeng":        return "wind"                      // 松风
        case "qingquan":        return "drop.degreesign.fill"      // 清泉

        default:                return "star.fill"
        }
    }
}
