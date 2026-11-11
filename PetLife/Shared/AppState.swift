import Foundation
import Observation
import Security

enum MemoryAssetStore {
    private static let folderName = "MemoryAssets"

    static func url(for relativePath: String?) -> URL? {
        guard let relativePath, let directory = try? directoryURL() else {
            return nil
        }

        return directory.appendingPathComponent(relativePath)
    }

    static func saveImageData(_ data: Data, preferredExtension: String = "jpg") throws -> String {
        let sanitizedExtension = preferredExtension.isEmpty ? "jpg" : preferredExtension
        let relativePath = "\(UUID().uuidString.lowercased()).\(sanitizedExtension)"
        let destinationURL = try directoryURL().appendingPathComponent(relativePath)
        try data.write(to: destinationURL, options: .atomic)
        return relativePath
    }

    static func saveBinaryData(_ data: Data, preferredExtension: String) throws -> String {
        try saveImageData(data, preferredExtension: preferredExtension)
    }

    static func copyImportedFile(
        from sourceURL: URL,
        preferredExtension: String? = nil
    ) throws -> String {
        let ext = preferredExtension ?? sourceURL.pathExtension
        let sanitizedExtension = ext.isEmpty ? "bin" : ext
        let relativePath = "\(UUID().uuidString.lowercased()).\(sanitizedExtension)"
        let destinationURL = try directoryURL().appendingPathComponent(relativePath)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        return relativePath
    }

    static func existingRelativePath(fileName: String) -> String? {
        guard let directory = try? directoryURL() else {
            return nil
        }

        let sanitizedFileName = fileName.replacingOccurrences(of: "/", with: "_")
        let candidateURL = directory.appendingPathComponent(sanitizedFileName)
        return FileManager.default.fileExists(atPath: candidateURL.path) ? sanitizedFileName : nil
    }

    static func saveDownloadedData(_ data: Data, fileName: String) throws -> String {
        let sanitizedFileName = fileName.replacingOccurrences(of: "/", with: "_")
        let destinationURL = try directoryURL().appendingPathComponent(sanitizedFileName)
        try data.write(to: destinationURL, options: .atomic)
        return sanitizedFileName
    }

    private static func directoryURL() throws -> URL {
        let fileManager = FileManager.default
        let baseURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directoryURL = baseURL.appendingPathComponent(folderName, isDirectory: true)

        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        return directoryURL
    }
}

protocol PetBackend: Sendable {
    func bootstrap() async -> BootstrapPayload
    func signIn(with draft: SignInDraft) async -> BootstrapPayload
    func signOut() async -> BootstrapPayload
    func addPet(_ draft: PetDraft, owner: UserAccount) async -> BootstrapPayload
    func addMemory(_ draft: MemoryDraft) async -> BootstrapPayload
    func setPetDiscoverable(_ petID: UUID, enabled: Bool) async -> BootstrapPayload
    func createVideo(_ draft: VideoDraft, selectedAssetCount: Int) async -> BootstrapPayload
    func createPost(_ draft: PostDraft, user: UserAccount, petName: String) async -> BootstrapPayload
    func toggleLike(postID: UUID) async -> BootstrapPayload
    func addComment(postID: UUID, text: String, userName: String) async -> BootstrapPayload
    func openChat(for pet: PetProfile) async -> (BootstrapPayload, UUID)
    func sendMessage(threadID: UUID, text: String, messageID: UUID) async -> BootstrapPayload
    func refreshChats() async throws -> [ChatThread]
    func markRead(threadID: UUID, through: Date) async throws
    func chatEvents() async -> AsyncStream<ChatEvent>
}

enum ChatEvent: Sendable { case changed, connected, reconnecting }
extension PetBackend {
    func setPetDiscoverable(_ petID: UUID, enabled: Bool) async -> BootstrapPayload { await bootstrap() }
    func refreshChats() async throws -> [ChatThread] { await bootstrap().chatThreads }
    func markRead(threadID: UUID, through: Date) async throws {}
    func chatEvents() async -> AsyncStream<ChatEvent> { AsyncStream { $0.finish() } }
}

enum PetBackendFactory {
    static func makeDefaultBackend() -> any PetBackend {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return InMemoryPetBackend()
        }

        if ProcessInfo.processInfo.environment["PETLIFE_BACKEND"]?.lowercased() == "memory" {
            return InMemoryPetBackend()
        }

        guard let config = SupabaseConfig.load() else {
            print("[PetLife] Supabase config missing, switched to InMemory fallback.")
            return InMemoryPetBackend()
        }

        return SupabasePetBackend(config: config)
    }
}

