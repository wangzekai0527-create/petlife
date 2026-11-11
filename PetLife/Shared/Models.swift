import Foundation

enum AppTab: Hashable {
    case home
    case tree
    case services
    case match
    case profile
}

enum AccentToken: String, CaseIterable, Hashable, Sendable, Codable {
    case ember
    case pine
    case sky
    case peach
    case plum
    case mint
}

enum UploadStatus: String, CaseIterable, Hashable, Sendable, Codable {
    case draft = "待处理"
    case uploading = "上传中"
    case reviewing = "审核中"
    case published = "已发布"
}

enum PostMediaKind: String, CaseIterable, Hashable, Sendable, Codable {
    case image = "图片"
    case video = "视频"
}

struct PostMediaAttachment: Hashable, Sendable, Codable {
    var kind: PostMediaKind
    var localAssetPath: String
    var displayName: String
}

struct UserAccount: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    var displayName: String
    var phone: String
    var city: String
    var bio: String
    var avatarSymbol: String
}

struct HolidayMemory: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    var title: String
    var subtitle: String
    var dateText: String
    var ornament: String
    var accent: AccentToken
    var story: String
    var mediaKind: PostMediaKind
    var mediaAssetPath: String?
    var mediaDisplayName: String?
    var notes: [MemoryNote]
    var photoAssetPath: String?
    var audioAssetPath: String?
    var audioDisplayName: String?
}

struct MemoryNote: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    var body: String
    var createdAtText: String
}

struct UploadVideo: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    var title: String
    var duration: String
    var caption: String
    var tags: [String]
    var status: UploadStatus
    var selectedAssetCount: Int
    var accent: AccentToken
    var publishDateText: String
}

struct PetProfile: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    var name: String
    var species: String
    var breed: String
    var ageText: String
    var city: String
    var bio: String
    var interests: [String]
    var lookingFor: String
    var accent: AccentToken
    var ownerName: String
    var vaccinated: Bool
    var ownerUserID: UUID? = nil
    var isDiscoverable: Bool = false
}

struct PostComment: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    var authorName: String
    var body: String
    var createdAtText: String
}

struct FeedPost: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    var relatedPetID: UUID?
    var authorName: String
    var petName: String
    var topic: String
    var city: String
    var content: String
    var tags: [String]
    var likes: Int
    var comments: [PostComment]
    var likedByCurrentUser: Bool
    var createdAtText: String
}

struct ChatMessage: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    var text: String
    var isFromCurrentUser: Bool
    var sentAtText: String
    var sentAt: Date? = nil
    var isRead: Bool = false
}

struct ChatThread: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    var relatedPetID: UUID
    var title: String
    var subtitle: String
    var unreadCount: Int
    var accent: AccentToken
    var messages: [ChatMessage]
}

struct BootstrapPayload: Sendable, Codable {
    var backendMessage: String? = nil
    var currentUser: UserAccount?
    var ownedPets: [PetProfile]
    var discoverPets: [PetProfile]
    var memories: [HolidayMemory]
    var uploadVideos: [UploadVideo]
    var feedPosts: [FeedPost]
    var chatThreads: [ChatThread]
}

struct SignInDraft: Hashable, Sendable {
    var email: String = ""
    var password: String = ""
    var isRegistration: Bool = false
    var displayName: String = ""
    var phone: String = ""
    var city: String = "上海"
}

struct PetDraft: Hashable, Sendable {
    var name: String = ""
    var species: String = "狗狗"
    var breed: String = ""
    var ageText: String = ""
    var city: String = "上海"
    var bio: String = ""
    var interestsText: String = ""
    var lookingFor: String = "一起散步和玩耍"
    var accent: AccentToken = .ember
    var vaccinated: Bool = true
    var isDiscoverable: Bool = false

    var interests: [String] {
        interestsText
            .split(separator: " ")
            .map { String($0) }
            .filter { !$0.isEmpty }
    }
}

struct PostDraft: Hashable, Sendable {
    var id: UUID = UUID()
    var topic: String = "同城交友"
    var city: String = "上海"
    var content: String = ""
    var tagsText: String = "遛宠 社交"
    var mediaKind: PostMediaKind = .image
    var mediaAssetPath: String?
    var mediaDisplayName: String = ""

    var tags: [String] {
        tagsText
            .split(separator: " ")
            .map { String($0) }
            .filter { !$0.isEmpty }
    }

    var mediaAttachment: PostMediaAttachment? {
        guard let mediaAssetPath else { return nil }
        return PostMediaAttachment(
            kind: mediaKind,
            localAssetPath: mediaAssetPath,
            displayName: mediaDisplayName.isEmpty ? mediaKind.rawValue : mediaDisplayName
        )
    }
}

struct VideoDraft: Hashable, Sendable {
    var title: String = ""
    var duration: String = "00:30"
    var caption: String = ""
    var tagsText: String = "成长 日常"
    var accent: AccentToken = .peach

    var tags: [String] {
        tagsText
            .split(separator: " ")
            .map { String($0) }
            .filter { !$0.isEmpty }
    }
}

struct MemoryDraft: Hashable, Sendable {
    var id: UUID = UUID()
    var title: String = ""
    var subtitle: String = ""
    var dateText: String = "2026.04.02"
    var story: String = ""
    var ornament: String = "star.fill"
    var accent: AccentToken = .pine
    var mediaKind: PostMediaKind = .image
    var mediaAssetPath: String?
    var mediaDisplayName: String?
    var photoAssetPath: String?
    var audioAssetPath: String?
    var audioDisplayName: String?
}
