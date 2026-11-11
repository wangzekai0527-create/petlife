import SwiftUI

struct ProfileHubView: View {
    @Environment(\.locale) private var appLocale
    let appModel: AppModel

    @State private var isShowingPetSheet = false
    @State private var petDraft = PetDraft()

    var body: some View {
        let _ = appLocale
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let currentUser = appModel.currentUser {
                    ProfileHeader(user: currentUser)
                }

                PetSection(
                    appModel: appModel,
                    pets: appModel.ownedPets,
                    addAction: { isShowingPetSheet = true }
                )

                MyMessagesEntry(appModel: appModel)

                Button(L10n.text("退出当前账号"), action: handleSignOut)
                    .fontWeight(.semibold)
                    .foregroundStyle(PetPalette.profile.secondaryInk)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(PetPalette.profile.border, lineWidth: 1))
            }
            .padding(20)
        }
        .background(PetPalette.profile.softBackground)
        .petNavigationTitle(L10n.text("我的"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingPetSheet) {
            AddPetSheet(
                draft: $petDraft,
                isBusy: appModel.isBusy,
                saveAction: handleAddPet
            )
        }
    }

    private func handleSignOut() {
        Task {
            await appModel.signOut()
        }
    }

    private func handleAddPet() {
        let draftToSave = petDraft
        Task {
            await appModel.addPet(draftToSave)
            petDraft = PetDraft()
            isShowingPetSheet = false
        }
    }
}

private struct ProfileHeader: View {
    @Environment(\.locale) private var appLocale
    let user: UserAccount
    var body: some View {
        let _ = appLocale
        HStack(alignment: .center, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text(user.displayName).font(.system(size: 27, weight: .semibold))
                Text(L10n.text(user.city)).font(.subheadline).foregroundStyle(PetPalette.profile.secondaryInk)
                if !user.phone.isEmpty {
                    Text(user.phone).font(.footnote).foregroundStyle(PetPalette.profile.secondaryInk)
                }
                Text(L10n.text(user.bio)).font(.subheadline).foregroundStyle(PetPalette.profile.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true).lineLimit(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            PetDoodle(animal: .cat).frame(width: 100, height: 116)
        }
        .padding(22)
        .petCard()
    }
}

private struct PetSection: View {
    @Environment(\.locale) private var appLocale
    let appModel: AppModel
    let pets: [PetProfile]
    let addAction: () -> Void

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 10) {
                    PetFeatureIcon(name: "feature-profile", size: 28)
                    Text(L10n.text("我的宠物档案"))
                        .font(.title3.weight(.semibold))
                }
                Spacer()
                Button(L10n.text("新增档案"), action: addAction)
                    .font(.subheadline.weight(.semibold))
            }

            if pets.isEmpty {
                HStack(spacing: 16) {
                    PetDoodle(animal: .dog).frame(width: 64, height: 72)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.text("先认识一下你的小伙伴")).font(.subheadline.weight(.medium))
                        Text(L10n.text("添加名字、性格和喜欢的事。")).font(.footnote).foregroundStyle(PetPalette.profile.secondaryInk)
                        Button(L10n.text("添加宠物档案"), action: addAction).font(.subheadline.weight(.semibold))
                    }
                }
                .padding(18)
                .petCard()
            }

            ForEach(pets) { pet in
                VStack(alignment: .leading, spacing: 10) {
                    Toggle(L10n.text("公开档案并接受交友消息"), isOn: Binding(
                        get: { pet.isDiscoverable },
                        set: { enabled in Task { await appModel.setPetDiscoverable(pet.id, enabled: enabled) } }
                    ))
                    Text("\(pet.name) · \(L10n.text(pet.species)) · \(L10n.text(pet.breed))")
                        .font(.headline)
                    Text("\(L10n.text(pet.ageText)) · \(L10n.text(pet.city))")
                        .font(.subheadline)
                        .foregroundStyle(PetPalette.profile.secondaryInk)
                    Text(pet.bio)
                        .font(.subheadline)
                        .foregroundStyle(PetPalette.profile.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        ForEach(pet.interests, id: \.self) { interest in
                            Text(L10n.text(interest))
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white, in: Capsule())
                                .overlay(Capsule().stroke(PetPalette.profile.border, lineWidth: 1))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(PetPalette.profile.border, lineWidth: 1))
            }
        }
    }
}

private struct MyMessagesEntry: View {
    @Environment(\.locale) private var appLocale
    let appModel: AppModel

    private var unreadCount: Int {
        appModel.chatThreads.reduce(0) { partialResult, thread in
            partialResult + thread.unreadCount
        }
    }

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.text("消息中心"))
                .font(.title3.weight(.semibold))

            NavigationLink {
                MessageInboxView(appModel: appModel)
            } label: {
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            PetPalette.profile.surface
                        )
                        .frame(width: 58, height: 58)
                        .overlay(
                            Image(systemName: "tray.full.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(PetPalette.profile.accent)
                        )

                    VStack(alignment: .leading, spacing: 5) {
                        Text(L10n.text("我的消息"))
                            .font(.headline)
                            .foregroundStyle(PetPalette.profile.ink)
                        Text(L10n.text("接收服务咨询和宠物交友消息，并继续回复聊天。"))
                            .font(.subheadline)
                            .foregroundStyle(PetPalette.profile.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(2)
                    }

                    Spacer()

                    if unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(PetPalette.profile.ink)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.white, in: Capsule())
                            .overlay(Capsule().stroke(PetPalette.profile.border, lineWidth: 1))
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PetPalette.profile.secondaryInk)
                }
                .padding(16)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(PetPalette.profile.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }
}