actor InMemoryPetBackend: PetBackend {
    private var currentUser: UserAccount?
    private var ownedPets: [PetProfile]
    private var discoverPets: [PetProfile]
    private var memories: [HolidayMemory]
    private var uploadVideos: [UploadVideo]
    private var feedPosts: [FeedPost]
    private var chatThreads: [ChatThread]

    init() {
        self.currentUser = nil
        self.ownedPets = []
        self.discoverPets = Self.makeDiscoverPets()
        self.memories = []
        self.uploadVideos = []
        self.feedPosts = []
        self.chatThreads = []
    }

    func bootstrap() async -> BootstrapPayload {
        BootstrapPayload(
            currentUser: currentUser,
            ownedPets: ownedPets,
            discoverPets: discoverPets,
            memories: memories,
            uploadVideos: uploadVideos,
            feedPosts: feedPosts,
            chatThreads: chatThreads
        )
    }

    func signIn(with draft: SignInDraft) async -> BootstrapPayload {
        let user = UserAccount(
            id: UUID(),
            displayName: draft.displayName.isEmpty ? "新用户" : draft.displayName,
            phone: draft.phone,
            city: draft.city,
            bio: "在 PetLife 记录宠物成长，也希望认识更多同频家庭。",
            avatarSymbol: "person.crop.circle.fill"
        )
        resetSessionState(for: user)

        return await bootstrap()
    }

    func signOut() async -> BootstrapPayload {
        resetSessionState(for: nil)
        return await bootstrap()
    }

    func addPet(_ draft: PetDraft, owner: UserAccount) async -> BootstrapPayload {
        let pet = PetProfile(
            id: UUID(),
            name: draft.name,
            species: draft.species,
            breed: draft.breed,
            ageText: draft.ageText,
            city: draft.city,
            bio: draft.bio,
            interests: draft.interests,
            lookingFor: draft.lookingFor,
            accent: draft.accent,
            ownerName: owner.displayName,
            vaccinated: draft.vaccinated
        )
        ownedPets.insert(pet, at: 0)
        return await bootstrap()
    }

    func addMemory(_ draft: MemoryDraft) async -> BootstrapPayload {
        let memory = HolidayMemory(
            id: draft.id,
            title: draft.title,
            subtitle: draft.subtitle,
            dateText: draft.dateText,
            ornament: draft.ornament,
            accent: draft.accent,
            story: draft.story,
            mediaKind: draft.mediaKind,
            mediaAssetPath: draft.mediaAssetPath ?? draft.photoAssetPath,
            mediaDisplayName: draft.mediaDisplayName,
            notes: [],
            photoAssetPath: draft.photoAssetPath,
            audioAssetPath: draft.audioAssetPath,
            audioDisplayName: draft.audioDisplayName
        )
        memories.insert(memory, at: 0)
        return await bootstrap()
    }

    func createVideo(_ draft: VideoDraft, selectedAssetCount: Int) async -> BootstrapPayload {
        let video = UploadVideo(
            id: UUID(),
            title: draft.title,
            duration: draft.duration,
            caption: draft.caption,
            tags: draft.tags,
            status: selectedAssetCount == 0 ? .draft : .uploading,
            selectedAssetCount: selectedAssetCount,
            accent: draft.accent,
            publishDateText: selectedAssetCount == 0 ? "草稿" : "刚刚"
        )
        uploadVideos.insert(video, at: 0)
        return await bootstrap()
    }

    func createPost(_ draft: PostDraft, user: UserAccount, petName: String) async -> BootstrapPayload {
        let relatedPetID = ownedPets.first(where: { $0.name == petName })?.id
        let post = FeedPost(
            id: draft.id,
            relatedPetID: relatedPetID,
            authorName: user.displayName,
            petName: petName,
            topic: draft.topic,
            city: draft.city,
            content: draft.content,
            tags: draft.tags,
            likes: 0,
            comments: [],
            likedByCurrentUser: false,
            createdAtText: "刚刚"
        )
        feedPosts.insert(post, at: 0)
        return await bootstrap()
    }

    func toggleLike(postID: UUID) async -> BootstrapPayload {
        guard let index = feedPosts.firstIndex(where: { $0.id == postID }) else {
            return await bootstrap()
        }

        feedPosts[index].likedByCurrentUser.toggle()
        feedPosts[index].likes += feedPosts[index].likedByCurrentUser ? 1 : -1
        return await bootstrap()
    }

    func addComment(postID: UUID, text: String, userName: String) async -> BootstrapPayload {
        guard let index = feedPosts.firstIndex(where: { $0.id == postID }) else {
            return await bootstrap()
        }

        let comment = PostComment(
            id: UUID(),
            authorName: userName,
            body: text,
            createdAtText: "刚刚"
        )
        feedPosts[index].comments.append(comment)
        return await bootstrap()
    }

    func openChat(for pet: PetProfile) async -> (BootstrapPayload, UUID) {
        if let existing = chatThreads.first(where: { $0.relatedPetID == pet.id }) {
            return (await bootstrap(), existing.id)
        }

        let thread = ChatThread(
            id: UUID(),
            relatedPetID: pet.id,
            title: "\(pet.ownerName) · \(pet.name)",
            subtitle: "新的聊天已开启",
            unreadCount: 0,
            accent: pet.accent,
            messages: [
                ChatMessage(id: UUID(), text: "你好，我想进一步了解 \(pet.name) 的档案和相处习惯。", isFromCurrentUser: true, sentAtText: "刚刚")
            ]
        )
        chatThreads.insert(thread, at: 0)
        return (await bootstrap(), thread.id)
    }

    func sendMessage(threadID: UUID, text: String, messageID: UUID) async -> BootstrapPayload {
        guard let index = chatThreads.firstIndex(where: { $0.id == threadID }) else {
            return await bootstrap()
        }

        chatThreads[index].messages.append(
            ChatMessage(id: messageID, text: text, isFromCurrentUser: true, sentAtText: "刚刚")
        )
        chatThreads[index].subtitle = text
        chatThreads[index].unreadCount = 0
        return await bootstrap()
    }

    private func resetSessionState(for user: UserAccount?) {
        currentUser = user

        guard let user else {
            ownedPets = []
            memories = []
            uploadVideos = []
            feedPosts = []
            chatThreads = []
            return
        }

        ownedPets = Self.makeDefaultOwnedPets(for: user)
        memories = Self.makeDefaultMemories()
        uploadVideos = Self.makeDefaultUploadVideos()
        feedPosts = Self.makeDefaultFeedPosts(from: discoverPets)
        chatThreads = Self.makeDefaultChatThreads(from: discoverPets)
    }

    static func makeDiscoverPets() -> [PetProfile] {
        [
            PetProfile(
                id: UUID(uuidString: "A0000000-0000-0000-0000-000000000001") ?? UUID(),
                name: "Bobo",
                species: "狗狗",
                breed: "柯基",
                ageText: "2岁",
                city: "上海",
                bio: "情绪稳定，喜欢飞盘和草地社交，见面会先闻闻再摇尾巴。",
                interests: ["飞盘", "露营", "亲人"],
                lookingFor: "周末能一起跑起来的玩伴",
                accent: .peach,
                ownerName: "林夏",
                vaccinated: true
            ),
            PetProfile(
                id: UUID(uuidString: "A0000000-0000-0000-0000-000000000002") ?? UUID(),
                name: "Mochi",
                species: "猫咪",
                breed: "布偶猫",
                ageText: "1岁半",
                city: "杭州",
                bio: "慢热但很黏人，适合安静家庭，也愿意先从线上视频认识。",
                interests: ["晒太阳", "陪伴", "安静"],
                lookingFor: "性格温柔的长期陪伴对象",
                accent: .sky,
                ownerName: "Qiao",
                vaccinated: true
            ),
            PetProfile(
                id: UUID(uuidString: "A0000000-0000-0000-0000-000000000003") ?? UUID(),
                name: "Dumpling",
                species: "狗狗",
                breed: "比熊",
                ageText: "3岁",
                city: "苏州",
                bio: "社交感很强，喜欢拍照，出门散步时会主动跟别的狗狗打招呼。",
                interests: ["拍照", "社交", "散步"],
                lookingFor: "一起拍写真、一起遛街的朋友",
                accent: .mint,
                ownerName: "周周",
                vaccinated: true
            )
        ]
    }

    static func makeDefaultOwnedPets(for user: UserAccount) -> [PetProfile] {
        [
            PetProfile(
                id: UUID(),
                name: "Lucky",
                species: "狗狗",
                breed: "金毛",
                ageText: "10个月",
                city: user.city,
                bio: "爱出门、爱训练、也爱和人互动，最近开始学会在镜头前看镜头。",
                interests: ["训练", "户外", "握手"],
                lookingFor: "一起玩球、也能一起拍日常视频的朋友",
                accent: .ember,
                ownerName: user.displayName,
                vaccinated: true
            )
        ]
    }

    static func makeDefaultMemories() -> [HolidayMemory] {
        [
            HolidayMemory(
                id: UUID(),
                title: "初雪见面",
                subtitle: "领养那天的第一张照片，点亮了新的家庭故事。",
                dateText: "2025.12.03",
                ornament: "sparkles",
                accent: .ember,
                story: "我们第一次见面是在下雪天。它从航空箱里探出头时很安静，但那一瞬间我知道它要成为家里的一员。",
                mediaKind: .image,
                mediaAssetPath: nil,
                mediaDisplayName: nil,
                notes: [],
                photoAssetPath: nil,
                audioAssetPath: nil,
                audioDisplayName: nil
            ),
            HolidayMemory(
                id: UUID(),
                title: "第一次穿新衣服",
                subtitle: "记录宠物成长节点，每一张照片都是时间线上的小坐标。",
                dateText: "2025.12.10",
                ornament: "gift.fill",
                accent: .pine,
                story: "第一次试穿新衣服，它居然没有挣扎，还会自己走到镜头前等我们拍照。",
                mediaKind: .image,
                mediaAssetPath: nil,
                mediaDisplayName: nil,
                notes: [],
                photoAssetPath: nil,
                audioAssetPath: nil,
                audioDisplayName: nil
            ),
            HolidayMemory(
                id: UUID(),
                title: "第一次拍全家福",
                subtitle: "把视频、照片和文字组合成一条完整的成长时间线。",
                dateText: "2025.12.24",
                ornament: "star.fill",
                accent: .peach,
                story: "那一晚我们录了视频，也第一次把宠物成长故事整理成了一个完整相册。",
                mediaKind: .video,
                mediaAssetPath: nil,
                mediaDisplayName: nil,
                notes: [],
                photoAssetPath: nil,
                audioAssetPath: nil,
                audioDisplayName: nil
            )
        ]
    }

    static func makeDefaultUploadVideos() -> [UploadVideo] {
        [
            UploadVideo(
                id: UUID(),
                title: "Lucky第一次学会握手",
                duration: "00:34",
                caption: "训练第三天终于学会握手，奖励了两颗冻干。",
                tags: ["训练", "成长", "高互动"],
                status: .published,
                selectedAssetCount: 1,
                accent: .ember,
                publishDateText: "今天"
            ),
            UploadVideo(
                id: UUID(),
                title: "Milo雪地撒欢",
                duration: "01:12",
                caption: "第一次见雪，冲出去之后根本停不下来。",
                tags: ["冬天", "户外", "萌宠"],
                status: .reviewing,
                selectedAssetCount: 2,
                accent: .sky,
                publishDateText: "待审核"
            ),
            UploadVideo(
                id: UUID(),
                title: "Nana洗澡挑战",
                duration: "00:48",
                caption: "洗澡前后判若两狗，但还是很可爱。",
                tags: ["日常", "搞笑"],
                status: .draft,
                selectedAssetCount: 1,
                accent: .mint,
                publishDateText: "草稿"
            )
        ]
    }

    static func makeDefaultFeedPosts(from discoverPets: [PetProfile]) -> [FeedPost] {
        let bobo = discoverPets.first(where: { $0.name == "Bobo" })
        let mochi = discoverPets.first(where: { $0.name == "Mochi" })
        let dumpling = discoverPets.first(where: { $0.name == "Dumpling" })

        return [
            FeedPost(
                id: UUID(),
                relatedPetID: mochi?.id,
                authorName: "阿青",
                petName: "Mochi",
                topic: "同城交友",
                city: "上海",
                content: "想给我家猫咪找固定玩伴，周末徐汇滨江可以一起遛猫背包，也欢迎先交换宠物档案。",
                tags: ["猫咪", "徐汇", "周末"],
                likes: 128,
                comments: [
                    PostComment(id: UUID(), authorName: "小暖", body: "我家蓝猫也在附近，可以约一个安静场地先见面。", createdAtText: "1小时前")
                ],
                likedByCurrentUser: false,
                createdAtText: "今天 09:20"
            ),
            FeedPost(
                id: UUID(),
                relatedPetID: bobo?.id,
                authorName: "林夏",
                petName: "Bobo",
                topic: "宠物相亲",
                city: "上海",
                content: "春天到了，想给狗狗找一个脾气温和、疫苗齐全的相亲对象，也欢迎先线上视频见面。",
                tags: ["相亲", "疫苗齐全", "视频初聊"],
                likes: 203,
                comments: [
                    PostComment(id: UUID(), authorName: "森森", body: "我家比熊三岁，性格很稳，可以先视频互相看看。", createdAtText: "2小时前")
                ],
                likedByCurrentUser: true,
                createdAtText: "今天 11:40"
            ),
            FeedPost(
                id: UUID(),
                relatedPetID: dumpling?.id,
                authorName: "周周",
                petName: "Dumpling",
                topic: "活动组队",
                city: "苏州",
                content: "有没有家庭想一起拍成长主题写真和短视频？可以组个小型宠物日常记录局。",
                tags: ["写真", "短视频", "节日"],
                likes: 87,
                comments: [],
                likedByCurrentUser: false,
                createdAtText: "昨天"
            )
        ]
    }

    static func makeDefaultChatThreads(from discoverPets: [PetProfile]) -> [ChatThread] {
        guard let bobo = discoverPets.first(where: { $0.name == "Bobo" }) else {
            return []
        }

        return [
            ChatThread(
                id: UUID(),
                relatedPetID: bobo.id,
                title: "\(bobo.ownerName) · \(bobo.name)",
                subtitle: "已约好本周先视频见面",
                unreadCount: 1,
                accent: .plum,
                messages: [
                    ChatMessage(id: UUID(), text: "你好呀，我看到了你发的相亲动态。", isFromCurrentUser: false, sentAtText: "昨天 21:10"),
                    ChatMessage(id: UUID(), text: "可以，我们先交换宠物档案和疫苗信息。", isFromCurrentUser: true, sentAtText: "昨天 21:16"),
                    ChatMessage(id: UUID(), text: "太好了，我今晚把 \(bobo.name) 的档案卡发你。", isFromCurrentUser: false, sentAtText: "今天 08:05")
                ]
            )
        ]
    }
}

