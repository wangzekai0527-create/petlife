import AVFoundation
import AVKit
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct PetMatchView: View {
    @Environment(\.locale) private var appLocale
    let appModel: AppModel

    @State private var isShowingComposer = false
    @State private var composerDraft = PostDraft()
    @State private var activeThreadRoute: ActiveThreadRoute?
    @State private var activePostRoute: ActivePostRoute?

    var body: some View {
        let _ = appLocale
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                MatchHero()
                PetFriendMatchEntry(appModel: appModel, activeThreadRoute: $activeThreadRoute)
                if appModel.discoverPets.isEmpty {
                    Text(L10n.text("暂无公开的宠物档案。你可以在“我的”里开启档案交友展示。"))
                        .font(.subheadline).padding(18).petCard()
                }
                MatchProfileCarousel(appModel: appModel, activeThreadRoute: $activeThreadRoute)
                MyPostsSection(appModel: appModel, showComposerAction: {
                    isShowingComposer = true
                })
                CommunityFeed(
                    appModel: appModel,
                    activeThreadRoute: $activeThreadRoute,
                    activePostRoute: $activePostRoute
                )
            }
            .padding(20)
        }
        .refreshable { await appModel.refreshContent() }
        .background(PetPalette.social.softBackground)
        .petNavigationTitle(L10n.text("宠物交友"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.text("发动态")) {
                    isShowingComposer = true
                }
            }
        }
        .sheet(isPresented: $isShowingComposer) {
            PostComposerSheet(
                draft: $composerDraft,
                petOptions: appModel.ownedPets.map(\.name),
                isBusy: appModel.isBusy,
                publishAction: handlePublishPost
            )
        }
        .sheet(item: $activeThreadRoute) { route in
            NavigationStack {
                ChatThreadView(appModel: appModel, threadID: route.id)
            }
        }
        .navigationDestination(item: $activePostRoute) { route in
            PostDetailView(appModel: appModel, postID: route.id)
        }
    }

    private func handlePublishPost(selectedPet: String) {
        let draftToSave = composerDraft
        Task {
            await appModel.createPost(draftToSave, petName: selectedPet)
            composerDraft = PostDraft()
            isShowingComposer = false
        }
    }
}

private struct ActiveThreadRoute: Identifiable {
    let id: UUID
}

private struct ActivePostRoute: Identifiable,Hashable {
    let id: UUID
}

private struct MatchHero: View {
    @Environment(\.locale) private var appLocale
    var body: some View {
        let _ = appLocale
        PetPageHeader(title: L10n.text("认识合拍的小伙伴"), subtitle: L10n.text("从一份档案开始，找到聊得来的宠友。"), animal: .dog)
    }
}

private struct MatchProfileCarousel: View {
    @Environment(\.locale) private var appLocale
    let appModel: AppModel
    @Binding var activeThreadRoute: ActiveThreadRoute?

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.text("推荐档案"))
                .font(.title3.weight(.semibold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(appModel.discoverPets) { pet in
                        NavigationLink {
                            PetDetailView(appModel: appModel, pet: pet, activeThreadRoute: $activeThreadRoute)
                        } label: {
                            PetProfileCard(pet: pet)
                        }
                    }
                }
            }
        }
    }
}

private struct PetProfileCard: View {
    @Environment(\.locale) private var appLocale
    let pet: PetProfile

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 14) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    PetPalette.social.surface
                )
                .frame(width: 250, height: 180)
                .overlay(
                    PetDoodle(animal: pet.species.contains("猫") ? .cat : .dog).frame(width: 84, height: 84)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text("\(pet.name) · \(L10n.text(pet.breed))")
                    .font(.headline)
                    .foregroundStyle(PetPalette.social.ink)
                Text("\(L10n.text(pet.ageText)) · \(L10n.text(pet.city))")
                    .font(.subheadline)
                    .foregroundStyle(PetPalette.social.secondaryInk)
                Text(pet.bio)
                    .font(.subheadline)
                    .foregroundStyle(PetPalette.social.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                ForEach(pet.interests, id: \.self) { interest in
                    Text(L10n.text(interest))
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(PetPalette.social.surface, in: Capsule())
                        .overlay(Capsule().stroke(PetPalette.social.border, lineWidth: 1))
                }
            }
        }
        .padding(16)
        .frame(width: 282, alignment: .leading)
        .background(PetPalette.social.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(PetPalette.social.border, lineWidth: 1))
    }
}

