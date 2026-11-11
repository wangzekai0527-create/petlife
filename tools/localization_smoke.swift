import Foundation
@main struct LocalizationSmoke {
    static func main() {
        let saved = UserDefaults.standard.object(forKey: L10n.preferenceKey)
        defer { UserDefaults.standard.set(saved, forKey: L10n.preferenceKey) }
        UserDefaults.standard.set("en", forKey: L10n.preferenceKey)
        precondition(L10n.text("宠物交友") == "Pet friends")
        precondition(L10n.text("0 条补充") == "0 notes")
        precondition(L10n.text("你好，小明") == "Hello, 小明")
        precondition(L10n.text("My own message / 我自己的消息") == "My own message / 我自己的消息")
        for (_, english) in L10n.english { precondition(!english.isEmpty) }
        UserDefaults.standard.set("zh-Hans", forKey: L10n.preferenceKey)
        precondition(L10n.text("宠物交友") == "宠物交友")
        precondition(L10n.text("0 条补充") == "0 条补充")
        print("PASS: bilingual catalog, interpolated labels, original user text and Chinese restoration")
    }
}