private enum SupabaseTable {
    static let userAccounts = "user_accounts"
    static let ownedPets = "owned_pets"
    static let holidayMemories = "holiday_memories"
    static let uploadVideos = "upload_videos"
    static let feedPosts = "feed_posts"
    static let postComments = "post_comments"
    static let chatThreads = "chat_threads"
    static let chatMessages = "chat_messages"
}

private enum SupabaseDateCodec {
    private static let fractionalFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let fallbackFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func string(from date: Date) -> String {
        fractionalFormatter.string(from: date)
    }

    static func date(from value: String?) -> Date {
        guard let value else { return .distantPast }
        if let date = fractionalFormatter.date(from: value) {
            return date
        }
        if let date = fallbackFormatter.date(from: value) {
            return date
        }
        return .distantPast
    }
}

private struct SupabaseConfig: Sendable {
    let projectURL: URL
    let anonKey: String
    let mediaBucket: String
    let publicMediaBucket: Bool

    static func load() -> SupabaseConfig? {
        guard
            let rawURL = value(for: "SUPABASE_URL"),
            let projectURL = normalizedProjectURL(rawURL),
            let anonKey = value(for: "SUPABASE_ANON_KEY")
        else {
            return nil
        }

        let mediaBucket = value(for: "SUPABASE_MEDIA_BUCKET") ?? "petlife-media"
        let publicMediaBucket = (value(for: "SUPABASE_MEDIA_PUBLIC") ?? "YES").lowercased() != "no"

        return SupabaseConfig(
            projectURL: projectURL,
            anonKey: anonKey,
            mediaBucket: mediaBucket,
            publicMediaBucket: publicMediaBucket
        )
    }

    // Accept either the dashboard project URL or a copied Data API URL.
    private static func normalizedProjectURL(_ rawValue: String) -> URL? {
        guard var components = URLComponents(string: rawValue),
              components.scheme == "https",
              let host = components.host, !host.isEmpty else {
            return nil
        }
        let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard path.isEmpty || path == "rest/v1" else { return nil }
        components.path = ""
        components.query = nil
        components.fragment = nil
        return components.url
    }

    private static func value(for key: String) -> String? {
        if let environmentValue = ProcessInfo.processInfo.environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !environmentValue.isEmpty {
            return environmentValue
        }

        if let plistValue = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            let trimmed = plistValue.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        return nil
    }
}

private enum LocalSessionStore {
    private static let activeUserKey = "petlife.activeUserID"

    static func loadActiveUserID() -> UUID? {
        guard let rawValue = UserDefaults.standard.string(forKey: activeUserKey) else {
            return nil
        }
        return UUID(uuidString: rawValue)
    }

    static func saveActiveUserID(_ userID: UUID?) {
        if let userID {
            UserDefaults.standard.set(userID.uuidString, forKey: activeUserKey)
        } else {
            UserDefaults.standard.removeObject(forKey: activeUserKey)
        }
    }
}

private struct SupabaseError: LocalizedError, Sendable {
    let message: String

    var errorDescription: String? {
        message
    }
}

private struct CloudSession: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let userID: UUID
    let expiresAt: Date
}

private actor SupabaseAuthClient {
    private struct AuthUser: Decodable { let id: UUID }
    private struct AuthResponse: Decodable {
        let access_token: String?
        let refresh_token: String?
        let expires_in: Double?
        let user: AuthUser?
    }
    private let config: SupabaseConfig
    private var session: CloudSession?
    private var refreshTask: Task<CloudSession, Error>?
    private var keychainQuery: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: "com.petlife.auth.\(config.projectURL.host ?? "")",
         kSecAttrAccount as String: "session"]
    }

    init(config: SupabaseConfig) { self.config = config }

    func restore() async throws -> UUID? {
        if session == nil {
            var query = keychainQuery
            query[kSecReturnData as String] = true
            query[kSecMatchLimit as String] = kSecMatchLimitOne
            var result: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            if status == errSecItemNotFound { return nil }
            guard status == errSecSuccess, let data = result as? Data else {
                throw SupabaseError(message: "无法读取已保存的登录状态，请重新登录。")
            }
            session = try JSONDecoder().decode(CloudSession.self, from: data)
        }
        _ = try await accessToken()
        return session?.userID
    }

    func signIn(_ draft: SignInDraft) async throws -> UUID? {
        let path = draft.isRegistration ? "signup" : "token?grant_type=password"
        let response = try await request(path, body: [
            "email": draft.email.trimmingCharacters(in: .whitespacesAndNewlines),
            "password": draft.password
        ])
        // Hosted projects normally require email verification before issuing a session.
        guard let token = response.access_token, let refresh = response.refresh_token,
              let user = response.user else { return nil }
        let newSession = CloudSession(accessToken: token, refreshToken: refresh,
            userID: user.id, expiresAt: Date().addingTimeInterval(response.expires_in ?? 3600))
        try save(newSession)
        return user.id
    }

    func accessToken() async throws -> String {
        guard let current = session else {
            throw SupabaseError(message: "请先登录。")
        }
        if current.expiresAt > Date().addingTimeInterval(60) { return current.accessToken }
        if let refreshTask { return try await refreshTask.value.accessToken }
        let task = Task<CloudSession, Error> {
            let response = try await self.request("token?grant_type=refresh_token", body: ["refresh_token": current.refreshToken])
            guard let token = response.access_token, let refresh = response.refresh_token,
                  let user = response.user else {
                throw SupabaseError(message: "登录已过期，请重新登录。")
            }
            return CloudSession(accessToken: token, refreshToken: refresh,
                userID: user.id, expiresAt: Date().addingTimeInterval(response.expires_in ?? 3600))
        }
        refreshTask = task
        defer { refreshTask = nil }
        let renewed = try await task.value
        try save(renewed)
        return renewed.accessToken
    }

    func signOut() async {
        let token = session?.accessToken
        session = nil
        SecItemDelete(keychainQuery as CFDictionary)
        if let token {
            var request = URLRequest(url: config.projectURL.appendingPathComponent("auth/v1/logout"))
            request.httpMethod = "POST"
            request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            _ = try? await URLSession.shared.data(for: request)
        }
    }

    private func save(_ value: CloudSession) throws {
        let data = try JSONEncoder().encode(value)
        let update = [kSecValueData as String: data]
        let status = SecItemUpdate(keychainQuery as CFDictionary, update as CFDictionary)
        if status == errSecItemNotFound {
            var item = keychainQuery
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else {
                throw SupabaseError(message: "无法安全保存登录状态。")
            }
        } else if status != errSecSuccess {
            throw SupabaseError(message: "无法安全保存登录状态。")
        }
        session = value
    }

    private func request(_ path: String, body: [String: String]) async throws -> AuthResponse {
        let url = URL(string: "auth/v1/" + path, relativeTo: config.projectURL.appendingPathComponent("/"))!.absoluteURL
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.httpBody = try JSONEncoder().encode(body)
        request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw SupabaseError(message: "登录服务没有响应。")
        }
        guard (200..<300).contains(response.statusCode) else {
            let error = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            let message = error?["msg"] as? String ?? error?["error_description"] as? String ?? error?["message"] as? String ?? "登录失败，请重试。"
            throw SupabaseError(message: message)
        }
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }
}

private struct SupabaseRESTClient: Sendable {
    enum StorageMode {
        case upload
        case authenticatedDownload
        case publicDownload
    }

    private let config: SupabaseConfig
    private let session = URLSession.shared
    private let auth: SupabaseAuthClient

    init(config: SupabaseConfig, auth: SupabaseAuthClient) {
        self.config = config
        self.auth = auth
    }

    func select<T: Decodable>(
        _ type: T.Type,
        from table: String,
        filters: [URLQueryItem] = [],
        limit: Int? = nil
    ) async throws -> [T] {
        var queryItems = filters
        queryItems.append(URLQueryItem(name: "select", value: "*"))
        if let limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }

        var request = URLRequest(url: try restURL(table: table, queryItems: queryItems))
        request.httpMethod = "GET"
        let data = try await perform(request)

        if data.isEmpty {
            return []
        }