private struct CommunityFeed: View {
    @Environment(\.locale) private var appLocale
    let appModel: AppModel
    @Binding var activeThreadRoute: ActiveThreadRoute?
    @Binding var activePostRoute: ActivePostRoute?

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.text("同城动态"))
                .font(.title3.weight(.semibold))

            ForEach(appModel.feedPosts) { post in
                NavigationLink {
                    PostDetailView(appModel: appModel, postID: post.id)
                } label: {
                    PostRow(
                        post: post,
                        attachment: appModel.mediaAttachment(for: post.id),
                        likeAction: {
                            Task {
                                await appModel.toggleLike(postID: post.id)
                            }
                        }
                    )
                }
                .contextMenu {
                    Button(L10n.text("进入详情")) {
                        activePostRoute = ActivePostRoute(id: post.id)
                    }
                    Button(L10n.text("发起聊天")) {
                        handleMessage(for: post)
                    }
                }
            }
        }
    }

    private func handleMessage(for post: FeedPost) {
        guard
            let relatedPetID = post.relatedPetID,
            let pet = appModel.discoverPets.first(where: { $0.id == relatedPetID })
        else {
            return
        }

        Task {
            if let id = await appModel.openChat(for: pet) {
                activeThreadRoute = ActiveThreadRoute(id: id)
            }
        }
    }
}

private struct MyPostsSection: View {
    @Environment(\.locale) private var appLocale
    let appModel: AppModel
    let showComposerAction: () -> Void

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(L10n.text("我的动态"))
                    .font(.title3.weight(.semibold))
                Spacer()
                NavigationLink(L10n.text("查看全部")) {
                    MyPostsHubView(appModel: appModel)
                }
                .font(.subheadline.weight(.semibold))
            }

            if appModel.myPosts.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.text("你还没有发布过动态。"))
                        .font(.headline)
                        .foregroundStyle(PetPalette.social.ink)
                    Text(L10n.text("从右上角发一条带图片或视频的动态，这里就会展示你已经发布的内容。"))
                        .font(.subheadline)
                        .foregroundStyle(PetPalette.social.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(L10n.text("现在发动态"), action: showComposerAction)
                        .buttonStyle(PetCompactButtonStyle())
                        .foregroundStyle(PetPalette.social.ink)
                        .tint(PetPalette.social.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(PetPalette.social.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(PetPalette.social.border, lineWidth: 1))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(appModel.myPosts) { post in
                            NavigationLink {
                                PostDetailView(appModel: appModel, postID: post.id)
                            } label: {
                                MyPostCard(
                                    post: post,
                                    attachment: appModel.mediaAttachment(for: post.id)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}

private struct MyPostCard: View {
    @Environment(\.locale) private var appLocale
    let post: FeedPost
    let attachment: PostMediaAttachment?

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 12) {
            PostMediaPreview(attachment: attachment, height: 180)

            Text(post.topic)
                .font(.headline)
                .foregroundStyle(PetPalette.social.ink)
                .lineLimit(1)

            Text(post.content)
                .font(.subheadline)
                .foregroundStyle(PetPalette.social.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(2)

            HStack(spacing: 14) {
                Label("\(post.likes)", systemImage: post.likedByCurrentUser ? "heart.fill" : "heart")
                Label("\(post.comments.count)", systemImage: "bubble.right")
                Text(post.createdAtText)
            }
            .font(.caption)
            .foregroundStyle(PetPalette.social.secondaryInk)
        }
        .padding(16)
        .frame(width: 250, alignment: .leading)
        .background(PetPalette.social.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(PetPalette.social.border, lineWidth: 1))
    }
}

private struct PetFriendMatchEntry: View {
    @Environment(\.locale) private var appLocale
    let appModel: AppModel
    @Binding var activeThreadRoute: ActiveThreadRoute?

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.text("宠物交友一键匹配"))
                .font(.title3.weight(.semibold))

            NavigationLink {
                PetFriendMatchView(appModel: appModel, activeThreadRoute: $activeThreadRoute)
            } label: {
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                PetPalette.social.surface
                            )

                        PetDoodle(animal: .dog).padding(8)
                    }
                    .frame(width: 64, height: 72)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.text("找到它的好朋友"))
                            .font(.headline)
                            .foregroundStyle(PetPalette.social.ink)
                        Text(L10n.text("结合体型、性格和城市，认识更合拍的宠友。"))
                            .font(.subheadline)
                            .foregroundStyle(PetPalette.social.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(3)

                        PetFlowLayout(spacing: 6) {
                            ForEach([L10n.text("同体型"), L10n.text("同频性格"), L10n.text("近距离")], id: \.self) { tag in
                                Text(L10n.text(tag))
                                    .font(.caption.weight(.medium))
                                    .fixedSize(horizontal: true, vertical: false)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(PetPalette.social.surface, in: Capsule())
                                    .overlay(Capsule().stroke(PetPalette.social.border, lineWidth: 1))
                                    .foregroundStyle(PetPalette.social.ink)
                            }
                        }
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PetPalette.social.ink)
                        .padding(.top, 6)
                }
                .padding(18)
                .background(PetPalette.social.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(PetPalette.social.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }
}

