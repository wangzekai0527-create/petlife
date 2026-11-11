// Dedicated accounts only. Creates a public test pet and one conversation.
// Set PETLIFE_TEST_ACCOUNTS to a JSON file [{email,password}, {email,password}].
import Foundation
actor Events {
    var connected = false
    var changes = 0
    func record(_ event: ChatEvent) {
        switch event { case .connected: connected = true; print("Realtime channel joined"); case .changed: changes += 1; print("Realtime database change received"); default: print("Realtime reconnecting") }
    }
}
@main struct ChatSmoke {
    struct Account: Decodable { let email: String; let password: String }
    static func require(_ condition: Bool, _ message: String) throws {
        if !condition { throw NSError(domain: message, code: 1) }
    }
    static func success(_ payload: BootstrapPayload) throws {
        if let error = payload.backendMessage { throw NSError(domain: error, code: 1) }
    }
    static func waitFor(_ condition: () async -> Bool) async throws {
        for _ in 0..<100 {
            if await condition() { return }
            try await Task.sleep(for: .milliseconds(200))
        }
        throw NSError(domain: "Realtime timeout", code: 1)
    }
    static func main() async throws {
        let path = ProcessInfo.processInfo.environment["PETLIFE_TEST_ACCOUNTS"]!
        let accounts = try JSONDecoder().decode([Account].self, from: Data(contentsOf: URL(fileURLWithPath: path)))
        let a = PetBackendFactory.makeDefaultBackend(), b = PetBackendFactory.makeDefaultBackend()
        let pa = await a.signIn(with: SignInDraft(email: accounts[0].email, password: accounts[0].password, displayName: "Chat test A"))
        let pb = await b.signIn(with: SignInDraft(email: accounts[1].email, password: accounts[1].password, displayName: "Chat test B"))
        try success(pa); try success(pb)
        guard let owner = pb.currentUser else { fatalError("No authenticated owner") }
        var draft = PetDraft(name: "Realtime verification \(UUID().uuidString.prefix(8))", breed: "Test")
        draft.isDiscoverable = true
        let saved = await b.addPet(draft, owner: owner); try success(saved)
        let discover = await a.bootstrap(); try success(discover)
        guard let pet = discover.discoverPets.first(where: { $0.name == draft.name && $0.ownerUserID == owner.id }) else { fatalError("Public pet not discoverable") }
        let (opened, threadID) = await a.openChat(for: pet); try success(opened)
        let ea = Events(), eb = Events()
        let ta = Task { for await event in await a.chatEvents() { await ea.record(event) } }
        let tb = Task { for await event in await b.chatEvents() { await eb.record(event) } }
        defer { ta.cancel(); tb.cancel() }
        try await waitFor { let first = await ea.connected; let second = await eb.connected; return first && second }
        let id = UUID(), text = "Hello from A / 来自 A 的消息"
        let sent = await a.sendMessage(threadID: threadID, text: text, messageID: id); try success(sent)
        try await waitFor { await eb.changes > 0 }
        let receiverThreads = try await b.refreshChats()
        guard let received = receiverThreads.first(where: { $0.id == threadID }), let message = received.messages.last else { fatalError("Recipient cannot read message") }
        try require(message.id == id && !message.isFromCurrentUser && received.unreadCount == 1, "Sender identity or unread count incorrect")
        print("PASS: authenticated realtime delivery A → B, correct sender and unread count")
        try await b.markRead(threadID: threadID, through: message.sentAt!)
        let senderThreads = try await a.refreshChats()
        try require(senderThreads.first(where: { $0.id == threadID })?.messages.last?.isRead == true, "Read receipt missing")
        print("PASS: participant read receipt")
        let before = await ea.changes
        let reply = await b.sendMessage(threadID: threadID, text: "Reply from B", messageID: UUID());try success(reply)
        try await waitFor { await ea.changes > before }
        let final = try await a.refreshChats().first(where: { $0.id == threadID })!
        try require(final.messages.last?.text == "Reply from B" && final.messages.last?.isFromCurrentUser == false, "Reply missing")
        print("PASS: authenticated realtime delivery B → A")
        let retried = await a.sendMessage(threadID: threadID, text: text, messageID: id);try success(retried)
        let dedup = try await a.refreshChats().first(where: { $0.id == threadID })!
        try require(dedup.messages.filter { $0.id == id }.count == 1, "Duplicate message on retry")
        print("PASS: idempotent retry without duplicate messages")
        let failed = await a.sendMessage(threadID: UUID(), text: "Must fail", messageID: UUID())
        try require(failed.backendMessage != nil, "Missing conversation was silently accepted")
        print("PASS: invalid conversation fails explicitly")
        try await Task.sleep(for: .seconds(27))
        let heartbeatCount = await ea.changes
        let afterHeartbeat = await b.sendMessage(threadID: threadID, text: "After heartbeat", messageID: UUID())
        try success(afterHeartbeat)
        try await waitFor { await ea.changes > heartbeatCount }
        print("PASS: live delivery after heartbeat and token refresh frame")
        let disabled = await b.setPetDiscoverable(pet.id, enabled: false);try success(disabled)
        let hidden = await a.bootstrap();try success(hidden)
        try require(!hidden.discoverPets.contains(where: { $0.id == pet.id }), "Private profile still visible")
        print("PASS: profile sharing can be disabled")
        try Data(threadID.uuidString.utf8).write(to: URL(fileURLWithPath: "/tmp/petlife-chat-test-thread"))
    }
}