        return try JSONDecoder().decode([T].self, from: data)
    }

    func insert<T: Encodable>(_ value: T, into table: String) async throws {
        var request = URLRequest(url: try restURL(table: table, queryItems: []))
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(value)
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        _ = try await perform(request)
    }

    func selectAll<T: Decodable>(_ type: T.Type, from table: String, filters: [URLQueryItem]) async throws -> [T] {
        var all: [T] = []
        var offset = 0
        while !Task.isCancelled {
            let page = try await select(type, from: table,
                filters: filters + [URLQueryItem(name: "offset", value: String(offset))], limit: 500)
            all.append(contentsOf: page)
            if page.count < 500 { break }
            offset += page.count
        }
        try Task.checkCancellation()
        return all
    }

    func upsert<T: Encodable>(_ value: T, table: String, conflict: String, ignoreDuplicates: Bool = false) async throws {
        var request = URLRequest(url: try restURL(table: table,
            queryItems: [URLQueryItem(name: "on_conflict", value: conflict)]))
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(value)
        request.setValue("resolution=\(ignoreDuplicates ? "ignore" : "merge")-duplicates,return=minimal", forHTTPHeaderField: "Prefer")
        _ = try await perform(request)
    }

    func insertMany<T: Encodable>(_ values: [T], into table: String) async throws {
        guard !values.isEmpty else { return }

        var request = URLRequest(url: try restURL(table: table, queryItems: []))
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(values)
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        _ = try await perform(request)
    }

    func update<T: Encodable>(_ value: T, table: String, filters: [URLQueryItem]) async throws {
        var request = URLRequest(url: try restURL(table: table, queryItems: filters))
        request.httpMethod = "PATCH"
        request.httpBody = try JSONEncoder().encode(value)
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        _ = try await perform(request)
    }

    func delete(from table: String, filters: [URLQueryItem]) async throws {
        var request = URLRequest(url: try restURL(table: table, queryItems: filters))
        request.httpMethod = "DELETE"
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        _ = try await perform(request)
    }

    func uploadObject(data: Data, path: String, contentType: String) async throws {
        var request = URLRequest(url: try storageURL(path: path, mode: .upload))
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "x-upsert")
        _ = try await perform(request)
    }

    func downloadObject(path: String) async throws -> Data {
        let mode: StorageMode = config.publicMediaBucket ? .publicDownload : .authenticatedDownload
        var request = URLRequest(url: try storageURL(path: path, mode: mode))
        request.httpMethod = "GET"

        if mode == .publicDownload {
            request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
        }

        return try await perform(request, includeJSONHeaders: mode != .publicDownload)
    }

    private func restURL(table: String, queryItems: [URLQueryItem]) throws -> URL {
        let baseURL = config.projectURL
            .appendingPathComponent("rest")
            .appendingPathComponent("v1")
            .appendingPathComponent(table)

        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw SupabaseError(message: "无法生成 Supabase 请求地址。")
        }

        components.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components.url else {
            throw SupabaseError(message: "无法生成 Supabase 请求地址。")
        }

        return url
    }

    private func storageURL(path: String, mode: StorageMode) throws -> URL {
        var url = config.projectURL
            .appendingPathComponent("storage")
            .appendingPathComponent("v1")
            .appendingPathComponent("object")

        switch mode {
        case .upload:
            break
        case .authenticatedDownload:
            url = url.appendingPathComponent("authenticated")
        case .publicDownload:
            url = url.appendingPathComponent("public")
        }

        url = url.appendingPathComponent(config.mediaBucket)
        for segment in path.split(separator: "/") {
            url = url.appendingPathComponent(String(segment))
        }
        return url
    }

    private func perform(_ request: URLRequest, includeJSONHeaders: Bool = true) async throws -> Data {
        var request = request
        request.setValue(config.anonKey, forHTTPHeaderField: "apikey")
        request.timeoutInterval = 30
        request.setValue("Bearer \(try await auth.accessToken())", forHTTPHeaderField: "Authorization")
        if includeJSONHeaders {
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            if request.value(forHTTPHeaderField: "Content-Type") == nil, request.httpMethod != "GET" {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError(message: "Supabase 没有返回有效的 HTTP 响应。")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw SupabaseError(message: errorMessage(from: data, statusCode: httpResponse.statusCode))
        }

        return data
    }

    private func errorMessage(from data: Data, statusCode: Int) -> String {
        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let message = object["message"] as? String ?? object["error_description"] as? String ?? object["error"] as? String
        else {
            let plainText = String(decoding: data, as: UTF8.self)
            return plainText.isEmpty ? "Supabase 请求失败，状态码 \(statusCode)。" : plainText
        }

        return message
    }
}

private struct UserRow: Codable, Sendable {
    let id: UUID
    var display_name: String
    var phone: String
    var city: String
    var bio: String
    var avatar_symbol: String
    var created_at: String
    var updated_at: String
}

private struct OwnedPetRow: Codable, Sendable {
    let id: UUID
    let user_id: UUID
    var name: String
    var species: String
    var breed: String
    var age_text: String
    var city: String
    var bio: String
    var interests: [String]
    var looking_for: String
    var accent: String
    var owner_name: String
    var vaccinated: Bool
    var is_discoverable: Bool
    var created_at: String
    var updated_at: String
}

private struct HolidayMemoryRow: Codable, Sendable {
    let id: UUID
    let user_id: UUID
    var title: String
    var subtitle: String
    var date_text: String
    var ornament: String
    var accent: String
    var story: String
    var photo_storage_path: String?
    var audio_storage_path: String?
    var audio_display_name: String?
    var created_at: String
    var updated_at: String
}

private struct UploadVideoRow: Codable, Sendable {
    let id: UUID
    let user_id: UUID
    var title: String
    var duration: String
    var caption: String
    var tags: [String]
    var status: String
    var selected_asset_count: Int
    var accent: String
    var publish_date_text: String
    var created_at: String
    var updated_at: String
}

private struct FeedPostRow: Codable, Sendable {
    let id: UUID
    let user_id: UUID
    var related_pet_id: UUID?
    var author_name: String
    var pet_name: String
    var topic: String
    var city: String
    var content: String
    var tags: [String]
    var likes: Int
    var liked_by_current_user: Bool
    var created_at_text: String
    var created_at: String
    var updated_at: String
}

private struct PostCommentRow: Codable, Sendable {
    let id: UUID
    let user_id: UUID
    let post_id: UUID
    var author_name: String
    var body: String
    var created_at_text: String
    var created_at: String
    var updated_at: String
}

private struct ChatReadRow: Codable, Sendable {
    let thread_id: UUID
    let user_id: UUID
    let last_read_at: String
}

private struct ChatThreadRow: Codable, Sendable {
    let id: UUID
    let user_id: UUID
    let related_pet_id: UUID
    var participant_id: UUID? = nil
    var title: String
    var subtitle: String
    var unread_count: Int
    var accent: String
    var created_at: String
    var updated_at: String
}

private struct ChatMessageRow: Codable, Sendable {
    let id: UUID
    let user_id: UUID
    let thread_id: UUID
    var text: String
    var is_from_current_user: Bool
    var sent_at_text: String
    var created_at: String
    var updated_at: String
}