private struct PetFriendMatchView: View {
    @Environment(\.locale) private var appLocale
    let appModel: AppModel
    @Binding var activeThreadRoute: ActiveThreadRoute?

    @State private var selectedPetID: UUID?

    private var selectedPet: PetProfile? {
        let fallback = appModel.ownedPets.first
        guard let selectedPetID else {
            return fallback
        }
        return appModel.ownedPets.first { $0.id == selectedPetID } ?? fallback
    }

    private var matchResults: [PetFriendMatchResult] {
        guard let selectedPet else {
            return []
        }

        return PetFriendMatcher.results(for: selectedPet, candidates: appModel.discoverPets)
    }

    var body: some View {
        let _ = appLocale
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                matchIntro

                if appModel.ownedPets.isEmpty {
                    emptyOwnedPetCard
                } else {
                    petPicker
                    matchRuleCard

                    ForEach(matchResults) { result in
                        PetFriendMatchResultCard(result: result, chatAction: {
                            openChat(for: result.pet)
                        })
                    }
                }
            }
            .padding(20)
        }
        .background(PetPalette.social.softBackground)
        .petNavigationTitle(L10n.text("一键匹配"))
        .onAppear {
            if selectedPetID == nil {
                selectedPetID = appModel.ownedPets.first?.id
            }
        }
    }

    private var matchIntro: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.text("宠物交友智能匹配"))
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(PetPalette.social.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(L10n.text("系统会读取宠物档案里的品种、体型关键词、性格描述、主人期望对象和城市信息，优先推送地区更近、特征更合拍的宠友。"))
                .font(.subheadline)
                .foregroundStyle(PetPalette.social.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var emptyOwnedPetCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.text("还没有可用于匹配的宠物档案"))
                .font(.headline)
                .foregroundStyle(PetPalette.social.ink)
            Text(L10n.text("先在“我的”里新增宠物档案，填写品种、性格和期望交友对象后，就可以进行一键匹配。"))
                .font(.subheadline)
                .foregroundStyle(PetPalette.social.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PetPalette.social.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(PetPalette.social.border, lineWidth: 1))
    }

    private var petPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.text("选择要匹配的宠物"))
                .font(.headline)
                .foregroundStyle(PetPalette.social.ink)

            Picker(L10n.text("选择要匹配的宠物"), selection: selectedPetIDBinding) {
                ForEach(appModel.ownedPets) { pet in
                    Text("\(pet.name) · \(L10n.text(pet.breed))").tag(Optional(pet.id))
                }
            }
            .pickerStyle(.menu)

            if let selectedPet {
                Text("\(L10n.text(selectedPet.city)) · \(selectedPet.bio)")
                    .font(.subheadline)
                    .foregroundStyle(PetPalette.social.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .background(PetPalette.social.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(PetPalette.social.border, lineWidth: 1))
    }

    private var selectedPetIDBinding: Binding<UUID?> {
        Binding(
            get: { selectedPetID ?? appModel.ownedPets.first?.id },
            set: { selectedPetID = $0 }
        )
    }

    private var matchRuleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text("匹配机制"))
                .font(.headline)
                .foregroundStyle(PetPalette.social.ink)

            MatchRuleRow(icon: "pawprint.fill", title: L10n.text("体型优先"), detail: L10n.text("小型犬优先匹配小型犬，同物种、同体型加权更高。"))
            MatchRuleRow(icon: "heart.text.square.fill", title: L10n.text("性格同频"), detail: L10n.text("安静匹配安静，活泼匹配活泼，按档案描述和兴趣关键词识别。"))
            MatchRuleRow(icon: "scope", title: L10n.text("期望对象"), detail: L10n.text("如果主人写明想找某个品种，比如金毛想认识萨摩耶，会额外提高匹配分。"))
            MatchRuleRow(icon: "location.fill", title: L10n.text("地区近优先"), detail: L10n.text("同城优先，其次推送周边城市，降低见面和遛宠成本。"))
        }
        .padding(18)
        .background(PetPalette.social.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(PetPalette.social.border, lineWidth: 1))
    }

    private func openChat(for pet: PetProfile) {
        Task {
            if let id = await appModel.openChat(for: pet) {
                activeThreadRoute = ActiveThreadRoute(id: id)
            }
        }
    }
}

