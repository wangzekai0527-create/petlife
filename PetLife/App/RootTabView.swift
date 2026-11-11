import Observation
import SwiftUI

struct RootTabView: View {
    @AppStorage(L10n.preferenceKey) private var language = "zh-Hans"
    @Environment(\.scenePhase) private var scenePhase
    @Bindable var appModel: AppModel
    @State private var selectedTab: AppTab = .home
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(appModel: AppModel, initialTab: AppTab = .home) {
        self.appModel = appModel
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        Group {
            if appModel.isLoaded {
                if appModel.isAuthenticated {
                    authenticatedShell
                } else {
                    AuthenticationView(appModel: appModel)
                }
            } else {
                VStack(spacing: 20) {
                    PetDoodle(animal: .cat).frame(width: 88, height: 100)
                    ProgressView(L10n.text("正在准备 PetLife")).tint(PetTheme.accent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(PetTheme.softBackground)
                .task { await appModel.loadIfNeeded() }
            }
        }
        .environment(\.locale, Locale(identifier: language))
        .tint(PetTheme.accent)
        .preferredColorScheme(.light)
        .task(id: "\(appModel.currentUser?.id.uuidString ?? "signed-out")-\(scenePhase == .active)") {
            if scenePhase == .active { await appModel.runChatSync() }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: appModel.isAuthenticated)
        .alert(L10n.text("账号与云端服务"), isPresented: Binding(
            get: { appModel.backendMessage != nil },
            set: { if !$0 { appModel.backendMessage = nil } }
        )) {
            Button(L10n.text("知道了"), role: .cancel) { appModel.backendMessage = nil }
        } message: {
            Text(L10n.text(appModel.backendMessage ?? ""))
        }
    }

    private var authenticatedShell: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { HomeDashboardView(appModel: appModel) }
                .toolbar(.hidden, for: .tabBar)
                .tag(AppTab.home)
            NavigationStack { AlbumTreeView(appModel: appModel) }
                .petPalette(.album)
                .toolbar(.hidden, for: .tabBar)
                .tag(AppTab.tree)
            NavigationStack { PetServicesView() }
                .petPalette(.services)
                .toolbar(.hidden, for: .tabBar)
                .tag(AppTab.services)
            NavigationStack { PetMatchView(appModel: appModel) }
                .petPalette(.social)
                .toolbar(.hidden, for: .tabBar)
                .tag(AppTab.match)
            NavigationStack { ProfileHubView(appModel: appModel) }
                .petPalette(.profile)
                .toolbar(.hidden, for: .tabBar)
                .tag(AppTab.profile)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: 4) {
                tab(.home, title: L10n.text("首页"), symbol: "house", selected: "house.fill")
                tab(.tree, title: L10n.text("相册"), symbol: "leaf", selected: "leaf.fill")
                tab(.services, title: L10n.text("服务"), symbol: "square.grid.2x2", selected: "square.grid.2x2.fill")
                tab(.match, title: L10n.text("交友"), symbol: "bubble.left.and.bubble.right", selected: "bubble.left.and.bubble.right.fill")
                tab(.profile, title: L10n.text("我的"), symbol: "person.crop.circle", selected: "person.crop.circle.fill")
            }
            .padding(7)
            .background(.white, in: Capsule())
            .overlay(Capsule().stroke(PetTheme.border.opacity(0.8), lineWidth: 0.7))
            .shadow(color: PetTheme.ink.opacity(0.06), radius: 18, y: 5)
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .background(PetTheme.softBackground.ignoresSafeArea(edges: .bottom))
        }
    }

    private func tab(_ value: AppTab, title: String, symbol: String, selected: String) -> some View {
        let active = selectedTab == value
        let palette: PetPalette = switch value {
        case .home: .neutral
        case .tree: .album
        case .services: .services
        case .match: .social
        case .profile: .profile
        }
        return Button { selectedTab = value } label: {
            VStack(spacing: 5) {
                Image(systemName: active ? selected : symbol)
                    .font(.system(size: 19, weight: .regular))
                Text(L10n.text(title)).font(.system(size: 11, weight: active ? .semibold : .regular))
            }
            .foregroundStyle(active ? palette.ink : PetTheme.secondaryInk)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(active ? palette.surface : .white, in: Capsule())
            .overlay(Capsule().stroke(active ? palette.border : .clear, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(active ? .isSelected : [])
    }
}

#Preview {
    RootTabView(appModel: AppModel())
}
