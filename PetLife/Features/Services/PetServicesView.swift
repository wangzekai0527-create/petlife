import PhotosUI
import SwiftUI
import UIKit

struct PetServicesView: View {
    @Environment(\.locale) private var appLocale
    @State private var selectedCategory: PetServiceCategory = .boarding
    @State private var boardingProviders = BoardingProvider.samples
    @State private var groomingShops = GroomingShop.samples
    @State private var hospitals = PetHospital.samples

    var body: some View {
        let _ = appLocale
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ServiceHero()

                HStack(spacing: 4) {
                    ForEach(PetServiceCategory.allCases, id: \.self) { category in
                        Button { selectedCategory = category } label: {
                            Text(L10n.text(category.title))
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .foregroundStyle(selectedCategory == category ? PetPalette.services.ink : PetPalette.services.secondaryInk)
                                .background(PetPalette.services.surface, in: Capsule())
                                .overlay(Capsule().stroke(selectedCategory == category ? PetPalette.services.ink : .clear, lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selectedCategory == category ? .isSelected : [])
                    }
                }
                .padding(4)
                .background(PetPalette.services.surface, in: Capsule())
                .overlay(Capsule().stroke(PetPalette.services.border, lineWidth: 1))

                switch selectedCategory {
                case .boarding:
                    BoardingSection(providers: $boardingProviders)
                case .grooming:
                    GroomingSection(shops: $groomingShops)
                case .hospital:
                    HospitalSection(hospitals: $hospitals)
                }
            }
            .padding(20)
        }
        .background(PetPalette.services.softBackground)
        .petNavigationTitle(L10n.text("服务"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func handleUpload(_ result: ServiceUploadResult) {
        switch result {
        case .boarding(let provider):
            boardingProviders.insert(provider, at: 0)
            selectedCategory = .boarding
        case .grooming(let shop):
            groomingShops.insert(shop, at: 0)
            selectedCategory = .grooming
        case .hospital(let hospital):
            hospitals.insert(hospital, at: 0)
            selectedCategory = .hospital
        }
    }
}

private enum PetServiceCategory: String, CaseIterable {
    case boarding
    case grooming
    case hospital

    var title: String {
        switch self {
        case .boarding:
            return L10n.text("宠物寄养")
        case .grooming:
            return L10n.text("宠物美容")
        case .hospital:
            return L10n.text("医院预约")
        }
    }

    var uploadTitle: String {
        switch self {
        case .boarding:
            return L10n.text("上传寄养资料")
        case .grooming:
            return L10n.text("上传美容服务")
        case .hospital:
            return L10n.text("上传医院信息")
        }
    }

    var listTitle: String {
        switch self {
        case .boarding:
            return L10n.text("寄养家庭筛选与沟通")
        case .grooming:
            return L10n.text("宠物美容筛选与沟通")
        case .hospital:
            return L10n.text("宠物医院筛选与预约")
        }
    }

    var listDetail: String {
        switch self {
        case .boarding:
            return L10n.text("浏览家庭或店铺上传的环境、寄养条件和适合宠物类型，再联系主人沟通。")
        case .grooming:
            return L10n.text("查看店铺上传的服务项目、环境图片和护理说明，再私信确认档期。")
        case .hospital:
            return L10n.text("查看医院上传的地址、电话、预约项目和诊疗能力，再私信预约时间。")
        }
    }
}

private enum ServiceUploadResult {
    case boarding(BoardingProvider)
    case grooming(GroomingShop)
    case hospital(PetHospital)
}

private struct ServiceHero: View {
    @Environment(\.locale) private var appLocale
    var body: some View {
        let _ = appLocale
        PetPageHeader(title: L10n.text("为它，多一份安心"), subtitle: L10n.text("寄养、美容和就医，先了解，再联系。"), animal: .turtle, usesNeutralText: true)
    }
}

private struct BoardingSection: View {
    @Environment(\.locale) private var appLocale
    @Binding var providers: [BoardingProvider]

    private var visibleProviders: [BoardingProvider] {
        providers.filter { !$0.isUserUploaded }
    }

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 14) {
            ForEach(visibleProviders) { provider in
                NavigationLink {
                    BoardingDetailView(provider: provider, providers: $providers)
                } label: {
                    ServiceProviderCard(
                        title: provider.name,
                        subtitle: provider.type.rawValue,
                        detail: provider.summary,
                        accent: provider.accent,
                        systemImage: provider.type == .shop ? "storefront.fill" : "house.fill",
                        imageAssetPath: provider.imageAssetPath,
                        tags: provider.environmentTags
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct GroomingSection: View {
    @Environment(\.locale) private var appLocale
    @Binding var shops: [GroomingShop]

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 14) {
            ServiceCategoryDescriptionCard(category: .grooming)

            ForEach(shops) { shop in
                GroomingProviderUploadCard(shop: shop, shops: $shops)
            }
        }
    }
}

private struct HospitalSection: View {
    @Environment(\.locale) private var appLocale
    @Binding var hospitals: [PetHospital]

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 14) {
            ServiceCategoryHeader(category: .hospital, uploadAction: handleHospitalUpload)

            ForEach(hospitals) { hospital in
                NavigationLink {
                    HospitalDetailView(hospital: hospital, hospitals: $hospitals)
                } label: {
                    ServiceProviderCard(
                        title: hospital.name,
                        subtitle: hospital.address,
                        detail: hospital.summary,
                        accent: hospital.accent,
                        systemImage: "cross.case.fill",
                        imageAssetPath: hospital.imageAssetPath,
                        tags: hospital.services
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func handleHospitalUpload(_ result: ServiceUploadResult) {
        guard case .hospital(let newHospital) = result else {
            return
        }

        hospitals.insert(newHospital, at: 0)
    }
}

private struct ServiceCategoryHeader: View {
    @Environment(\.locale) private var appLocale
    let category: PetServiceCategory
    let uploadAction: (ServiceUploadResult) -> Void

    var body: some View {
        let _ = appLocale
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(category.listTitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(PetPalette.services.ink)
                Text(category.listDetail)
                    .font(.subheadline)
                    .foregroundStyle(PetPalette.services.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            NavigationLink {
                ServiceUploadForm(category: category, saveAction: uploadAction)
            } label: {
                Label(L10n.text("发布/上传"), systemImage: "plus")
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(PetPalette.services.surface, in: Capsule())
                    .overlay(Capsule().stroke(PetPalette.services.border, lineWidth: 1))
                    .foregroundStyle(PetPalette.services.ink)
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(PetPalette.services.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(PetPalette.services.border, lineWidth: 1))
    }
}

private struct ServiceCategoryDescriptionCard: View {
    @Environment(\.locale) private var appLocale
    let category: PetServiceCategory

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 6) {
            Text(category.listTitle)
                .font(.title3.weight(.semibold))
                .foregroundStyle(PetPalette.services.ink)
            Text(category.listDetail)
                .font(.subheadline)
                .foregroundStyle(PetPalette.services.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PetPalette.services.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(PetPalette.services.border, lineWidth: 1))
    }
}

private struct ServiceProviderCard: View {
    @Environment(\.locale) private var appLocale
    let title: String
    let subtitle: String
    let detail: String
    let accent: AccentToken
    let systemImage: String
    let imageAssetPath: String?
    let tags: [String]

    var body: some View {
        let _ = appLocale
        HStack(alignment: .top, spacing: 14) {
            ServiceImagePreview(
                imageAssetPath: imageAssetPath,
                accent: accent,
                systemImage: systemImage,
                height: 88
            )
            .frame(width: 68)

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text(title))
                    .font(.headline)
                    .foregroundStyle(PetPalette.services.ink)
                    .lineLimit(2)
                Text(L10n.text(subtitle))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PetPalette.services.ink)
                    .lineLimit(2)
                Text(L10n.text(detail))
                    .font(.subheadline)
                    .foregroundStyle(PetPalette.services.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)

                TagWrap(tags: Array(tags.prefix(2)), accent: accent)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(PetPalette.services.secondaryInk)
        }
        .padding(18)
        .background(PetPalette.services.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(PetPalette.services.border, lineWidth: 1))
    }
}

private struct GroomingProviderUploadCard: View {
    @Environment(\.locale) private var appLocale
    let shop: GroomingShop
    @Binding var shops: [GroomingShop]

    var body: some View {
        let _ = appLocale
        HStack(alignment: .top, spacing: 14) {
            NavigationLink {
                GroomingDetailView(shop: shop, shops: $shops)
            } label: {
                HStack(alignment: .top, spacing: 14) {
                    ServiceImagePreview(
                        imageAssetPath: shop.imageAssetPath,
                        accent: shop.accent,
                        systemImage: "scissors",
                        height: 88
                    )
                    .frame(width: 92)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.text(shop.name))
                            .font(.headline)
                            .foregroundStyle(PetPalette.services.ink)
                            .lineLimit(2)
                        Text(L10n.text(shop.address))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(PetPalette.services.ink)
                            .lineLimit(2)
                        Text(L10n.text(shop.summary))
                            .font(.subheadline)
                            .foregroundStyle(PetPalette.services.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(3)

                        TagWrap(tags: Array(shop.highlights.prefix(3)), accent: shop.accent)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 12) {
                NavigationLink {
                    ServiceUploadForm(category: .grooming, saveAction: handleGroomingUpload)
                } label: {
                    Label(L10n.text("发布/上传"), systemImage: "plus")
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 8)
                        .background(PetPalette.services.surface, in: Capsule())
                        .overlay(Capsule().stroke(PetPalette.services.border, lineWidth: 1))
                        .foregroundStyle(PetPalette.services.ink)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    GroomingDetailView(shop: shop, shops: $shops)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PetPalette.services.secondaryInk)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(PetPalette.services.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(PetPalette.services.border, lineWidth: 1))
    }

    private func handleGroomingUpload(_ result: ServiceUploadResult) {
        guard case .grooming(let newShop) = result else {
            return
        }

        shops.insert(newShop, at: 0)
    }
}

private struct BoardingDetailView: View {
    @Environment(\.locale) private var appLocale
    let provider: BoardingProvider
    @Binding var providers: [BoardingProvider]

    var body: some View {
        let _ = appLocale
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ServiceCategoryHeader(category: .boarding, uploadAction: handleBoardingUpload)

                BoardingDetailHeader(provider: provider)

                if provider.type == .home {
                    HomeProviderChoicesSection(
                        currentProviderID: provider.id,
                        providers: $providers
                    )
                }

                CompactDetailBlock(title: L10n.text("环境标签"), rows: provider.environmentTags)
                DetailBlock(title: L10n.text("寄养条件"), rows: provider.conditions)
                DetailBlock(title: L10n.text("适合宠物"), rows: provider.petFit)
            }
            .padding(20)
            .padding(.bottom, 88)
        }
        .background(PetPalette.services.softBackground)
        .petNavigationTitle(L10n.text("寄养详情"))
        .safeAreaInset(edge: .bottom) {
            DetailContactBar(title: provider.name, accent: provider.accent, label: L10n.text("联系主人"))
        }
    }

    private func handleBoardingUpload(_ result: ServiceUploadResult) {
        guard case .boarding(let newProvider) = result else {
            return
        }

        providers.insert(newProvider, at: 0)
    }
}

private struct BoardingDetailHeader: View {
    @Environment(\.locale) private var appLocale
    let provider: BoardingProvider

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 22) {
            ServiceImagePreview(
                imageAssetPath: provider.imageAssetPath,
                accent: provider.accent,
                systemImage: provider.type == .shop ? "storefront.fill" : "house.fill",
                height: 178
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text(provider.name))
                    .font(.system(size: 38, weight: .bold, design: .default))
                    .foregroundStyle(PetPalette.services.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(L10n.text(provider.type.rawValue))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(PetPalette.services.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct HomeProviderChoicesSection: View {
    @Environment(\.locale) private var appLocale
    let currentProviderID: UUID
    @Binding var providers: [BoardingProvider]

    private var homeProviders: [BoardingProvider] {
        providers.filter { $0.type == .home && $0.id != currentProviderID }
    }

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.text("个人家庭可选列表"))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(PetPalette.services.ink)

                Text(L10n.text("上传后的家庭图片、寄养情况和适合宠物会展示在这里，方便用户自行比较选择。"))
                    .font(.subheadline)
                    .foregroundStyle(PetPalette.services.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if homeProviders.isEmpty {
                Text(L10n.text("暂无个人家庭资料，点击上方发布/上传后会显示在这里。"))
                    .font(.subheadline)
                    .foregroundStyle(PetPalette.services.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(PetPalette.services.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(PetPalette.services.border, lineWidth: 1))
            } else {
                ForEach(homeProviders) { provider in
                    NavigationLink {
                        BoardingDetailView(provider: provider, providers: $providers)
                    } label: {
                        UploadedHomeProviderCard(provider: provider)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct UploadedHomeProviderCard: View {
    @Environment(\.locale) private var appLocale
    let provider: BoardingProvider

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 12) {
            ServiceImagePreview(
                imageAssetPath: provider.imageAssetPath,
                accent: provider.accent,
                systemImage: "house.fill",
                height: 150
            )

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(L10n.text(provider.name))
                    .font(.headline)
                    .foregroundStyle(PetPalette.services.ink)
                    .lineLimit(2)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PetPalette.services.secondaryInk)
            }

            Text(L10n.text(provider.summary))
                .font(.subheadline)
                .foregroundStyle(PetPalette.services.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)

            TagWrap(tags: Array(provider.environmentTags.prefix(3)), accent: provider.accent)

            if !provider.conditions.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    Text(L10n.text("寄养情况"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PetPalette.services.ink)

                    ForEach(Array(provider.conditions.prefix(2)), id: \.self) { condition in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(PetPalette.services.ink)
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)

                            Text(condition)
                                .font(.caption)
                                .foregroundStyle(PetPalette.services.secondaryInk)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(PetPalette.services.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(PetPalette.services.border, lineWidth: 1))
    }
}

private struct GroomingDetailView: View {
    @Environment(\.locale) private var appLocale
    let shop: GroomingShop
    @Binding var shops: [GroomingShop]

    var body: some View {
        let _ = appLocale
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ServiceCategoryHeader(category: .grooming, uploadAction: handleGroomingUpload)

                ServiceVisualHeader(
                    title: shop.name,
                    subtitle: shop.address,
                    accent: shop.accent,
                    systemImage: "scissors",
                    imageAssetPath: shop.imageAssetPath
                )

                DetailBlock(title: L10n.text("店铺上传服务"), rows: shop.uploadedServices)

                GroomingShopChoicesSection(currentShopID: shop.id, shops: $shops)

                DetailBlock(title: L10n.text("1. 基础护理 Basic Grooming"), rows: [
                    L10n.text("洗澡与吹干：使用宠物专用洗发露和护发素，彻底清洁并吹干毛发，帮助预防皮肤问题。"),
                    L10n.text("修剪指甲：专业修剪或磨光，防止指甲过长导致行走困难或嵌入肉垫。"),
                    L10n.text("清理耳朵：清除耳垢，必要时拔除耳毛，帮助预防耳道感染。"),
                    L10n.text("挤肛门腺：减轻宠物瘙痒感，降低腺体发炎风险。"),
                    L10n.text("眼部清理：清理泪痕和眼角分泌物。")
                ])

                DetailBlock(title: L10n.text("2. 修剪与造型 Trimming & Styling"), rows: [
                    L10n.text("全身体毛修剪：针对长毛品种修剪特定造型，例如贵宾的泰迪装。"),
                    L10n.text("卫生区域修剪：修剪脚底毛、腹部毛和肛门周围毛发，保持整洁。"),
                    L10n.text("去废毛 De-shedding：换毛期使用专业工具去除深层死毛，减少家中掉毛。")
                ])

                DetailBlock(title: L10n.text("3. 特色 SPA 与高端服务"), rows: [
                    L10n.text("药浴：针对皮肤敏感或有皮肤问题的宠物使用特定药水。"),
                    L10n.text("美牙服务：刷牙或洁牙，帮助改善口臭和牙结石。"),
                    L10n.text("香薰/精油 SPA：缓解宠物压力，滋养皮肤。"),
                    L10n.text("染色美容：使用安全颜料对耳朵、尾巴进行创意染色。")
                ])
            }
            .padding(20)
            .padding(.bottom, 88)
        }
        .background(PetPalette.services.softBackground)
        .petNavigationTitle(L10n.text("美容服务"))
        .safeAreaInset(edge: .bottom) {
            DetailContactBar(title: shop.name, accent: shop.accent, label: L10n.text("联系店铺"))
        }
    }

    private func handleGroomingUpload(_ result: ServiceUploadResult) {
        guard case .grooming(let newShop) = result else {
            return
        }

        shops.insert(newShop, at: 0)
    }
}

private struct GroomingShopChoicesSection: View {
    @Environment(\.locale) private var appLocale
    let currentShopID: UUID
    @Binding var shops: [GroomingShop]

    private var otherShops: [GroomingShop] {
        shops.filter { $0.id != currentShopID }
    }

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.text("可选美容店铺"))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(PetPalette.services.ink)

                Text(L10n.text("上传后的店铺图片、服务项目和护理说明会展示在这里，方便用户比较后私信确认档期。"))
                    .font(.subheadline)
                    .foregroundStyle(PetPalette.services.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if otherShops.isEmpty {
                Text(L10n.text("暂无其他美容店铺资料，点击上方发布/上传后会显示在这里。"))
                    .font(.subheadline)
                    .foregroundStyle(PetPalette.services.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(PetPalette.services.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(PetPalette.services.border, lineWidth: 1))
            } else {
                ForEach(otherShops) { shop in
                    NavigationLink {
                        GroomingDetailView(shop: shop, shops: $shops)
                    } label: {
                        GroomingShopChoiceCard(shop: shop)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct GroomingShopChoiceCard: View {
    @Environment(\.locale) private var appLocale
    let shop: GroomingShop

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 12) {
            ServiceImagePreview(
                imageAssetPath: shop.imageAssetPath,
                accent: shop.accent,
                systemImage: "scissors",
                height: 150
            )

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(L10n.text(shop.name))
                    .font(.headline)
                    .foregroundStyle(PetPalette.services.ink)
                    .lineLimit(2)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PetPalette.services.secondaryInk)
            }

            Text(L10n.text(shop.summary))
                .font(.subheadline)
                .foregroundStyle(PetPalette.services.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)

            TagWrap(tags: Array(shop.highlights.prefix(3)), accent: shop.accent)

            if !shop.uploadedServices.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    Text(L10n.text("店铺服务"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PetPalette.services.ink)

                    ForEach(Array(shop.uploadedServices.prefix(2)), id: \.self) { service in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(PetPalette.services.ink)
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)

                            Text(service)
                                .font(.caption)
                                .foregroundStyle(PetPalette.services.secondaryInk)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(PetPalette.services.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(PetPalette.services.border, lineWidth: 1))
    }
}

private struct HospitalDetailView: View {
    @Environment(\.locale) private var appLocale
    let hospital: PetHospital
    @Binding var hospitals: [PetHospital]

    var body: some View {
        let _ = appLocale
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ServiceCategoryHeader(category: .hospital, uploadAction: handleHospitalUpload)

                ServiceVisualHeader(
                    title: hospital.name,
                    subtitle: hospital.address,
                    accent: hospital.accent,
                    systemImage: "cross.case.fill",
                    imageAssetPath: hospital.imageAssetPath
                )

                VStack(alignment: .leading, spacing: 10) {
                    ContactRow(icon: "mappin.and.ellipse", text: hospital.address)
                    ContactRow(icon: "phone.fill", text: hospital.phone)
                }
                .padding(18)
                .background(PetPalette.services.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(PetPalette.services.border, lineWidth: 1))

                DetailBlock(title: L10n.text("可预约项目"), rows: hospital.services)
                HospitalChoicesSection(currentHospitalID: hospital.id, hospitals: $hospitals)
                DetailBlock(title: L10n.text("医院能力"), rows: hospital.capabilities)
            }
            .padding(20)
            .padding(.bottom, 88)
        }
        .background(PetPalette.services.softBackground)
        .petNavigationTitle(L10n.text("医院预约"))
        .safeAreaInset(edge: .bottom) {
            DetailContactBar(title: hospital.name, accent: hospital.accent, label: L10n.text("发起咨询"))
        }
    }

    private func handleHospitalUpload(_ result: ServiceUploadResult) {
        guard case .hospital(let newHospital) = result else {
            return
        }

        hospitals.insert(newHospital, at: 0)
    }
}

private struct HospitalChoicesSection: View {
    @Environment(\.locale) private var appLocale
    let currentHospitalID: UUID
    @Binding var hospitals: [PetHospital]

    private var otherHospitals: [PetHospital] {
        hospitals.filter { $0.id != currentHospitalID }
    }

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.text("可选宠物医院"))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(PetPalette.services.ink)

                Text(L10n.text("上传后的医院地址、电话、预约项目和诊疗能力会展示在这里，方便用户比较后预约时间。"))
                    .font(.subheadline)
                    .foregroundStyle(PetPalette.services.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if otherHospitals.isEmpty {
                Text(L10n.text("暂无其他医院资料，点击上方发布/上传后会显示在这里。"))
                    .font(.subheadline)
                    .foregroundStyle(PetPalette.services.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(PetPalette.services.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(PetPalette.services.border, lineWidth: 1))
            } else {
                ForEach(otherHospitals) { hospital in
                    NavigationLink {
                        HospitalDetailView(hospital: hospital, hospitals: $hospitals)
                    } label: {
                        HospitalChoiceCard(hospital: hospital)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct HospitalChoiceCard: View {
    @Environment(\.locale) private var appLocale
    let hospital: PetHospital

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 12) {
            ServiceImagePreview(
                imageAssetPath: hospital.imageAssetPath,
                accent: hospital.accent,
                systemImage: "cross.case.fill",
                height: 150
            )

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(L10n.text(hospital.name))
                    .font(.headline)
                    .foregroundStyle(PetPalette.services.ink)
                    .lineLimit(2)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PetPalette.services.secondaryInk)
            }

            ContactRow(icon: "mappin.and.ellipse", text: hospital.address)
            ContactRow(icon: "phone.fill", text: hospital.phone)

            Text(L10n.text(hospital.summary))
                .font(.subheadline)
                .foregroundStyle(PetPalette.services.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)

            TagWrap(tags: Array(hospital.services.prefix(3)), accent: hospital.accent)

            if !hospital.capabilities.isEmpty {
                VStack(alignment: .leading, spacing: 7) {
                    Text(L10n.text("诊疗能力"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PetPalette.services.ink)

                    ForEach(Array(hospital.capabilities.prefix(2)), id: \.self) { capability in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(PetPalette.services.ink)
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)

                            Text(L10n.text(capability))
                                .font(.caption)
                                .foregroundStyle(PetPalette.services.secondaryInk)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(PetPalette.services.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(PetPalette.services.border, lineWidth: 1))
    }
}

private struct DetailContactBar: View {
    @Environment(\.locale) private var appLocale
    let title: String
    let accent: AccentToken
    let label: String

    var body: some View {
        let _ = appLocale
        NavigationLink {
            ServiceConversationView(title: title, accent: accent)
        } label: {
            Label(L10n.text(label), systemImage: "message.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(PetCompactButtonStyle())
        .foregroundStyle(PetPalette.services.ink)
        .tint(PetPalette.services.ink)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
    }
}

private struct ServiceVisualHeader: View {
    @Environment(\.locale) private var appLocale
    let title: String
    let subtitle: String
    let accent: AccentToken
    let systemImage: String
    let imageAssetPath: String?

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 16) {
            ServiceImagePreview(
                imageAssetPath: imageAssetPath,
                accent: accent,
                systemImage: systemImage,
                height: 230
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text(title))
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(PetPalette.services.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(L10n.text(subtitle))
                    .font(.headline)
                    .foregroundStyle(PetPalette.services.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct ServiceUploadForm: View {
    @Environment(\.locale) private var appLocale
    let category: PetServiceCategory
    let saveAction: (ServiceUploadResult) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var imageAssetPath: String?
    @State private var importErrorMessage: String?

    @State private var providerType: BoardingProvider.ProviderType = .home
    @State private var name = ""
    @State private var address = ""
    @State private var phone = ""
    @State private var summary = ""
    @State private var environmentTagsText = L10n.text("无幼童 封闭阳台 每日反馈")
    @State private var conditionsText = ""
    @State private var petFitText = ""
    @State private var servicesText = ""
    @State private var capabilitiesText = ""

    var body: some View {
        let _ = appLocale
        Form {
            Section(L10n.text("基础信息")) {
                if category == .boarding {
                    Picker(L10n.text("类型"), selection: $providerType) {
                        ForEach(BoardingProvider.ProviderType.allCases, id: \.self) { type in
                            Text(L10n.text(type.rawValue)).tag(type)
                        }
                    }
                }

                TextField(defaultNamePrompt, text: $name)
                if category != .boarding {
                    TextField(L10n.text("地址"), text: $address)
                }
                if category == .hospital {
                    TextField(L10n.text("联系电话"), text: $phone)
                }
                TextField(L10n.text("简短描述"), text: $summary, axis: .vertical)
            }

            Section(imageSectionTitle) {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label(imageAssetPath == nil ? L10n.text("选择图片") : L10n.text("更换图片"), systemImage: "photo")
                }

                ServiceImagePreview(
                    imageAssetPath: imageAssetPath,
                    accent: .sky,
                    systemImage: category.placeholderIcon,
                    height: 180
                )
                .padding(.vertical, 4)

                if let importErrorMessage {
                    Text(L10n.text(importErrorMessage))
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            switch category {
            case .boarding:
                Section(L10n.text("寄养筛选信息")) {
                    TextField(L10n.text("环境标签，空格分隔"), text: $environmentTagsText)
                    TextField(L10n.text("寄养条件，每行一条"), text: $conditionsText, axis: .vertical)
                    TextField(L10n.text("适合宠物类型，每行一条"), text: $petFitText, axis: .vertical)
                }
            case .grooming:
                Section(L10n.text("店铺服务")) {
                    TextField(L10n.text("服务标签，空格分隔"), text: $environmentTagsText)
                    TextField(L10n.text("可提供服务，每行一条"), text: $servicesText, axis: .vertical)
                }
            case .hospital:
                Section(L10n.text("医院预约信息")) {
                    TextField(L10n.text("可预约项目，空格分隔"), text: $servicesText)
                    TextField(L10n.text("医院能力，每行一条"), text: $capabilitiesText, axis: .vertical)
                }
            }
        }
        .petNavigationTitle(category.uploadTitle)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.text("发布"), action: save)
                    .disabled(!canSave)
            }
        }
        .task(id: selectedPhotoItem) {
            await importSelectedPhoto()
        }
        .onAppear(perform: applyDefaults)
    }

    private var defaultNamePrompt: String {
        switch category {
        case .boarding:
            return L10n.text("家庭或店铺名称")
        case .grooming:
            return L10n.text("宠物店铺名称")
        case .hospital:
            return L10n.text("宠物医院名称")
        }
    }

    private var imageSectionTitle: String {
        switch category {
        case .boarding:
            return L10n.text("环境图片")
        case .grooming:
            return L10n.text("店铺图片")
        case .hospital:
            return L10n.text("医院图片")
        }
    }

    private var canSave: Bool {
        let hasBase = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        switch category {
        case .boarding:
            return hasBase
        case .grooming:
            return hasBase && !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .hospital:
            return hasBase &&
                !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func applyDefaults() {
        guard conditionsText.isEmpty, petFitText.isEmpty, servicesText.isEmpty, capabilitiesText.isEmpty else {
            return
        }

        switch category {
        case .boarding:
            conditionsText = L10n.text("提供独立休息空间\n每天照片反馈\n可按宠物习惯喂食")
            petFitText = L10n.text("适合小型犬\n适合性格稳定的猫咪")
        case .grooming:
            environmentTagsText = L10n.text("基础护理 造型修剪 特色SPA")
            servicesText = L10n.text("洗澡与吹干\n修剪指甲\n清理耳朵\n去废毛\n药浴和美牙服务")
        case .hospital:
            environmentTagsText = L10n.text("体检 健康管理 疫苗")
            servicesText = L10n.text("宠物体检 宠物健康管理 疫苗接种")
            capabilitiesText = L10n.text("提供基础体检、血常规和生化检查\n支持长期健康档案管理\n可提前沟通宠物病史和预约时间")
        }
    }

    private func save() {
        let cleanName = trimmed(name)
        let cleanSummary = trimmed(summary)
        let cleanAddress = trimmed(address)
        let cleanPhone = trimmed(phone)

        switch category {
        case .boarding:
            saveAction(.boarding(BoardingProvider(
                name: cleanName,
                type: providerType,
                summary: cleanSummary,
                imageAssetPath: imageAssetPath,
                environmentTags: splitTags(environmentTagsText),
                conditions: splitLines(conditionsText),
                petFit: splitLines(petFitText),
                accent: providerType == .home ? .mint : .sky,
                isUserUploaded: true
            )))
        case .grooming:
            let uploadedServices = splitLines(servicesText)
            saveAction(.grooming(GroomingShop(
                name: cleanName,
                address: cleanAddress,
                summary: cleanSummary,
                imageAssetPath: imageAssetPath,
                highlights: splitTags(environmentTagsText),
                uploadedServices: uploadedServices.isEmpty ? [L10n.text("基础护理"), L10n.text("修剪与造型")] : uploadedServices,
                accent: .peach
            )))
        case .hospital:
            saveAction(.hospital(PetHospital(
                name: cleanName,
                address: cleanAddress,
                phone: cleanPhone,
                summary: cleanSummary,
                imageAssetPath: imageAssetPath,
                services: splitTags(servicesText),
                capabilities: splitLines(capabilitiesText),
                accent: .ember
            )))
        }

        dismiss()
    }

    private func importSelectedPhoto() async {
        guard let selectedPhotoItem else {
            return
        }

        do {
            guard let imageData = try await selectedPhotoItem.loadTransferable(type: Data.self) else {
                importErrorMessage = L10n.text("图片读取失败，请重新选择。")
                return
            }

            let ext = selectedPhotoItem.supportedContentTypes.first?.preferredFilenameExtension ?? "jpg"
            imageAssetPath = try MemoryAssetStore.saveImageData(imageData, preferredExtension: ext)
            importErrorMessage = nil
        } catch {
            importErrorMessage = L10n.text("图片导入失败：\(error.localizedDescription)")
        }
    }
}

private extension PetServiceCategory {
    var placeholderIcon: String {
        switch self {
        case .boarding:
            return "house.fill"
        case .grooming:
            return "scissors"
        case .hospital:
            return "cross.case.fill"
        }
    }
}

private struct DetailBlock: View {
    @Environment(\.locale) private var appLocale
    let title: String
    let rows: [String]

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text(title))
                .font(.title3.weight(.semibold))
                .foregroundStyle(PetPalette.services.ink)

            ForEach(rows.isEmpty ? [L10n.text("暂无补充内容")] : rows, id: \.self) { row in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(PetPalette.services.ink)
                        .frame(width: 7, height: 7)
                        .padding(.top, 7)

                    Text(L10n.text(row))
                        .font(.subheadline)
                        .foregroundStyle(PetPalette.services.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(18)
        .background(PetPalette.services.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(PetPalette.services.border, lineWidth: 1))
    }
}

private struct CompactDetailBlock: View {
    @Environment(\.locale) private var appLocale
    let title: String
    let rows: [String]

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text(title))
                .font(.title3.weight(.semibold))
                .foregroundStyle(PetPalette.services.ink)

            ForEach(rows.isEmpty ? [L10n.text("暂无补充内容")] : rows, id: \.self) { row in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(PetPalette.services.ink)
                        .frame(width: 7, height: 7)
                        .padding(.top, 7)

                    Text(L10n.text(row))
                        .font(.subheadline)
                        .foregroundStyle(PetPalette.services.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: 190, alignment: .leading)
        .background(PetPalette.services.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(PetPalette.services.border, lineWidth: 1))
    }
}

private struct ServiceImagePreview: View {
    @Environment(\.locale) private var appLocale
    let imageAssetPath: String?
    let accent: AccentToken
    let systemImage: String
    let height: CGFloat

    var body: some View {
        let _ = appLocale
        Group {
            if
                let imageAssetPath,
                let imageURL = MemoryAssetStore.url(for: imageAssetPath),
                let image = UIImage(contentsOfFile: imageURL.path)
            {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        PetPalette.services.surface
                    )
                    .overlay(
                        PetDoodle(animal: systemImage.contains("house") ? .dog : systemImage.contains("cross") ? .bird : .turtle)
                            .frame(width: min(height * 0.72, 118), height: min(height * 0.72, 118))
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct ContactRow: View {
    @Environment(\.locale) private var appLocale
    let icon: String
    let text: String

    var body: some View {
        let _ = appLocale
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(PetPalette.services.ink)
                .frame(width: 22)
            Text(L10n.text(text))
                .font(.subheadline)
                .foregroundStyle(PetPalette.services.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct TagWrap: View {
    @Environment(\.locale) private var appLocale
    let tags: [String]
    let accent: AccentToken

    var body: some View {
        let _ = appLocale
        PetFlowLayout(spacing: 6) {
            ForEach(tags.isEmpty ? [L10n.text("待完善")] : tags, id: \.self) { tag in
                Text(L10n.text(tag))
                    .font(.caption)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(PetPalette.services.surface, in: Capsule())
                    .overlay(Capsule().stroke(PetPalette.services.border, lineWidth: 1))
                    .foregroundStyle(PetPalette.services.ink)
            }
        }
    }
}

private struct ServiceConversationView: View {
    @Environment(\.locale) private var appLocale
    let title: String
    let accent: AccentToken
    var body: some View {
        let _ = appLocale
        ContentUnavailableView(L10n.text("服务方尚未接入在线聊天"), systemImage: "bubble.left.and.bubble.right",
            description: Text(L10n.text("此服务目前为展示资料，尚无可接收消息的商家账号。请使用服务资料中的联系方式。")))
            .petNavigationTitle(title)
    }
}

private struct BoardingProvider: Identifiable, Hashable {
    enum ProviderType: String, CaseIterable, Hashable {
        case shop = "宠物店铺寄养"
        case home = "个人家庭寄养"
    }

    let id = UUID()
    var name: String
    var type: ProviderType
    var summary: String
    var imageAssetPath: String?
    var environmentTags: [String]
    var conditions: [String]
    var petFit: [String]
    var accent: AccentToken
    var isUserUploaded = false

    static let samples: [BoardingProvider] = [
        BoardingProvider(
            name: "暖爪家庭寄养",
            type: .home,
            summary: "家庭式照护，每天上传照片和散步记录，只接小型犬和性格稳定的猫咪。",
            imageAssetPath: nil,
            environmentTags: ["无幼童", "封闭阳台", "每日反馈"],
            conditions: [
                "提供客厅活动区、独立睡眠垫和饮水点。",
                "寄养前需要疫苗记录和基础驱虫记录。",
                "每天至少两次照片反馈，可沟通喂食习惯。"
            ],
            petFit: [
                "适合 12kg 以下小型犬。",
                "适合胆子较小、需要安静环境的猫咪。",
                "暂不接有明显攻击行为的宠物。"
            ],
            accent: .mint
        ),
        BoardingProvider(
            name: "PawCare 宠物店寄养",
            type: .shop,
            summary: "门店寄养，有独立笼位、夜间巡查和基础清洁服务，适合短期出差托管。",
            imageAssetPath: nil,
            environmentTags: ["独立笼位", "夜间巡查", "可加洗护"],
            conditions: [
                "店铺提供小型、中型和大型独立寄养空间。",
                "支持自带粮食、药品和常用玩具。",
                "寄养期间可加购洗澡、修甲和耳道清理。"
            ],
            petFit: [
                "适合短期旅行、出差期间托管。",
                "适合需要规律喂药或固定喂食时间的宠物。",
                "大型犬需提前沟通体型和活动需求。"
            ],
            accent: .sky
        )
    ]
}

private struct GroomingShop: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var address: String
    var summary: String
    var imageAssetPath: String?
    var highlights: [String]
    var uploadedServices: [String]
    var accent: AccentToken

    static let samples: [GroomingShop] = [
        GroomingShop(
            name: "毛球造型研究所",
            address: "上海市徐汇区宠爱路 88 号",
            summary: "提供日常洗护、品种造型、去废毛、药浴和美牙护理，可先沟通宠物性格。",
            imageAssetPath: nil,
            highlights: ["基础护理", "造型修剪", "特色SPA"],
            uploadedServices: [
                "基础护理：洗澡、吹干、修剪指甲、清理耳朵。",
                "修剪与造型：全身体毛修剪、卫生区域修剪、去废毛。",
                "特色 SPA：药浴、美牙、香薰护理和安全染色。"
            ],
            accent: .peach
        ),
        GroomingShop(
            name: "Little Paw 精致洗护",
            address: "杭州市西湖区湖畔街 26 号",
            summary: "主打低刺激洗护和猫咪友好护理，支持预约独立时段。",
            imageAssetPath: nil,
            highlights: ["低刺激", "猫咪友好", "美牙"],
            uploadedServices: [
                "低刺激洗护：使用温和洗护用品，适合敏感皮肤宠物。",
                "猫咪友好护理：预约独立时段，减少等候和应激。",
                "美牙护理：刷牙、口腔清洁和口气管理。"
            ],
            accent: .plum
        )
    ]
}

private struct PetHospital: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var address: String
    var phone: String
    var summary: String
    var imageAssetPath: String?
    var services: [String]
    var capabilities: [String]
    var accent: AccentToken

    static let samples: [PetHospital] = [
        PetHospital(
            name: "安安宠物医院",
            address: "上海市静安区康宁路 168 号",
            phone: "021-6677-8899",
            summary: "支持宠物体检、疫苗、皮肤科、口腔检查和慢病健康管理预约。",
            imageAssetPath: nil,
            services: ["宠物体检", "宠物健康管理", "疫苗接种"],
            capabilities: [
                "提供基础体检、血常规、生化检查和影像检查。",
                "可建立长期健康档案，定期提醒复诊。",
                "支持猫犬常见皮肤问题和口腔问题初诊。"
            ],
            accent: .ember
        ),
        PetHospital(
            name: "青禾动物医疗中心",
            address: "杭州市滨江区月明路 39 号",
            phone: "0571-8866-1234",
            summary: "提供健康管理、术前评估、老年宠物检查和营养咨询。",
            imageAssetPath: nil,
            services: ["老年体检", "术前评估", "营养咨询"],
            capabilities: [
                "适合老年宠物年度检查和慢病复查。",
                "提供体重管理、饮食建议和护理方案。",
                "预约后可提前沟通宠物病史和检查项目。"
            ],
            accent: .pine
        )
    ]
}

private func trimmed(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines)
}

private func splitTags(_ text: String) -> [String] {
    text
        .split(whereSeparator: { $0.isWhitespace || $0 == "，" || $0 == "," || $0 == "、" })
        .map { String($0) }
        .filter { !$0.isEmpty }
}

private func splitLines(_ text: String) -> [String] {
    text
        .split(whereSeparator: \.isNewline)
        .map { trimmed(String($0)) }
        .filter { !$0.isEmpty }
}

#Preview {
    NavigationStack {
        PetServicesView()
    }
}