private struct MatchRuleRow: View {
    @Environment(\.locale) private var appLocale
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        let _ = appLocale
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(PetPalette.social.ink)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.text(title))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PetPalette.social.ink)
                Text(L10n.text(detail))
                    .font(.caption)
                    .foregroundStyle(PetPalette.social.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct PetFriendMatchResultCard: View {
    @Environment(\.locale) private var appLocale
    let result: PetFriendMatchResult
    let chatAction: () -> Void

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        PetPalette.social.surface
                    )
                    .frame(width: 92, height: 92)
                    .overlay(PetFeatureIcon(name: "feature-social", size: 42))

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(result.pet.name) · \(L10n.text(result.pet.breed))")
                            .font(.headline)
                            .foregroundStyle(PetPalette.social.ink)
                            .lineLimit(2)
                        Spacer(minLength: 8)
                        Text(L10n.text("\(result.score)分"))
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(PetPalette.social.surface, in: Capsule())
                            .overlay(Capsule().stroke(PetPalette.social.border, lineWidth: 1))
                            .foregroundStyle(PetPalette.social.ink)
                    }

                    Text("\(L10n.text(result.pet.ageText)) · \(L10n.text(result.pet.city)) · \(result.distanceLabel)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PetPalette.social.ink)
                    Text(result.pet.bio)
                        .font(.subheadline)
                        .foregroundStyle(PetPalette.social.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(3)
                }
            }

            HStack(spacing: 8) {
                ForEach(result.pet.interests.prefix(3), id: \.self) { interest in
                    Text(L10n.text(interest))
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(PetPalette.social.surface, in: Capsule())
                        .overlay(Capsule().stroke(PetPalette.social.border, lineWidth: 1))
                        .foregroundStyle(PetPalette.social.ink)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text("推荐理由"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PetPalette.social.ink)

                ForEach(result.reasons, id: \.self) { reason in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(PetPalette.social.ink)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        Text(L10n.text(reason))
                            .font(.caption)
                            .foregroundStyle(PetPalette.social.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Button(L10n.text("发起聊天"), action: chatAction)
                .buttonStyle(PetCompactButtonStyle())
                .foregroundStyle(PetPalette.social.ink)
                .tint(PetPalette.social.ink)
        }
        .padding(18)
        .background(PetPalette.social.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(PetPalette.social.border, lineWidth: 1))
    }
}

private struct PetFriendMatchResult: Identifiable, Hashable {
    var id: UUID { pet.id }
    let pet: PetProfile
    let score: Int
    let reasons: [String]
    let distanceLabel: String
}

private enum PetFriendMatcher {
    static func results(for pet: PetProfile, candidates: [PetProfile]) -> [PetFriendMatchResult] {
        candidates
            .map { candidate in
                score(pet: pet, candidate: candidate)
            }
            .sorted {
                if $0.score == $1.score {
                    return cityPriority(from: pet.city, to: $0.pet.city) > cityPriority(from: pet.city, to: $1.pet.city)
                }
                return $0.score > $1.score
            }
    }

    private static func score(pet: PetProfile, candidate: PetProfile) -> PetFriendMatchResult {
        var score = 0
        var reasons: [String] = []

        if pet.species == candidate.species {
            score += 15
            reasons.append("同为\(pet.species)，互动方式更接近。")
        }

        let petSize = sizeBucket(for: pet)
        let candidateSize = sizeBucket(for: candidate)
        if petSize == candidateSize {
            score += 25
            reasons.append("\(petSize)体型接近，见面玩耍更安全。")
        }

        let sharedPersonalities = personalityTags(for: pet).intersection(personalityTags(for: candidate))
        if !sharedPersonalities.isEmpty {
            score += 24
            reasons.append("性格关键词同频：\(sharedPersonalities.sorted().joined(separator: "、"))。")
        }

        let expectedBreedHits = expectedBreeds(in: pet).filter { candidate.breed.contains($0) || candidate.bio.contains($0) }
        if !expectedBreedHits.isEmpty {
            score += 24
            reasons.append("符合主人期望的交友对象：\(expectedBreedHits.joined(separator: "、"))。")
        }

        let sharedInterests = Set(pet.interests).intersection(Set(candidate.interests))
        if !sharedInterests.isEmpty {
            score += min(16, sharedInterests.count * 8)
            reasons.append("共同兴趣：\(sharedInterests.sorted().joined(separator: "、"))。")
        }

        let cityScore = cityPriority(from: pet.city, to: candidate.city)
        score += cityScore
        reasons.append(cityReason(from: pet.city, to: candidate.city))

        if reasons.isEmpty {
            reasons.append("档案信息完整，可先从线上聊天了解彼此。")
        }

        return PetFriendMatchResult(
            pet: candidate,
            score: min(score, 100),
            reasons: Array(reasons.prefix(4)),
            distanceLabel: cityDistanceLabel(from: pet.city, to: candidate.city)
        )
    }

    private static func sizeBucket(for pet: PetProfile) -> String {
        let text = searchableText(for: pet)
        if text.contains("小型") || text.contains("柯基") || text.contains("比熊") || text.contains("泰迪") || text.contains("博美") || text.contains("吉娃娃") {
            return "小型"
        }
        if text.contains("金毛") || text.contains("拉布拉多") || text.contains("阿拉斯加") || text.contains("德牧") || text.contains("大型") {
            return "大型"
        }
        if text.contains("萨摩耶") || text.contains("边牧") || text.contains("柴犬") || text.contains("中型") {
            return "中型"
        }
        if pet.species.contains("猫") {
            return "猫咪"
        }
        return "相近"
    }

    private static func personalityTags(for pet: PetProfile) -> Set<String> {
        let text = searchableText(for: pet)
        var tags = Set<String>()
        if text.contains("安静") || text.contains("温柔") || text.contains("慢热") || text.contains("稳定") {
            tags.insert("安静稳定")
        }
        if text.contains("活泼") || text.contains("社交") || text.contains("跑") || text.contains("飞盘") || text.contains("户外") {
            tags.insert("活泼外向")
        }
        if text.contains("亲人") || text.contains("黏人") || text.contains("陪伴") {
            tags.insert("亲人陪伴")
        }
        return tags
    }

    private static func expectedBreeds(in pet: PetProfile) -> [String] {
        let knownBreeds = ["金毛", "萨摩耶", "柯基", "布偶猫", "比熊", "柴犬", "边牧", "拉布拉多", "泰迪", "博美"]
        let text = "\(pet.lookingFor) \(pet.bio) \(pet.interests.joined(separator: " "))"
        return knownBreeds.filter { breed in
            breed != pet.breed && text.contains(breed)
        }
    }

    private static func cityPriority(from origin: String, to candidate: String) -> Int {
        if origin == candidate {
            return 20
        }
        if nearbyCities(for: origin).contains(candidate) {
            return 12
        }
        return 5
    }

    private static func nearbyCities(for city: String) -> Set<String> {
        switch city {
        case "上海":
            return ["苏州", "杭州", "南京"]
        case "杭州":
            return ["上海", "苏州", "宁波"]
        case "苏州":
            return ["上海", "杭州", "南京"]
        default:
            return []
        }
    }

    private static func cityReason(from origin: String, to candidate: String) -> String {
        if origin == candidate {
            return "同城优先推送，线下见面和遛宠更方便。"
        }
        if nearbyCities(for: origin).contains(candidate) {
            return "\(candidate)属于周边城市，适合周末约见。"
        }
        return "地区距离较远，建议先线上熟悉。"
    }

    private static func cityDistanceLabel(from origin: String, to candidate: String) -> String {
        if origin == candidate {
            return "同城优先"
        }
        if nearbyCities(for: origin).contains(candidate) {
            return "周边城市"
        }
        return "可线上认识"
    }

    private static func searchableText(for pet: PetProfile) -> String {
        "\(pet.species) \(pet.breed) \(pet.bio) \(pet.interests.joined(separator: " ")) \(pet.lookingFor)"
    }
}

private struct PostRow: View {
    @Environment(\.locale) private var appLocale
    let post: FeedPost
    let attachment: PostMediaAttachment?
    let likeAction: () -> Void

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(post.authorName) · \(post.petName)")
                        .font(.headline)
                        .foregroundStyle(PetPalette.social.ink)
                    Text("\(post.topic) · \(L10n.text(post.city))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PetPalette.social.ink)
                }
                Spacer()
                Text(post.createdAtText)
                    .font(.caption)
                    .foregroundStyle(PetPalette.social.secondaryInk)
            }

            Text(post.content)
                .font(.subheadline)
                .foregroundStyle(PetPalette.social.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)

            if attachment != nil {
                PostMediaPreview(attachment: attachment, height: 190)
            }

            HStack(spacing: 8) {
                ForEach(post.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(PetPalette.social.surface, in: Capsule())
                        .overlay(Capsule().stroke(PetPalette.social.border, lineWidth: 1))
                }
            }

            HStack(spacing: 18) {
                Button(action: likeAction) {
                    Label("\(post.likes)", systemImage: post.likedByCurrentUser ? "heart.fill" : "heart")
                }
                .buttonStyle(.plain)

                Label("\(post.comments.count)", systemImage: "bubble.right")
                Label(L10n.text("详情"), systemImage: "arrow.right.circle")
            }
            .font(.caption)
            .foregroundStyle(PetPalette.social.secondaryInk)
        }
        .padding(18)
        .background(PetPalette.social.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(PetPalette.social.border, lineWidth: 1))
    }
}