actor SupabasePetBackend: PetBackend {
    private let client: SupabaseRESTClient
    private let realtimeConfig: SupabaseConfig

    private let auth: SupabaseAuthClient
    private var lastCloudPayload: BootstrapPayload?
    private var sessionUserID: UUID?

    fileprivate init(config: SupabaseConfig) {
        self.realtimeConfig = config
        let auth = SupabaseAuthClient(config: config)
        self.auth = auth
        self.client = SupabaseRESTClient(config: config, auth: auth)
    }

    func bootstrap() async -> BootstrapPayload {
        await runCloud(
            primary: {
                try await loadBootstrapPayload()
            }
        )
    }

    func signIn(with draft: SignInDraft) async -> BootstrapPayload {
        await runCloud(primary: {
            guard let userID = try await auth.signIn(draft) else {
                var payload = makeSignedOutPayload()
                payload.backendMessage = "注册申请已提交。请到邮箱确认邮件，再切换到登录。"
                return payload
            }
            saveSessionUserID(userID)
            if let user = try await loadUser(userID: userID) {
                return try await loadBootstrapPayload(for: user)
            }
            let user = UserAccount(id: userID,
                displayName: draft.displayName.isEmpty ? "新用户" : draft.displayName,
                phone: draft.phone, city: draft.city,
                bio: "在 PetLife 记录宠物成长。", avatarSymbol: "person.crop.circle.fill")
            try await saveUser(user)
            return try await loadBootstrapPayload(for: user)
        })
    }

    func signOut() async -> BootstrapPayload {
        await auth.signOut()
        saveSessionUserID(nil)
        let payload = makeSignedOutPayload()
        lastCloudPayload = payload
        return payload
    }

    func addPet(_ draft: PetDraft, owner: UserAccount) async -> BootstrapPayload {
        await runCloud(
            primary: {
                guard let userID = loadSessionUserID() else {
                    return makeSignedOutPayload()
                }

                let pet = PetProfile(
                    id: UUID(),
                    name: draft.name,
                    species: draft.species,
                    breed: draft.breed,
                    ageText: draft.ageText,
                    city: draft.city,
                    bio: draft.bio,
                    interests: draft.interests,
                    lookingFor: draft.lookingFor,
                    accent: draft.accent,
                    ownerName: owner.displayName,
                    vaccinated: draft.vaccinated,
                    ownerUserID: userID,
                    isDiscoverable: draft.isDiscoverable
                )
                try await client.insert(makeOwnedPetRow(pet, userID: userID, createdAt: Date()), into: SupabaseTable.ownedPets)
                return try await loadBootstrapPayload()
            }
        )
    }

    func addMemory(_ draft: MemoryDraft) async -> BootstrapPayload {
        await runCloud(
            primary: {
                guard let userID = loadSessionUserID() else {
                    return makeSignedOutPayload()
                }

                let memory = HolidayMemory(
                    id: draft.id,
                    title: draft.title,
                    subtitle: draft.subtitle,
                    dateText: draft.dateText,
                    ornament: draft.ornament,
                    accent: draft.accent,
                    story: draft.story,
                    mediaKind: draft.mediaKind,
                    mediaAssetPath: draft.mediaAssetPath ?? draft.photoAssetPath,
                    mediaDisplayName: draft.mediaDisplayName,
                    notes: [],
                    photoAssetPath: draft.photoAssetPath,
                    audioAssetPath: draft.audioAssetPath,
                    audioDisplayName: draft.audioDisplayName
                )

                let photoStoragePath = try await uploadMemoryAsset(
                    relativePath: draft.photoAssetPath,
                    userID: userID,
                    memoryID: memory.id,
                    fileStem: "photo",
                    fallbackExtension: "jpg"
                )
                let audioStoragePath = try await uploadMemoryAsset(
                    relativePath: draft.audioAssetPath,
                    userID: userID,
                    memoryID: memory.id,
                    fileStem: "audio",
                    fallbackExtension: "m4a"
                )

                try await client.insert(
                    makeMemoryRow(
                        memory,
                        userID: userID,
                        createdAt: Date(),
                        photoStoragePath: photoStoragePath,
                        audioStoragePath: audioStoragePath
                    ),
                    into: SupabaseTable.holidayMemories
                )
                return try await loadBootstrapPayload()
            }
        )
    }

    func createVideo(_ draft: VideoDraft, selectedAssetCount: Int) async -> BootstrapPayload {
        await runCloud(
            primary: {
                guard let userID = loadSessionUserID() else {
                    return makeSignedOutPayload()
                }

                let video = UploadVideo(
                    id: UUID(),
                    title: draft.title,
                    duration: draft.duration,
                    caption: draft.caption,
                    tags: draft.tags,
                    status: selectedAssetCount == 0 ? .draft : .uploading,
                    selectedAssetCount: selectedAssetCount,
                    accent: draft.accent,
                    publishDateText: selectedAssetCount == 0 ? "草稿" : "刚刚"
                )
                try await client.insert(makeVideoRow(video, userID: userID, createdAt: Date()), into: SupabaseTable.uploadVideos)
                return try await loadBootstrapPayload()
            }
        )
    }

    func createPost(_ draft: PostDraft, user: UserAccount, petName: String) async -> BootstrapPayload {
        await runCloud(
            primary: {
                guard let userID = loadSessionUserID() else {
                    return makeSignedOutPayload()
                }

                let payload = try await loadBootstrapPayload()
                let relatedPetID = payload.ownedPets.first(where: { $0.name == petName })?.id
                let post = FeedPost(
                    id: draft.id,
                    relatedPetID: relatedPetID,
                    authorName: user.displayName,
                    petName: petName,
                    topic: draft.topic,
                    city: draft.city,
                    content: draft.content,
                    tags: draft.tags,
                    likes: 0,
                    comments: [],
                    likedByCurrentUser: false,
                    createdAtText: "刚刚"
                )
                try await client.insert(makeFeedPostRow(post, userID: userID, createdAt: Date()), into: SupabaseTable.feedPosts)
                return try await loadBootstrapPayload()
            }
        )
    }

    func toggleLike(postID: UUID) async -> BootstrapPayload {
        await runCloud(
            primary: {
                guard let userID = loadSessionUserID() else {
                    return makeSignedOutPayload()
                }

                guard var row = try await loadPostRow(postID: postID, userID: userID) else {
                    return try await loadBootstrapPayload()
                }

                row.liked_by_current_user.toggle()
                row.likes = max(0, row.likes + (row.liked_by_current_user ? 1 : -1))
                row.updated_at = nowString()
                try await client.update(row, table: SupabaseTable.feedPosts, filters: [eq("id", postID), eq("user_id", userID)])
                return try await loadBootstrapPayload()
            }
        )
    }

    func addComment(postID: UUID, text: String, userName: String) async -> BootstrapPayload {
        await runCloud(
            primary: {
                guard let userID = loadSessionUserID() else {
                    return makeSignedOutPayload()
                }

                guard try await loadPostRow(postID: postID, userID: userID) != nil else {
                    return try await loadBootstrapPayload()
                }

                let comment = PostComment(
                    id: UUID(),
                    authorName: userName,
                    body: text,
                    createdAtText: "刚刚"
                )
                try await client.insert(
                    makePostCommentRow(comment, postID: postID, userID: userID, createdAt: Date()),
                    into: SupabaseTable.postComments
                )
                return try await loadBootstrapPayload()
            }
        )
    }

    func openChat(for pet: PetProfile) async -> (BootstrapPayload, UUID) {
        await runCloud(primary: {
            guard let userID = loadSessionUserID(), let recipient = pet.ownerUserID,
                  recipient != userID, pet.isDiscoverable else {
                throw SupabaseError(message: "此档案是示例或尚未开放交友，无法发起真实聊天。")
            }
            let existing = try await client.select(ChatThreadRow.self, from: SupabaseTable.chatThreads,
                filters: [eq("related_pet_id", pet.id)])
            if let row = existing.first { return (try await loadBootstrapPayload(), row.id) }
            let initiator = try await loadUser(userID: userID)?.displayName ?? "PetLife"
            let thread = ChatThread(id: UUID(), relatedPetID: pet.id,
                title: "\(initiator) ↔ \(pet.ownerName) · \(pet.name)", subtitle: "新的聊天已开启",
                unreadCount: 0, accent: pet.accent, messages: [])
            var row = makeChatThreadRow(thread, userID: userID, createdAt: Date())
            row.participant_id = recipient
            do { try await client.insert(row, into: SupabaseTable.chatThreads) }
            catch {
                // A second tap or device can create the same conversation concurrently.
                if let winner = try await client.select(ChatThreadRow.self, from: SupabaseTable.chatThreads,
                    filters: [eq("related_pet_id", pet.id)]).first {
                    return (try await loadBootstrapPayload(), winner.id)
                }
                throw error
            }
            return (try await loadBootstrapPayload(), thread.id)
        })
    }

    func sendMessage(threadID: UUID, text: String, messageID: UUID) async -> BootstrapPayload {
        await runCloud(primary: {
            guard let userID = loadSessionUserID(),
                  let thread = try await loadThreadRow(threadID: threadID, userID: userID),
                  thread.participant_id != nil else {
                throw SupabaseError(message: "此会话尚未连接真实接收方，请从交友档案重新发起。")
            }
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, trimmed.count <= 4000 else {
                throw SupabaseError(message: "消息需要包含 1 至 4000 个字符。")
            }
            let message = ChatMessage(id: messageID, text: trimmed, isFromCurrentUser: true, sentAtText: "刚刚")
            try await client.upsert(makeChatMessageRow(message, threadID: threadID, userID: userID, createdAt: Date()),
                table: SupabaseTable.chatMessages, conflict: "id", ignoreDuplicates: true)
            return try await loadBootstrapPayload()
        })
    }

    func setPetDiscoverable(_ petID: UUID, enabled: Bool) async -> BootstrapPayload {
        await runCloud(primary: {
            guard let userID = loadSessionUserID() else { return makeSignedOutPayload() }
            try await client.update(["is_discoverable": enabled], table: SupabaseTable.ownedPets,
                filters: [eq("id", petID), eq("user_id", userID)])
            return try await loadBootstrapPayload()
        })
    }

    func refreshChats() async throws -> [ChatThread] {
        guard let userID = loadSessionUserID() else { return [] }
        return try await loadChats(userID: userID)
    }

    func markRead(threadID: UUID, through: Date) async throws {
        guard let userID = loadSessionUserID() else { return }
        try await client.upsert(ChatReadRow(thread_id: threadID, user_id: userID,
            last_read_at: SupabaseDateCodec.string(from: through)), table: "chat_reads",
            conflict: "thread_id,user_id")
    }

    private func loadChats(userID: UUID) async throws -> [ChatThread] {
        let rows = try await client.select(ChatThreadRow.self, from: SupabaseTable.chatThreads)
        var result: [ChatThread] = []
        for row in rows {
            async let messages = client.selectAll(ChatMessageRow.self, from: SupabaseTable.chatMessages,
                filters: [eq("thread_id", row.id), URLQueryItem(name: "order", value: "created_at.asc,id.asc")])
            async let receipts = client.select(ChatReadRow.self, from: "chat_reads", filters: [eq("thread_id", row.id)])
            let reads = try await receipts
            let mine = reads.first { $0.user_id == userID }.map { createdAt(from: $0.last_read_at) } ?? .distantPast
            let peer = reads.first { $0.user_id != userID }.map { createdAt(from: $0.last_read_at) } ?? .distantPast
            let sorted = try await messages.sorted {
                if $0.created_at == $1.created_at { return $0.id.uuidString < $1.id.uuidString }
                return createdAt(from: $0.created_at) < createdAt(from: $1.created_at)
            }
            var thread = decodeThread(row)
            thread.messages = sorted.map { message in
                ChatMessage(id: message.id, text: message.text, isFromCurrentUser: message.user_id == userID,
                    sentAtText: message.created_at, sentAt: createdAt(from: message.created_at),
                    isRead: message.user_id == userID && createdAt(from: message.created_at) <= peer)
            }
            thread.subtitle = thread.messages.last?.text ?? "新的聊天已开启"
            thread.unreadCount = sorted.filter { $0.user_id != userID && createdAt(from: $0.created_at) > mine }.count
            if row.user_id != userID { thread.title = "宠物交友 · \(row.title)" }
            result.append(thread)
        }
        return result.sorted { ($0.messages.last?.sentAt ?? .distantPast) > ($1.messages.last?.sentAt ?? .distantPast) }
    }

    private func failurePayload(_ error: Error) -> BootstrapPayload {
        var payload = lastCloudPayload ?? makeSignedOutPayload()
        payload.backendMessage = error.localizedDescription
        return payload
    }

    private func runCloud(primary: () async throws -> BootstrapPayload) async -> BootstrapPayload {
        do {
            let payload = try await primary()
            lastCloudPayload = payload
            return payload
        } catch {
            return failurePayload(error)
        }
    }

    private func runCloud(primary: () async throws -> (BootstrapPayload, UUID)) async -> (BootstrapPayload, UUID) {
        do {
            let result = try await primary()
            lastCloudPayload = result.0
            return result
        } catch {
            return (failurePayload(error), UUID())
        }
    }

    private func loadBootstrapPayload() async throws -> BootstrapPayload {
        guard let activeUserID = try await auth.restore() else {
            saveSessionUserID(nil)
            return makeSignedOutPayload()
        }
        saveSessionUserID(activeUserID)

        guard let user = try await loadUser(userID: activeUserID) else {
            saveSessionUserID(nil)
            return makeSignedOutPayload()
        }

        return try await loadBootstrapPayload(for: user)
    }

    private func loadBootstrapPayload(for user: UserAccount) async throws -> BootstrapPayload {
        let userID = user.id

        async let petRows = client.select(OwnedPetRow.self, from: SupabaseTable.ownedPets, filters: [eq("user_id", userID)])
        async let memoryRows = client.select(HolidayMemoryRow.self, from: SupabaseTable.holidayMemories, filters: [eq("user_id", userID)])
        async let videoRows = client.select(UploadVideoRow.self, from: SupabaseTable.uploadVideos, filters: [eq("user_id", userID)])
        async let postRows = client.select(FeedPostRow.self, from: SupabaseTable.feedPosts, filters: [eq("user_id", userID)])
        async let commentRows = client.select(PostCommentRow.self, from: SupabaseTable.postComments, filters: [eq("user_id", userID)])
        async let liveChats = loadChats(userID: userID)
        async let directoryRows = client.select(OwnedPetRow.self, from: SupabaseTable.ownedPets,
            filters: [URLQueryItem(name: "is_discoverable", value: "eq.true"), URLQueryItem(name: "user_id", value: "neq.\(userID.uuidString)")])

        let pets = try await petRows
            .sorted { createdAt(from: $0.created_at) > createdAt(from: $1.created_at) }
            .map(decodeOwnedPet)

        let memories = try await buildMemories(from: memoryRows)
        let videos = try await videoRows
            .sorted { createdAt(from: $0.created_at) > createdAt(from: $1.created_at) }
            .map(decodeVideo)

        let sortedComments = try await commentRows
            .sorted { createdAt(from: $0.created_at) < createdAt(from: $1.created_at) }
        var commentsByPost: [UUID: [PostComment]] = [:]
        for row in sortedComments {
            commentsByPost[row.post_id, default: []].append(decodeComment(row))
        }

        let posts = try await postRows
            .sorted { createdAt(from: $0.created_at) > createdAt(from: $1.created_at) }
            .map { row in
                var post = decodeFeedPost(row)
                post.comments = commentsByPost[row.id] ?? []
                return post
            }

        return BootstrapPayload(
            currentUser: user,
            ownedPets: pets,
            discoverPets: try await directoryRows.map(decodeOwnedPet),
            memories: memories,
            uploadVideos: videos,
            feedPosts: posts,
            chatThreads: try await liveChats
        )
    }

    private func buildMemories(from rows: [HolidayMemoryRow]) async throws -> [HolidayMemory] {
        var memories: [HolidayMemory] = []
        for row in rows.sorted(by: { createdAt(from: $0.created_at) > createdAt(from: $1.created_at) }) {
            memories.append(try await decodeMemory(row))
        }
        return memories
    }

    private func loadUser(userID: UUID) async throws -> UserAccount? {
        guard let row = try await loadUserRow(userID: userID) else {
            return nil
        }
        return decodeUser(row)
    }

    private func loadUserRow(userID: UUID) async throws -> UserRow? {
        try await client.select(
            UserRow.self,
            from: SupabaseTable.userAccounts,
            filters: [eq("id", userID)],
            limit: 1
        ).first
    }

    private func loadPostRow(postID: UUID, userID: UUID) async throws -> FeedPostRow? {
        try await client.select(
            FeedPostRow.self,
            from: SupabaseTable.feedPosts,
            filters: [eq("id", postID), eq("user_id", userID)],
            limit: 1
        ).first
    }

    private func loadThreadRow(threadID: UUID, userID: UUID) async throws -> ChatThreadRow? {
        try await client.select(
            ChatThreadRow.self,
            from: SupabaseTable.chatThreads,
            filters: [eq("id", threadID)],
            limit: 1
        ).first
    }

    private func saveUser(_ user: UserAccount) async throws {
        let timestamp = nowString()
        let row = UserRow(
            id: user.id,
            display_name: user.displayName,
            phone: user.phone,
            city: user.city,
            bio: user.bio,
            avatar_symbol: user.avatarSymbol,
            created_at: timestamp,
            updated_at: timestamp
        )
        try await client.insert(row, into: SupabaseTable.userAccounts)
    }

    private func loadSessionUserID() -> UUID? {
        sessionUserID
    }

    private func saveSessionUserID(_ userID: UUID?) {
        sessionUserID = userID
        LocalSessionStore.saveActiveUserID(userID)
    }

    private func decodeUser(_ row: UserRow) -> UserAccount {
        UserAccount(
            id: row.id,
            displayName: row.display_name,
            phone: row.phone,
            city: row.city,
            bio: row.bio,
            avatarSymbol: row.avatar_symbol
        )
    }

    private func decodeOwnedPet(_ row: OwnedPetRow) -> PetProfile {
        PetProfile(
            id: row.id,
            name: row.name,
            species: row.species,
            breed: row.breed,
            ageText: row.age_text,
            city: row.city,
            bio: row.bio,
            interests: row.interests,
            lookingFor: row.looking_for,
            accent: AccentToken(rawValue: row.accent) ?? .ember,
            ownerName: row.owner_name,
            vaccinated: row.vaccinated,
            ownerUserID: row.user_id,
            isDiscoverable: row.is_discoverable
        )
    }

    private func decodeMemory(_ row: HolidayMemoryRow) async throws -> HolidayMemory {
        HolidayMemory(
            id: row.id,
            title: row.title,
            subtitle: row.subtitle,
            dateText: row.date_text,
            ornament: row.ornament,
            accent: AccentToken(rawValue: row.accent) ?? .pine,
            story: row.story,
            mediaKind: .image,
            mediaAssetPath: await cacheAssetIfNeeded(storagePath: row.photo_storage_path, fallbackExtension: "jpg"),
            mediaDisplayName: nil,
            notes: [],
            photoAssetPath: await cacheAssetIfNeeded(storagePath: row.photo_storage_path, fallbackExtension: "jpg"),
            audioAssetPath: await cacheAssetIfNeeded(storagePath: row.audio_storage_path, fallbackExtension: "m4a"),
            audioDisplayName: row.audio_display_name
        )
    }

    private func decodeVideo(_ row: UploadVideoRow) -> UploadVideo {
        UploadVideo(
            id: row.id,
            title: row.title,
            duration: row.duration,
            caption: row.caption,
            tags: row.tags,
            status: UploadStatus(rawValue: row.status) ?? .draft,
            selectedAssetCount: row.selected_asset_count,
            accent: AccentToken(rawValue: row.accent) ?? .peach,
            publishDateText: row.publish_date_text
        )
    }

    private func decodeFeedPost(_ row: FeedPostRow) -> FeedPost {
        FeedPost(
            id: row.id,
            relatedPetID: row.related_pet_id,
            authorName: row.author_name,
            petName: row.pet_name,
            topic: row.topic,
            city: row.city,
            content: row.content,
            tags: row.tags,
            likes: row.likes,
            comments: [],
            likedByCurrentUser: row.liked_by_current_user,
            createdAtText: row.created_at_text
        )
    }

    private func decodeComment(_ row: PostCommentRow) -> PostComment {
        PostComment(
            id: row.id,
            authorName: row.author_name,
            body: row.body,
            createdAtText: row.created_at_text
        )
    }

    private func decodeThread(_ row: ChatThreadRow) -> ChatThread {
        ChatThread(
            id: row.id,
            relatedPetID: row.related_pet_id,
            title: row.title,
            subtitle: row.subtitle,
            unreadCount: row.unread_count,
            accent: AccentToken(rawValue: row.accent) ?? .plum,
            messages: []
        )
    }

    private func decodeMessage(_ row: ChatMessageRow) -> ChatMessage {
        ChatMessage(
            id: row.id,
            text: row.text,
            isFromCurrentUser: row.is_from_current_user,
            sentAtText: row.sent_at_text
        )
    }

    private func makeOwnedPetRow(_ pet: PetProfile, userID: UUID, createdAt: Date) -> OwnedPetRow {
        let timestamp = SupabaseDateCodec.string(from: createdAt)
        return OwnedPetRow(
            id: pet.id,
            user_id: userID,
            name: pet.name,
            species: pet.species,
            breed: pet.breed,
            age_text: pet.ageText,
            city: pet.city,
            bio: pet.bio,
            interests: pet.interests,
            looking_for: pet.lookingFor,
            accent: pet.accent.rawValue,
            owner_name: pet.ownerName,
            vaccinated: pet.vaccinated,
            is_discoverable: pet.isDiscoverable,
            created_at: timestamp,
            updated_at: timestamp
        )
    }

    private func makeMemoryRow(
        _ memory: HolidayMemory,
        userID: UUID,
        createdAt: Date,
        photoStoragePath: String?,
        audioStoragePath: String?
    ) -> HolidayMemoryRow {
        let timestamp = SupabaseDateCodec.string(from: createdAt)
        return HolidayMemoryRow(
            id: memory.id,
            user_id: userID,
            title: memory.title,
            subtitle: memory.subtitle,
            date_text: memory.dateText,
            ornament: memory.ornament,
            accent: memory.accent.rawValue,
            story: memory.story,
            photo_storage_path: photoStoragePath,
            audio_storage_path: audioStoragePath,
            audio_display_name: memory.audioDisplayName,
            created_at: timestamp,
            updated_at: timestamp
        )
    }

    private func makeVideoRow(_ video: UploadVideo, userID: UUID, createdAt: Date) -> UploadVideoRow {
        let timestamp = SupabaseDateCodec.string(from: createdAt)
        return UploadVideoRow(
            id: video.id,
            user_id: userID,
            title: video.title,
            duration: video.duration,
            caption: video.caption,
            tags: video.tags,
            status: video.status.rawValue,
            selected_asset_count: video.selectedAssetCount,
            accent: video.accent.rawValue,
            publish_date_text: video.publishDateText,
            created_at: timestamp,
            updated_at: timestamp
        )
    }

    private func makeFeedPostRow(_ post: FeedPost, userID: UUID, createdAt: Date) -> FeedPostRow {
        let timestamp = SupabaseDateCodec.string(from: createdAt)
        return FeedPostRow(
            id: post.id,
            user_id: userID,
            related_pet_id: post.relatedPetID,
            author_name: post.authorName,
            pet_name: post.petName,
            topic: post.topic,
            city: post.city,
            content: post.content,
            tags: post.tags,
            likes: post.likes,
            liked_by_current_user: post.likedByCurrentUser,
            created_at_text: post.createdAtText,
            created_at: timestamp,
            updated_at: timestamp
        )
    }

    private func makePostCommentRow(
        _ comment: PostComment,
        postID: UUID,
        userID: UUID,
        createdAt: Date
    ) -> PostCommentRow {
        let timestamp = SupabaseDateCodec.string(from: createdAt)
        return PostCommentRow(
            id: comment.id,
            user_id: userID,
            post_id: postID,
            author_name: comment.authorName,
            body: comment.body,
            created_at_text: comment.createdAtText,
            created_at: timestamp,
            updated_at: timestamp
        )
    }

    private func makeChatThreadRow(_ thread: ChatThread, userID: UUID, createdAt: Date) -> ChatThreadRow {
        let timestamp = SupabaseDateCodec.string(from: createdAt)
        return ChatThreadRow(
            id: thread.id,
            user_id: userID,
            related_pet_id: thread.relatedPetID,
            title: thread.title,
            subtitle: thread.subtitle,
            unread_count: thread.unreadCount,
            accent: thread.accent.rawValue,
            created_at: timestamp,
            updated_at: timestamp
        )
    }

    private func makeChatMessageRow(
        _ message: ChatMessage,
        threadID: UUID,
        userID: UUID,
        createdAt: Date
    ) -> ChatMessageRow {
        let timestamp = SupabaseDateCodec.string(from: createdAt)
        return ChatMessageRow(
            id: message.id,
            user_id: userID,
            thread_id: threadID,
            text: message.text,
            is_from_current_user: message.isFromCurrentUser,
            sent_at_text: message.sentAtText,
            created_at: timestamp,
            updated_at: timestamp
        )
    }

    private func makeSignedOutPayload() -> BootstrapPayload {
        BootstrapPayload(
            currentUser: nil,
            ownedPets: [],
            discoverPets: [],
            memories: [],
            uploadVideos: [],
            feedPosts: [],
            chatThreads: []
        )
    }

    private func eq(_ key: String, _ value: UUID) -> URLQueryItem {
        URLQueryItem(name: key, value: "eq.\(value.uuidString.lowercased())")
    }

    private func nowString() -> String {
        SupabaseDateCodec.string(from: Date())
    }

    private func createdAt(from value: String) -> Date {
        SupabaseDateCodec.date(from: value)
    }

    private func uploadMemoryAsset(
        relativePath: String?,
        userID: UUID,
        memoryID: UUID,
        fileStem: String,
        fallbackExtension: String
    ) async throws -> String? {
        guard
            let localURL = MemoryAssetStore.url(for: relativePath),
            FileManager.default.fileExists(atPath: localURL.path)
        else {
            return nil
        }

        let fileExtension = localURL.pathExtension.isEmpty ? fallbackExtension : localURL.pathExtension.lowercased()
        let storagePath = "users/\(userID.uuidString.lowercased())/memories/\(memoryID.uuidString.lowercased())/\(fileStem).\(fileExtension)"
        let data = try Data(contentsOf: localURL)
        try await client.uploadObject(data: data, path: storagePath, contentType: contentType(forExtension: fileExtension))
        return storagePath
    }

    private func cacheAssetIfNeeded(storagePath: String?, fallbackExtension: String) async -> String? {
        guard let storagePath else {
            return nil
        }

        let rawFileName = storagePath.replacingOccurrences(of: "/", with: "_")
        let fileName = rawFileName.contains(".") ? rawFileName : "\(rawFileName).\(fallbackExtension)"

        if let cachedPath = MemoryAssetStore.existingRelativePath(fileName: fileName) {
            return cachedPath
        }

        do {
            let data = try await client.downloadObject(path: storagePath)
            return try MemoryAssetStore.saveDownloadedData(data, fileName: fileName)
        } catch {
            print("[PetLife] Failed to cache Supabase asset \(storagePath): \(error)")
            return nil
        }
    }

    private func contentType(forExtension fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "heic":
            return "image/heic"
        case "webp":
            return "image/webp"
        case "m4a":
            return "audio/m4a"
        case "aac":
            return "audio/aac"
        case "mp3":
            return "audio/mpeg"
        case "wav":
            return "audio/wav"
        default:
            return "application/octet-stream"
        }
    }
}

