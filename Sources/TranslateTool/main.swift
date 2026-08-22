import Foundation
import Translation

@available(macOS 26, *)
@main
struct TranslateTool {
    static func main() async {
        let fileURL = URL(fileURLWithPath: "/Users/foy.fan/Desktop/BECVocab/Sources/BECVocab/Resources/bec_data.json")

        guard let data = try? Data(contentsOf: fileURL),
              var words = try? JSONDecoder().decode([WordEntry].self, from: data) else {
            print("❌ Failed to load data")
            return
        }

        print("Loaded \(words.count) words")

        let source = Locale.Language(identifier: "en-US")
        let target = Locale.Language(identifier: "zh-CN")
        let session = TranslationSession(installedSource: source, target: target)

        let total = words.count
        var translated = 0
        var skipped = 0
        var failed = 0

        for i in 0..<total {
            if words[i].ex.isEmpty {
                words[i].exZh = ""
                skipped += 1
                continue
            }
            if !words[i].exZh.isEmpty {
                translated += 1
                continue
            }

            do {
                let response = try await session.translate(words[i].ex)
                words[i].exZh = response.targetText
                translated += 1
            } catch {
                words[i].exZh = ""
                failed += 1
                if failed <= 5 || i % 500 == 0 {
                    print("⚠️ Failed #\(i) '\(words[i].en)': \(error.localizedDescription)")
                }
            }

            if i % 100 == 0 && i > 0 {
                print("Progress: \(i)/\(total) (T:\(translated) S:\(skipped) F:\(failed))")
                let encoder = JSONEncoder()
                if let encoded = try? encoder.encode(words) {
                    try? encoded.write(to: fileURL)
                }
            }
        }

        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(words) {
            try? encoded.write(to: fileURL)
        }

        print("✅ Done! Translated: \(translated), Skipped: \(skipped), Failed: \(failed)")
    }
}

struct WordEntry: Codable {
    var en: String
    var ipa: String
    var uk: String
    var zh: String
    var ex: String
    var exZh: String = ""

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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(en, forKey: .en)
        try container.encode(ipa, forKey: .ipa)
        try container.encode(uk, forKey: .uk)
        try container.encode(zh, forKey: .zh)
        try container.encode(ex, forKey: .ex)
        try container.encode(exZh, forKey: .exZh)
    }
}