private struct PetDetailView: View {
    @Environment(\.locale) private var appLocale
    let appModel: AppModel
    let pet: PetProfile
    @Binding var activeThreadRoute: ActiveThreadRoute?

    var body: some View {
        let _ = appLocale
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        PetPalette.social.surface
                    )
                    .frame(height: 250)
                    .overlay(
                        PetHeroArtwork(name: "hero-social", width: 190)
                    )

                Text("\(pet.name) · \(L10n.text(pet.breed))")
                    .font(.largeTitle.weight(.bold))
                Text("\(L10n.text(pet.species)) · \(L10n.text(pet.ageText)) · \(L10n.text(pet.city))")
                    .font(.headline)
                    .foregroundStyle(PetPalette.social.secondaryInk)
                Text(pet.bio)
                    .font(.body)
                    .foregroundStyle(PetPalette.social.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)

                Text(L10n.text("想找的关系"))
                    .font(.headline)
                Text(pet.lookingFor)
                    .font(.subheadline)
                    .foregroundStyle(PetPalette.social.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)

                Button(L10n.text("发起聊天"), action: openChat)
                    .buttonStyle(PetCompactButtonStyle())
                    .foregroundStyle(PetPalette.social.ink)
                    .tint(PetPalette.social.ink)
            }
            .padding(20)
        }
        .petNavigationTitle(L10n.text("宠物档案"))
    }

    private func openChat() {
        Task {
            if let id = await appModel.openChat(for: pet) {
                activeThreadRoute = ActiveThreadRoute(id: id)
            }
        }
    }
}

