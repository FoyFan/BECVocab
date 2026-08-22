import Foundation

struct Word: Codable, Identifiable, Hashable {
    let en: String
    let ipa: String
    let uk: String
    let zh: String
    let ex: String
    var exZh: String = ""

    var id: String { en }

    enum CodingKeys: String, CodingKey {
        case en, ipa, uk, zh, ex, exZh
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        en = try container.decode(String.self, forKey: .en)
        ipa = try container.decode(String.self, forKey: .ipa)
        uk = try container.decode(String.self, forKey: .uk)
        zh = try container.decode(String.self, forKey: .zh)
        ex = try container.decode(String.self, forKey: .ex)
        exZh = try container.decodeIfPresent(String.self, forKey: .exZh) ?? ""
    }

    var ipaDisplay: String {
        if !ipa.isEmpty { return "/\(ipa)/" }
        if !uk.isEmpty { return "/\(uk)/" }
        return ""
    }

    var hasExample: Bool { !ex.isEmpty }
}