private struct MessageInboxView: View {
    @Environment(\.locale) private var appLocale
    let appModel: AppModel


    var body: some View {
        let _ = appLocale
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                inboxHeader

                MessageThreadSection(title: L10n.text("服务消息")) {
                    EmptyInboxCard(text: L10n.text("暂无服务消息。服务方接入后会在这里显示真实会话。"))
                }

                MessageThreadSection(title: L10n.text("交友消息")) {
                    if appModel.chatThreads.isEmpty {
                        EmptyInboxCard(text: L10n.text("还没有宠物交友消息。去相亲角发起聊天后，对话会出现在这里。"))
                    } else {
                        ForEach(appModel.chatThreads) { thread in
                            NavigationLink {
                                ChatThreadView(appModel: appModel, threadID: thread.id)
                            } label: {
                                MessageThreadRow(
                                    icon: "bubble.left.and.bubble.right.fill",
                                    title: thread.title,
                                    subtitle: thread.subtitle,
                                    source: L10n.text("宠物相亲角"),
                                    unreadCount: thread.unreadCount,
                                    accent: thread.accent
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(PetPalette.profile.softBackground)
        .petNavigationTitle(L10n.text("我的消息"))
    }

    private var inboxHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.text("消息盒子"))
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(PetPalette.profile.ink)
            Text(L10n.text("这里集中接收服务页面和宠物相亲角发来的消息，用户可以点进会话继续回复。"))
                .font(.subheadline)
                .foregroundStyle(PetPalette.profile.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct MessageThreadSection<Content: View>: View {
    @Environment(\.locale) private var appLocale
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text(title))
                .font(.title3.weight(.semibold))
                .foregroundStyle(PetPalette.profile.ink)

            content
        }
    }
}

private struct MessageThreadRow: View {
    @Environment(\.locale) private var appLocale
    let icon: String
    let title: String
    let subtitle: String
    let source: String
    let unreadCount: Int
    let accent: AccentToken

    var body: some View {
        let _ = appLocale
        HStack(spacing: 14) {
            Circle()
                .fill(PetPalette.profile.accent.opacity(0.2))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: icon)
                        .foregroundStyle(PetPalette.profile.ink)
                )

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(L10n.text(title))
                        .font(.headline)
                        .foregroundStyle(PetPalette.profile.ink)
                    Text(L10n.text(source))
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white, in: Capsule())
                        .overlay(Capsule().stroke(PetPalette.profile.border, lineWidth: 1))
                        .foregroundStyle(PetPalette.profile.ink)
                }

                Text(L10n.text(subtitle))
                    .font(.subheadline)
                    .foregroundStyle(PetPalette.profile.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
            }

            Spacer()

            if unreadCount > 0 {
                Text("\(unreadCount)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PetPalette.profile.ink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.white, in: Capsule())
                    .overlay(Capsule().stroke(PetPalette.profile.border, lineWidth: 1))
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(PetPalette.profile.secondaryInk)
        }
        .padding(16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(PetPalette.profile.border, lineWidth: 1))
    }
}

private struct EmptyInboxCard: View {
    @Environment(\.locale) private var appLocale
    let text: String

    var body: some View {
        let _ = appLocale
        Text(L10n.text(text))
            .font(.subheadline)
            .foregroundStyle(PetPalette.profile.secondaryInk)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(PetPalette.profile.border, lineWidth: 1))
    }
}

private struct AddPetSheet: View {
    @Environment(\.locale) private var appLocale
    @Binding var draft: PetDraft
    let isBusy: Bool
    let saveAction: () -> Void

    var body: some View {
        let _ = appLocale
        NavigationStack {
            Form {
                Section(L10n.text("基础信息")) {
                    TextField(L10n.text("名字"), text: $draft.name)
                    TextField(L10n.text("物种，例如狗狗/猫咪"), text: $draft.species)
                    TextField(L10n.text("品种"), text: $draft.breed)
                    TextField(L10n.text("年龄"), text: $draft.ageText)
                    TextField(L10n.text("城市"), text: $draft.city)
                }

                Section(L10n.text("社交标签")) {
                    TextField(L10n.text("简介"), text: $draft.bio, axis: .vertical)
                    TextField(L10n.text("兴趣，用空格分开"), text: $draft.interestsText)
                    TextField(L10n.text("想找怎样的伙伴"), text: $draft.lookingFor)
                    Toggle(L10n.text("已完成基础疫苗"), isOn: $draft.vaccinated)
                    Toggle(L10n.text("在交友页面公开这份宠物档案"), isOn: $draft.isDiscoverable)
                    Text(L10n.text("开启后，其他已登录用户可以看到档案并向你发起聊天。"))
                        .font(.footnote)
                }
            }
            .petNavigationTitle(L10n.text("新增宠物档案"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.text("保存"), action: saveAction)
                        .disabled(draft.name.isEmpty || draft.breed.isEmpty || isBusy)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileHubView(appModel: AppModel())
    }
}