private struct PostDetailView: View {
    @Environment(\.locale) private var appLocale
    let appModel: AppModel
    let postID: UUID

    @State private var commentText = ""

    private var post: FeedPost? {
        appModel.post(for: postID)
    }

    var body: some View {
        let _ = appLocale
        ScrollView {
            if let post {
                VStack(alignment: .leading, spacing: 18) {
                    if let attachment = appModel.mediaAttachment(for: post.id) {
                        PostMediaDetail(attachment: attachment)
                    }

                    PostRow(
                        post: post,
                        attachment: nil,
                        likeAction: {
                            Task {
                                await appModel.toggleLike(postID: post.id)
                            }
                        }
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.text("评论"))
                            .font(.title3.weight(.semibold))

                        ForEach(post.comments) { comment in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(comment.authorName)
                                    .font(.headline)
                                Text(comment.body)
                                    .font(.subheadline)
                                    .foregroundStyle(PetPalette.social.secondaryInk)
                                Text(comment.createdAtText)
                                    .font(.caption)
                                    .foregroundStyle(PetPalette.social.secondaryInk)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(PetPalette.social.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(PetPalette.social.border, lineWidth: 1))
                        }

                        TextField(L10n.text("补一句你的想法"), text: $commentText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)

                        Button(L10n.text("发布评论"), action: handleAddComment)
                            .buttonStyle(PetCompactButtonStyle())
                            .foregroundStyle(PetPalette.social.ink)
                            .tint(PetPalette.social.ink)
                            .disabled(commentText.isEmpty)
                    }
                }
                .padding(20)
            }
        }
        .background(PetPalette.social.softBackground)
        .petNavigationTitle(L10n.text("动态详情"))
    }

    private func handleAddComment() {
        let text = commentText
        Task {
            await appModel.addComment(postID: postID, text: text)
            commentText = ""
        }
    }
}

private struct PostMediaDetail: View {
    @Environment(\.locale) private var appLocale
    let attachment: PostMediaAttachment

