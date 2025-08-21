import Foundation

struct HomeConfig: Codable {
    var banners: [BannerItem]
    var categories: [CategoryItem]
    var featured: [FeaturedItem]
    var quickActions: [QuickActionItem]

    static let `default` = HomeConfig(
        banners: [
            .init(title: "闪购嗨BUY指南", subtitle: "活动示意图 · 占位"),
            .init(title: "超级补贴", subtitle: "全城低价无套路"),
            .init(title: "甄选名院", subtitle: "TOP机构曝光")
        ],
        categories: [
            .init(title: "皮肤管理", symbol: "sparkles"),
            .init(title: "除皱抗衰", symbol: "face.smiling"),
            .init(title: "瘦脸轮廓", symbol: "person.crop.square"),
            .init(title: "鼻部", symbol: "nose"),
            .init(title: "美体塑形", symbol: "figure.arms.open"),
            .init(title: "玻尿酸", symbol: "drop"),
            .init(title: "眼部", symbol: "eye"),
            .init(title: "私密整形", symbol: "lock"),
            .init(title: "嗨Buy 指南", symbol: "book"),
            .init(title: "更多", symbol: "ellipsis.circle")
        ],
        featured: [
            .init(title: "风向标", subtitle: "身体刷酸 ¥199起", symbol: "sparkles"),
            .init(title: "超级补贴", subtitle: "全城低价无套路", symbol: "flame"),
            .init(title: "吸脂名院", subtitle: "TOP机构曝光", symbol: "cross.case"),
            .init(title: "引导拍摄", subtitle: "开始拍摄三视图", symbol: "camera")
        ],
        quickActions: [
            .init(title: "口碑榜", symbol: "rosette"),
            .init(title: "魔镜", symbol: "face.smiling"),
            .init(title: "试用官", symbol: "person.crop.circle.badge.checkmark"),
            .init(title: "美肤套餐", symbol: "leaf"),
            .init(title: "附近优惠", symbol: "mappin.and.ellipse"),
            .init(title: "福利社", symbol: "gift")
        ]
    )
}

struct BannerItem: Codable, Identifiable { let id = UUID(); let title: String; let subtitle: String }
struct CategoryItem: Codable, Identifiable { let id = UUID(); let title: String; let symbol: String }
struct FeaturedItem: Codable, Identifiable { let id = UUID(); let title: String; let subtitle: String; let symbol: String }
struct QuickActionItem: Codable, Identifiable { let id = UUID(); let title: String; let symbol: String }

enum HomeConfigLoader {
    static func loadFromBundle() -> HomeConfig? {
        guard let url = Bundle.main.url(forResource: "home_data", withExtension: "json") else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(HomeConfig.self, from: data)
        } catch {
            return nil
        }
    }
}