@MainActor
@Observable
final class AppModel {
    private let backend: any PetBackend
    private(set) var postMediaAttachments: [UUID: PostMediaAttachment] = [:]
    private var memoryMediaAttachments: [UUID: PostMediaAttachment] = [:]

    var backendMessage: String?
    var isLoaded = false
    var isBusy = false
    var currentUser: UserAccount?
    var ownedPets: [PetProfile] = []
    var discoverPets: [PetProfile] = []
    var holidayMemories: [HolidayMemory] = []
    var uploadVideos: [UploadVideo] = []
    var feedPosts: [FeedPost] = []
    var chatThreads: [ChatThread] = []

    init(backend: (any PetBackend)? = nil) {
        self.backend = backend ?? PetBackendFactory.makeDefaultBackend()
    }

    var isAuthenticated: Bool {
        currentUser != nil
    }

    var publishedVideos: [UploadVideo] {
        uploadVideos.filter { $0.status == .published || $0.status == .reviewing }
    }

    var pendingVideos: [UploadVideo] {
        uploadVideos.filter { $0.status == .draft || $0.status == .uploading }
    }

    var myPosts: [FeedPost] {
        guard let currentUser else { return [] }
        return feedPosts.filter { $0.authorName == currentUser.displayName }
    }

    func loadIfNeeded() async {
        guard !isLoaded else { return }
        isBusy = true
        apply(await backend.bootstrap())
        isBusy = false
        isLoaded = true
    }