    var body: some View {
        let _ = appLocale
        if let fileURL = MemoryAssetStore.url(for: attachment.localAssetPath) {
            Group {
                switch attachment.kind {
                case .image:
                    if let image = UIImage(contentsOfFile: fileURL.path) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        MediaPlaceholder(kind: attachment.kind, title: attachment.displayName)
                    }
                case .video:
                    VideoPlayer(player: AVPlayer(url: fileURL))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 320)
            .background(PetPalette.social.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(PetPalette.social.border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        } else {
            MediaPlaceholder(kind: attachment.kind, title: attachment.displayName)
                .frame(height: 320)
        }
    }
}

struct ChatThreadView: View {
    @Environment(\.locale) private var appLocale
    @Environment(\.petPalette) private var palette
    @Environment(\.scenePhase) private var scenePhase
    let appModel: AppModel
    let threadID: UUID
    @State private var draft = ""
    @State private var isSending = false
    @State private var failed = false
    @State private var messageID = UUID()
    private var thread: ChatThread? { appModel.thread(for: threadID) }

    var body: some View {
        let _ = appLocale
        VStack(spacing: 0) {
            Text(L10n.text(appModel.chatConnection)).font(.caption).padding(8)
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if thread?.messages.isEmpty != false {
                            Text(L10n.text("发送第一条消息，开始交流吧。"))
                                .font(.subheadline).padding(24)
                        }
                        ForEach(thread?.messages ?? []) { message in
                            HStack {
                                if message.isFromCurrentUser { Spacer(minLength: 48) }
                                VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 5) {
                                    Text(message.text).textSelection(.enabled)
                                        .font(.body).padding(14)
                                        .background(palette.surface, in: RoundedRectangle(cornerRadius: 18))
                                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(palette.border, lineWidth: 0.7))
                                    HStack(spacing: 6) {
                                        if let date = message.sentAt { Text(date, style: .time) }
                                        else { Text(L10n.text(message.sentAtText)) }
                                        if message.isFromCurrentUser { Text(message.isRead ? L10n.text("已读") : L10n.text("已发送")) }
                                    }.font(.caption2)
                                }
                                if !message.isFromCurrentUser { Spacer(minLength: 48) }
                            }.id(message.id)
                        }
                        Color.clear.frame(height: 1).id("chat-bottom")
                    }.padding(20)
                }
                .onAppear { proxy.scrollTo("chat-bottom", anchor: .bottom) }
                .onChange(of: thread?.messages.last?.id) { _, _ in proxy.scrollTo("chat-bottom", anchor: .bottom) }
            }
            if failed { Text(L10n.text(appModel.chatSendError ?? "发送失败，内容已保留。请检查网络后重试。"))
                .font(.footnote).padding(.horizontal).accessibilityAddTraits(.updatesFrequently) }
            HStack(alignment: .bottom, spacing: 12) {
                TextField(L10n.text("输入消息"), text: $draft, axis: .vertical)
                    .lineLimit(1...5).textFieldStyle(.roundedBorder)
                    .disabled(isSending)
                Button(isSending ? L10n.text("发送中") : (failed ? L10n.text("重试") : L10n.text("发送")), action: handleSend)
                    .buttonStyle(PetCompactButtonStyle())
                    .disabled(isSending || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || draft.count > 4000)
            }.padding(16).background(Color.white)
        }
        .petNavigationTitle(thread?.title ?? L10n.text("聊天"))
        .background(palette.softBackground)
        .task(id: "\(thread?.messages.last?.id.uuidString ?? "empty")-\(scenePhase == .active)") {
            if scenePhase == .active { await appModel.markChatRead(threadID) }
        }
        .onChange(of: draft) { _, _ in if !isSending { failed = false; messageID = UUID() } }
    }

    private func handleSend() {
        guard !isSending else { return }
        isSending = true
        let text = draft
        let id = messageID
        Task {
            let sent = await appModel.sendMessage(threadID: threadID, text: text, messageID: id)
            isSending = false
            failed = !sent
            if sent { draft = ""; messageID = UUID() }
        }
    }
}

private struct MyPostsHubView: View {
    @Environment(\.locale) private var appLocale
    let appModel: AppModel

