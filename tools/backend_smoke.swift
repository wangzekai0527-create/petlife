// Run only against a dedicated test account. See README for required environment variables.
import Foundation

@main
struct BackendSmoke {
    static func requireSuccess(_ payload: BootstrapPayload) throws {
        if let message = payload.backendMessage {
            throw NSError(domain: "BackendSmoke", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }
    }

    static func main() async throws {
        let backend = PetBackendFactory.makeDefaultBackend()
        let mode = CommandLine.arguments.dropFirst().first ?? "write"
        if mode == "read" {
            let payload = await backend.bootstrap()
            try requireSuccess(payload)
            precondition(payload.currentUser != nil, "Session did not survive process restart")
            precondition(payload.ownedPets.contains { $0.name == "连接验证小宠" }, "Pet did not persist")
            guard let memory = payload.memories.first(where: { $0.title == "云端媒体验证" }),
                  let url = MemoryAssetStore.url(for: memory.photoAssetPath) else {
                fatalError("Memory/media did not persist")
            }
            let bytes = try Data(contentsOf: url)
            precondition(bytes == testImage, "Downloaded media differs from uploaded media")
            print("PASS: fresh process restored session, pet, memory and private media")
        } else if mode == "signout" {
            try requireSuccess(await backend.bootstrap())
            let signedOut = await backend.signOut()
            try requireSuccess(signedOut)
            precondition(signedOut.currentUser == nil)
            let afterSignOut = await backend.bootstrap()
            precondition(afterSignOut.currentUser == nil)
            print("PASS: sign-out cleared local session")
        } else {
            let env = ProcessInfo.processInfo.environment
            guard let email = env["PETLIFE_TEST_EMAIL"], let password = env["PETLIFE_TEST_PASSWORD"] else {
                fatalError("Set PETLIFE_TEST_EMAIL and PETLIFE_TEST_PASSWORD for a dedicated test account")
            }
            let payload = await backend.signIn(with: SignInDraft(email: email, password: password, displayName: "后端连接验证"))
            try requireSuccess(payload)
            guard let user = payload.currentUser else { fatalError("Sign-in failed") }
            let saved = await backend.addPet(PetDraft(name: "连接验证小宠", breed: "测试", ageText: "1岁"), owner: user)
            try requireSuccess(saved)
            let path = try MemoryAssetStore.saveBinaryData(testImage, preferredExtension: "png")
            let memory = await backend.addMemory(MemoryDraft(title: "云端媒体验证", story: "可清理的自动验证记录", photoAssetPath: path))
            try requireSuccess(memory)
            print("PASS: authenticated write of pet, memory and private media")
        }
    }

    static let testImage = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aX1cAAAAASUVORK5CYII=")!
}