    func signIn(_ draft: SignInDraft) async {
        isBusy = true
        apply(await backend.signIn(with: draft))
        isBusy = false
    }

    func signOut() async {
        isBusy = true
        apply(await backend.signOut())
        isBusy = false
    }

    func addPet(_ draft: PetDraft) async {
        guard let currentUser else { return }
        isBusy = true
        apply(await backend.addPet(draft, owner: currentUser))
        isBusy = false
    }

    func setPetDiscoverable(_ petID: UUID, enabled: Bool) async {
        apply(await backend.setPetDiscoverable(petID, enabled: enabled))
    }

    func addMemory(_ draft: MemoryDraft) async {
        if let mediaAssetPath = draft.mediaAssetPath ?? draft.photoAssetPath {
            memoryMediaAttachments[draft.id] = PostMediaAttachment(
                kind: draft.mediaKind,
                localAssetPath: mediaAssetPath,
                displayName: draft.mediaDisplayName ?? draft.mediaKind.rawValue
            )
        }
        isBusy = true
        apply(await backend.addMemory(draft))
        isBusy = false
    }

    func addMemoryNote(memoryID: UUID, text: String) {
        guard let index = holidayMemories.firstIndex(where: { $0.id == memoryID }) else {
            return
        }

        let note = MemoryNote(
            id: UUID(),
            body: text,
            createdAtText: "刚刚"
        )
        holidayMemories[index].notes.insert(note, at: 0)
    }