    var body: some View {
        let _ = appLocale
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if appModel.myPosts.isEmpty {
                    Text(L10n.text("这里还没有你发布的动态。"))
                        .font(.subheadline)
                        .foregroundStyle(PetPalette.social.secondaryInk)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(PetPalette.social.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(PetPalette.social.border, lineWidth: 1))
                } else {
                    ForEach(appModel.myPosts) { post in
                        NavigationLink {
                            PostDetailView(appModel: appModel, postID: post.id)
                        } label: {
                            PostRow(
                                post: post,
                                attachment: appModel.mediaAttachment(for: post.id),
                                likeAction: {
                                    Task {
                                        await appModel.toggleLike(postID: post.id)
                                    }
                                }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .background(PetPalette.social.softBackground)
        .petNavigationTitle(L10n.text("我的动态"))
    }
}

private struct PostComposerSheet: View {
    @Environment(\.locale) private var appLocale
    @Binding var draft: PostDraft
    let petOptions: [String]
    let isBusy: Bool
    let publishAction: (String) -> Void

    @State private var selectedPet = ""
    @State private var selectedMediaItem: PhotosPickerItem?
    @State private var mediaErrorMessage: String?

    var body: some View {
        let _ = appLocale
        NavigationStack {
            Form {
                Section(L10n.text("动态内容")) {
                    Picker(L10n.text("关联宠物"), selection: selectedPetBinding) {
                        ForEach(petOptions, id: \.self) { pet in
                            Text(pet).tag(pet)
                        }
                    }
                    TextField(L10n.text("主题"), text: $draft.topic)
                    TextField(L10n.text("城市"), text: $draft.city)
                    TextField(L10n.text("正文"), text: $draft.content, axis: .vertical)
                    TextField(L10n.text("标签，空格分隔"), text: $draft.tagsText)
                }

                Section(L10n.text("图片或视频")) {
                    Picker(L10n.text("内容形式"), selection: $draft.mediaKind) {
                        ForEach(PostMediaKind.allCases, id: \.self) { kind in
                            Text(L10n.text(kind.rawValue)).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)

                    PhotosPicker(
                        selection: $selectedMediaItem,
                        matching: draft.mediaKind == .image ? .images : .videos
                    ) {
                        Label(
                            draft.mediaAssetPath == nil ? L10n.text("选择\(draft.mediaKind.rawValue)") : L10n.text("重新选择\(draft.mediaKind.rawValue)"),
                            systemImage: draft.mediaKind == .image ? "photo" : "video"
                        )
                    }

                    if let attachment = draft.mediaAttachment {
                        PostMediaPreview(attachment: attachment, height: 180)
                            .padding(.vertical, 4)
                    }

                    if let mediaErrorMessage {
                        Text(mediaErrorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .petNavigationTitle(L10n.text("发布动态"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.text("发布")) {
                        publishAction(selectedPet.isEmpty ? (petOptions.first ?? L10n.text("我的宠物")) : selectedPet)
                    }
                    .disabled(draft.content.isEmpty || draft.mediaAssetPath == nil || petOptions.isEmpty || isBusy)
                }
            }
            .task(id: selectedMediaItem) {
                await importSelectedMedia()
            }
        }
    }

    private var selectedPetBinding: Binding<String> {
        Binding(
            get: { selectedPet.isEmpty ? (petOptions.first ?? "") : selectedPet },
            set: { selectedPet = $0 }
        )
    }

    private func importSelectedMedia() async {
        guard let selectedMediaItem else { return }
        mediaErrorMessage = nil

        let preferredType = selectedMediaItem.supportedContentTypes.first
        let preferredExtension = preferredType?.preferredFilenameExtension ?? (draft.mediaKind == .image ? "jpg" : "mov")

        do {
            guard let data = try await selectedMediaItem.loadTransferable(type: Data.self) else {
                mediaErrorMessage = L10n.text("没有读取到媒体内容。")
                return
            }

            let assetPath = try MemoryAssetStore.saveBinaryData(data, preferredExtension: preferredExtension)
            draft.mediaAssetPath = assetPath
            draft.mediaDisplayName = selectedMediaItem.itemIdentifier ?? "\(draft.mediaKind.rawValue).\(preferredExtension)"
        } catch {
            mediaErrorMessage = L10n.text("导入\(draft.mediaKind.rawValue)失败，请重试。")
        }
    }
}

private struct PostMediaPreview: View {
    @Environment(\.locale) private var appLocale
    let attachment: PostMediaAttachment?
    let height: CGFloat

    var body: some View {
        let _ = appLocale
        Group {
            if let attachment, let fileURL = MemoryAssetStore.url(for: attachment.localAssetPath) {
                switch attachment.kind {
                case .image:
                    if let image = UIImage(contentsOfFile: fileURL.path) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        MediaPlaceholder(kind: attachment.kind, title: attachment.displayName)
                    }
                case .video:
                    if let thumbnail = videoThumbnail(for: fileURL) {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .overlay(alignment: .center) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 34))
                                    .foregroundStyle(.white)
                                    .shadow(radius: 10)
                            }
                    } else {
                        MediaPlaceholder(kind: attachment.kind, title: attachment.displayName)
                    }
                }
            } else {
                MediaPlaceholder(kind: .image, title: L10n.text("暂未选择媒体"))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func videoThumbnail(for url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 900, height: 900)
        do {
            let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            return nil
        }
    }
}

private struct MediaPlaceholder: View {
    @Environment(\.locale) private var appLocale
    let kind: PostMediaKind
    let title: String
    var body: some View {
        let _ = appLocale
        VStack(spacing: 8) {
            PetDoodle(animal: kind == .video ? .bird : .cat).frame(width: 68, height: 72)
            Text(L10n.text(title)).font(.caption).foregroundStyle(PetPalette.social.secondaryInk).lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PetPalette.social.surface)
    }
}

#Preview {
    NavigationStack {
        PetMatchView(appModel: AppModel())
    }
}
