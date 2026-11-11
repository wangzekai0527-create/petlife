import SwiftUI

struct HomeDashboardView: View {
    @Environment(\.locale) private var appLocale
    @AppStorage(L10n.preferenceKey) private var language = "zh-Hans"
    let appModel: AppModel

    var body: some View {
        let _ = appLocale
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PetPageHeader(
                    title: L10n.text("你好，\(appModel.currentUser?.displayName ?? "朋友")"),
                    subtitle: L10n.text("找玩伴、找寄养，也记下日常。"),
                    animal: .dog
                )
                stats
                VStack(alignment: .leading, spacing: 16) {
                    Text(L10n.text("今天，和它一起"))
                        .font(.title3.weight(.semibold))
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        NavigationLink {
                            PetMatchView(appModel: appModel).petPalette(.social)
                        } label: {
                            HomeShortcut(title: L10n.text("宠物交友"), detail: L10n.text("认识合拍的新朋友"), animal: .dog).petPalette(.socialShortcut)
                        }
                        NavigationLink {
                            PetServicesView().petPalette(.services)
                        } label: {
                            HomeShortcut(title: L10n.text("寻找寄养"), detail: L10n.text("为它找个安心的家"), animal: .turtle).petPalette(.servicesShortcut)
                        }
                        NavigationLink {
                            AlbumTreeView(appModel: appModel).petPalette(.album)
                        } label: {
                            HomeShortcut(title: L10n.text("成长相册"), detail: L10n.text("收好每一段小日常"), animal: .bird).petPalette(.albumShortcut)
                        }
                        NavigationLink {
                            ProfileHubView(appModel: appModel).petPalette(.profile)
                        } label: {
                            HomeShortcut(title: L10n.text("宠物档案"), detail: L10n.text("更了解你的伙伴"), animal: .cat).petPalette(.profile)
                        }
                    }
                    .buttonStyle(.plain)
                }
                HStack(spacing: 18) {
                    PetDoodle(animal: .rabbit).frame(width: 68, height: 76)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.text("每一种小伙伴，都值得被了解。"))
                            .font(.subheadline.weight(.medium))
                        Text(L10n.text("从一份完整的宠物档案开始。"))
                            .font(.footnote)
                            .foregroundStyle(PetTheme.secondaryInk)
                    }
                }
                .padding(.vertical, 6)
            }
            .padding(24)
        }
        .refreshable { await appModel.refreshContent() }
        .background(PetTheme.softBackground)
        .navigationTitle("petlife")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { language = language == "en" ? "zh-Hans" : "en" } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                        Text(language == "en" ? "中文" : "English")
                    }
                    .font(.subheadline.weight(.medium))
                    .fixedSize()
                    .frame(minHeight: 44)
                }
                .accessibilityLabel(language == "en" ? "Switch to Chinese" : "切换为英文")
            }
        }
    }

    private var stats: some View {
        HStack(spacing: 0) {
            stat(appModel.ownedPets.count, L10n.text("我的宠物"))
            Divider().frame(height: 34)
            stat(appModel.holidayMemories.count, L10n.text("成长记录"))
            Divider().frame(height: 34)
            stat(appModel.chatThreads.count, L10n.text("我的会话"))
        }
        .padding(.vertical, 18)
        .petCard()
    }

    private func stat(_ value: Int, _ label: String) -> some View {
        VStack(spacing: 6) {
            Text("\(value)")
                .font(.system(size: 28, weight: .semibold))
                .monospacedDigit()
            Text(L10n.text(label)).font(.caption).foregroundStyle(PetTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct HomeShortcut: View {
    @Environment(\.locale) private var appLocale
    @Environment(\.petPalette) private var palette
    let title: String
    let detail: String
    let animal: PetAnimal

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                PetDoodle(animal: animal).frame(width: 56, height: 58)
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(palette.secondaryInk)
            }
            Text(L10n.text(title)).font(.headline).foregroundStyle(palette.ink)
            Text(L10n.text(detail)).font(.caption).foregroundStyle(palette.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .petCard()
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack { HomeDashboardView(appModel: AppModel()) }
}