    func createVideo(_ draft: VideoDraft, selectedAssetCount: Int) async {
        isBusy = true
        apply(await backend.createVideo(draft, selectedAssetCount: selectedAssetCount))
        isBusy = false
    }

    func createPost(_ draft: PostDraft, petName: String) async {
        guard let currentUser else { return }
        if let attachment = draft.mediaAttachment {
            postMediaAttachments[draft.id] = attachment
        }
        isBusy = true
        apply(await backend.createPost(draft, user: currentUser, petName: petName))
        isBusy = false
    }

    func toggleLike(postID: UUID) async {
        apply(await backend.toggleLike(postID: postID))
    }

    func addComment(postID: UUID, text: String) async {
        guard let currentUser else { return }
        apply(await backend.addComment(postID: postID, text: text, userName: currentUser.displayName))
    }

    func openChat(for pet: PetProfile) async -> UUID? {
        let result = await backend.openChat(for: pet)
        apply(result.0)
        return result.0.backendMessage == nil ? result.1 : nil
    }

    var chatConnection = "正在连接"
    private var refreshingChats = false
    private var chatRefreshRequested = false
    var chatSendError: String?

    func sendMessage(threadID: UUID, text: String, messageID: UUID = UUID()) async -> Bool {
        guard let identity = currentUser?.id else { return false }
        let payload = await backend.sendMessage(threadID: threadID, text: text, messageID: messageID)
        guard currentUser?.id == identity else { return false }
        chatSendError = payload.backendMessage
        guard payload.backendMessage == nil else { return false }
        apply(payload)
        return true
    }

    func refreshChats() async {
        if refreshingChats { chatRefreshRequested = true; return }
        guard let identity = currentUser?.id else { return }
        refreshingChats = true
        chatRefreshRequested = false
        do {
            let threads = try await backend.refreshChats()
            if currentUser?.id == identity { chatThreads = threads }
        } catch { chatConnection = "连接中断，正在重连" }
        refreshingChats = false
        if chatRefreshRequested && !Task.isCancelled { await refreshChats() }
    }

    func refreshContent() async {
        guard let identity = currentUser?.id else { return }
        let payload = await backend.bootstrap()
        guard currentUser?.id == identity else { return }
        apply(payload)
    }

    func markChatRead(_ threadID: UUID) async {
        guard let lastReceived = thread(for: threadID)?.messages.last?.sentAt else { return }
        do {
            try await backend.markRead(threadID: threadID, through: lastReceived)
            if let index = chatThreads.firstIndex(where: { $0.id == threadID }) { chatThreads[index].unreadCount = 0 }
        } catch { /* Retry when the next refresh or foreground activation arrives. */ }
    }

    func runChatSync() async {
        guard currentUser != nil else { return }
        if backend is InMemoryPetBackend { chatConnection = "示例会话"; return }
        await withTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor in
                for await event in await self.backend.chatEvents() {
                    guard !Task.isCancelled else { break }
                    switch event {
                    case .connected: self.chatConnection = "实时消息已连接"
                    case .reconnecting: self.chatConnection = "连接中断，正在重连"
                    case .changed: break
                    }
                    await self.refreshChats()
                }
            }
            group.addTask { @MainActor in
                while !Task.isCancelled {
                    await self.refreshChats()
                    do { try await Task.sleep(for: .seconds(15)) } catch { break }
                }
            }
            await group.waitForAll()
        }
    }

    func thread(for id: UUID) -> ChatThread? {
        chatThreads.first(where: { $0.id == id })
    }

    func post(for id: UUID) -> FeedPost? {
        feedPosts.first(where: { $0.id == id })
    }

    func memory(for id: UUID) -> HolidayMemory? {
        holidayMemories.first(where: { $0.id == id })
    }

    func mediaAttachment(for postID: UUID) -> PostMediaAttachment? {
        postMediaAttachments[postID]
    }

    private func apply(_ payload: BootstrapPayload) {
        backendMessage = payload.backendMessage
        currentUser = payload.currentUser
        ownedPets = payload.ownedPets
        discoverPets = payload.discoverPets
        holidayMemories = payload.memories
        for index in holidayMemories.indices {
            guard let attachment = memoryMediaAttachments[holidayMemories[index].id] else {
                continue
            }

            holidayMemories[index].mediaKind = attachment.kind
            holidayMemories[index].mediaAssetPath = attachment.localAssetPath
            holidayMemories[index].mediaDisplayName = attachment.displayName
            if attachment.kind == .image {
                holidayMemories[index].photoAssetPath = attachment.localAssetPath
            }
        }
        uploadVideos = payload.uploadVideos
        feedPosts = payload.feedPosts
        chatThreads = payload.chatThreads
        let validPostIDs = Set(payload.feedPosts.map(\.id))
        postMediaAttachments = postMediaAttachments.filter { validPostIDs.contains($0.key) }
    }
}

// Supabase's documented JSON v1 protocol; only RLS-authorized Postgres changes are subscribed.
extension SupabasePetBackend {
    func chatEvents() async -> AsyncStream<ChatEvent> {
        let config = realtimeConfig
        let auth = auth
        return AsyncStream { continuation in
            let worker = Task {
                var attempt = 0
                while !Task.isCancelled {
                    var components = URLComponents(url: config.projectURL, resolvingAgainstBaseURL: false)!
                    components.scheme = "wss"
                    components.path = "/realtime/v1/websocket"
                    components.queryItems = [URLQueryItem(name: "apikey", value: config.anonKey), URLQueryItem(name: "vsn", value: "1.0.0")]
                    let socket = URLSession.shared.webSocketTask(with: components.url!)
                    socket.resume()
                    do {
                        let token = try await auth.accessToken()
                        let join: [String: Any] = ["topic": "realtime:petlife-chats", "event": "phx_join", "ref": "1", "join_ref": "1",
                            "payload": ["access_token": token, "config": ["postgres_changes":
                                ["chat_threads", "chat_messages", "chat_reads"].map { ["event": "*", "schema": "public", "table": $0] }]]]
                        try await socket.send(.string(String(decoding: JSONSerialization.data(withJSONObject: join), as: UTF8.self)))
                        try await withThrowingTaskGroup(of: Void.self) { group in
                            defer { group.cancelAll(); socket.cancel(with: .goingAway, reason: nil) }
                            group.addTask {
                                while !Task.isCancelled {
                                    let frame = try await socket.receive()
                                    let data: Data
                                    switch frame {
                                    case .string(let string): data = Data(string.utf8)
                                    case .data(let bytes): data = bytes
                                    @unknown default: continue
                                    }
                                    guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                                          let event = object["event"] as? String else { continue }
                                    if event == "postgres_changes" { continuation.yield(.changed) }
                                    if event == "phx_reply", object["ref"] as? String == "1" {
                                        let payload = object["payload"] as? [String: Any]
                                        guard payload?["status"] as? String == "ok" else {
                                            throw SupabaseError(message: "实时连接失败")
                                        }
                                        continuation.yield(.connected)
                                    }
                                    if event == "phx_error" || event == "phx_close" { throw URLError(.networkConnectionLost) }
                                }
                            }
                            group.addTask {
                                while !Task.isCancelled {
                                    try await Task.sleep(for: .seconds(25))
                                    let heartbeat: [String: Any] = ["topic": "phoenix", "event": "heartbeat", "payload": [:], "ref": UUID().uuidString]
                                    try await socket.send(.string(String(decoding: JSONSerialization.data(withJSONObject: heartbeat), as: UTF8.self)))
                                    let refresh: [String: Any] = ["topic": "realtime:petlife-chats", "event": "access_token",
                                        "payload": ["access_token": try await auth.accessToken()], "ref": UUID().uuidString]
                                    try await socket.send(.string(String(decoding: JSONSerialization.data(withJSONObject: refresh), as: UTF8.self)))
                                }
                            }
                            try await group.next()
                        }
                        attempt = 0
                    } catch {
                        socket.cancel(with: .goingAway, reason: nil)
                        guard !Task.isCancelled else { break }
                        print("[PetLife] Realtime reconnect: \(error.localizedDescription)")
                        continuation.yield(.reconnecting)
                        attempt = min(attempt + 1, 5)
                        do { try await Task.sleep(for: .seconds(Double(1 << attempt))) } catch { break }
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in worker.cancel() }
        }
    }
}
