import Foundation

struct AnatomyItem: Identifiable, Hashable { let id: String; let name: String; let summary: String }

enum AnatomyStore {
    static let items: [AnatomyItem] = [
        .init(id: "upper_lateral_cartilage", name: "上外侧软骨", summary: "鼻背上段两侧软骨，影响鼻背线顺直与过渡。"),
        .init(id: "nasal_bone", name: "鼻骨", summary: "上段骨性支架，决定鼻背高度与宽窄。"),
        .init(id: "septal_cartilage", name: "鼻中隔软骨", summary: "鼻尖与鼻背重要支撑材料来源。"),
        .init(id: "pogonion", name: "颏前点 (Pogonion)", summary: "颏部最前点，决定侧面下巴投影。"),
        .init(id: "menton", name: "颏下点 (Menton)", summary: "颏部最低点，影响颏部长度与轮廓。")
    ]

    static func byIds(_ ids: [String]) -> [AnatomyItem] {
        let set = Set(ids)
        return items.filter { set.contains($0.id) }
    }
}


