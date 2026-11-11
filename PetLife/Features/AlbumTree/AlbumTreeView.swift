import AVFoundation
import AVKit
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct AlbumTreeView: View {
    @Environment(\.locale) private var appLocale
    let appModel: AppModel

    @State private var isShowingMemorySheet = false
    @State private var memoryDraft = MemoryDraft()

    var body: some View {
        let _ = appLocale
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TreeHeroHeader(addAction: {
                    isShowingMemorySheet = true
                })

                if appModel.holidayMemories.isEmpty {
                    EmptyTimelineCard(addAction: {
                        isShowingMemorySheet = true
                    })
                } else {
                    ForEach(Array(appModel.holidayMemories.enumerated()), id: \.element.id) { index, memory in
                        NavigationLink {
                            MemoryDetailView(appModel: appModel, memoryID: memory.id)
                        } label: {
                            TimelineMemoryCard(
                                memory: memory,
                                showsStem: index < appModel.holidayMemories.count - 1
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .background(PetPalette.album.softBackground)
        .petNavigationTitle(L10n.text("相册树"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.text("新增记录")) {
                    isShowingMemorySheet = true
                }
            }
        }
        .sheet(isPresented: $isShowingMemorySheet) {
            AddMemorySheet(
                draft: $memoryDraft,
                isBusy: appModel.isBusy,
                saveAction: handleAddMemory
            )
        }
    }

    private func handleAddMemory() {
        let draftToSave = memoryDraft
        Task {
            await appModel.addMemory(draftToSave)
            memoryDraft = MemoryDraft()
            isShowingMemorySheet = false
        }
    }
}

private struct TreeHeroHeader: View {
    @Environment(\.locale) private var appLocale
    let addAction: () -> Void
    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 16) {
            PetPageHeader(title: L10n.text("慢慢长大，慢慢记录"), subtitle: L10n.text("照片、声音和文字，留住每一段日常。"), animal: .bird, usesNeutralText: true)
            Button(action: addAction) {
                Label(L10n.text("记录今天"), systemImage: "plus")
            }
            .buttonStyle(PetPrimaryButtonStyle())
        }
    }
}

private struct EmptyTimelineCard: View {
    @Environment(\.locale) private var appLocale
    let addAction: () -> Void

    var body: some View {
        let _ = appLocale
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text("还没有成长记录"))
                .font(.headline)
                .foregroundStyle(PetPalette.album.ink)
            Text(L10n.text("发布第一张照片或第一段视频后，它会出现在这里。"))
                .font(.subheadline)
                .foregroundStyle(PetPalette.album.secondaryInk)
            Button(L10n.text("新增记录"), action: addAction)
                .buttonStyle(PetCompactButtonStyle())
                .foregroundStyle(PetPalette.album.ink)
                .tint(PetPalette.album.ink)
                .tint(PetPalette.album.pine)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(PetPalette.album.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(PetPalette.album.border, lineWidth: 1))
    }
}

private struct TimelineMemoryCard: View {
    @Environment(\.locale) private var appLocale
    let memory: HolidayMemory
    let showsStem: Bool

    private var badges: [String] {
        [
            memory.mediaKind.rawValue,
            L10n.text("\(memory.notes.count) 条补充"),
            L10n.text("成长节点")
        ]
    }

    var body: some View {
        let _ = appLocale
        HStack(alignment: .center, spacing: 14) {
            VStack(spacing: 0) {
                Circle()
                    .fill(PetPalette.album.surface)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Image(systemName: memory.mediaKind == .video ? "play.fill" : "camera.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(PetPalette.album.ink)
                    )

                if showsStem {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(PetPalette.album.ink)
                        .frame(width: 4, height: 98)
                        .padding(.top, 4)
                }
            }

            HStack(alignment: .top, spacing: 14) {
                MemoryMediaPreview(memory: memory, height: 96)
                    .frame(width: 104)

                VStack(alignment: .leading, spacing: 10) {
                    Text(memory.dateText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PetPalette.album.ink)

                    Text(memory.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(PetPalette.album.ink)
                        .lineLimit(2)

                    Text(memory.subtitle.isEmpty ? memory.story : memory.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(PetPalette.album.secondaryInk)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)

                    PetFlowLayout(spacing: 6) {
                        ForEach(badges, id: \.self) { badge in
                            MiniBadge(label: badge)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PetPalette.album.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(PetPalette.album.border, lineWidth: 1))
        }
    }
}

private struct MemoryDetailView: View {
    @Environment(\.locale) private var appLocale
    let appModel: AppModel
    let memoryID: UUID

    @State private var noteText = ""

    private var memory: HolidayMemory? {
        appModel.memory(for: memoryID)
    }

    var body: some View {
        let _ = appLocale
        ScrollView {
            if let memory {
                VStack(alignment: .leading, spacing: 18) {
                    MemoryMediaPreview(memory: memory, height: 320)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(memory.title)
                            .font(.largeTitle.weight(.bold))
                        Text(memory.dateText)
                            .font(.headline)
                            .foregroundStyle(PetPalette.album.ink)
                        Text(memory.story)
                            .font(.body)
                            .foregroundStyle(PetPalette.album.secondaryInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.text("记录文字"))
                            .font(.title3.weight(.semibold))

                        ForEach(memory.notes) { note in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(note.body)
                                    .font(.subheadline)
                                    .foregroundStyle(PetPalette.album.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(L10n.text(note.createdAtText))
                                    .font(.caption)
                                    .foregroundStyle(PetPalette.album.secondaryInk)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(PetPalette.album.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(PetPalette.album.border, lineWidth: 1))
                        }

                        TextField(L10n.text("继续补充这段成长故事"), text: $noteText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)

                        Button(L10n.text("新增文字记录"), action: handleAddNote)
                            .buttonStyle(PetCompactButtonStyle())
                            .foregroundStyle(PetPalette.album.ink)
                            .tint(PetPalette.album.ink)
                            .tint(PetPalette.album.pine)
                            .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(20)
            }
        }
        .background(PetPalette.album.softBackground)
        .petNavigationTitle(L10n.text("成长详情"))
    }

    private func handleAddNote() {
        let text = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return
        }

        appModel.addMemoryNote(memoryID: memoryID, text: text)
        noteText = ""
    }
}

private struct AddMemorySheet: View {
    @Environment(\.locale) private var appLocale
    @Binding var draft: MemoryDraft
    let isBusy: Bool
    let saveAction: () -> Void

    @State private var selectedMediaItem: PhotosPickerItem?
    @State private var isImportingMedia = false
    @State private var importErrorMessage: String?

    var body: some View {
        let _ = appLocale
        NavigationStack {
            Form {
                Section(L10n.text("基础信息")) {
                    TextField(L10n.text("标题"), text: $draft.title)
                    TextField(L10n.text("简短说明"), text: $draft.subtitle)
                    TextField(L10n.text("日期"), text: $draft.dateText)
                }

                Section(L10n.text("记录内容")) {
                    TextField(L10n.text("写下这次成长故事"), text: $draft.story, axis: .vertical)
                }

                Section(L10n.text("照片或视频")) {
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
                            draft.mediaAssetPath == nil ? L10n.text("选择\(draft.mediaKind.rawValue)") : L10n.text("更换\(draft.mediaKind.rawValue)"),
                            systemImage: draft.mediaKind == .video ? "video" : "photo"
                        )
                    }

                    if draft.mediaAssetPath != nil {
                        MemoryMediaPreview(memory: previewMemory, height: 180)
                            .padding(.vertical, 4)

                        Button(L10n.text("移除媒体"), role: .destructive) {
                            draft.mediaAssetPath = nil
                            draft.mediaDisplayName = nil
                            draft.photoAssetPath = nil
                            selectedMediaItem = nil
                        }
                    }
                }

                if let importErrorMessage {
                    Section(L10n.text("导入提示")) {
                        Text(L10n.text(importErrorMessage))
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .petNavigationTitle(L10n.text("新增成长记录"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.text("保存"), action: saveAction)
                        .disabled(
                            draft.title.isEmpty ||
                            draft.story.isEmpty ||
                            draft.mediaAssetPath == nil ||
                            isBusy ||
                            isImportingMedia
                        )
                }
            }
            .task(id: selectedMediaItem) {
                await importSelectedMedia()
            }
            .onChange(of: draft.mediaKind) {
                draft.mediaAssetPath = nil
                draft.mediaDisplayName = nil
                draft.photoAssetPath = nil
                selectedMediaItem = nil
            }
        }
    }

    private var previewMemory: HolidayMemory {
        HolidayMemory(
            id: UUID(),
            title: draft.title,
            subtitle: draft.subtitle,
            dateText: draft.dateText,
            ornament: draft.ornament,
            accent: draft.accent,
            story: draft.story,
            mediaKind: draft.mediaKind,
            mediaAssetPath: draft.mediaAssetPath,
            mediaDisplayName: draft.mediaDisplayName,
            notes: [],
            photoAssetPath: draft.photoAssetPath,
            audioAssetPath: nil,
            audioDisplayName: nil
        )
    }

    private func importSelectedMedia() async {
        guard let selectedMediaItem else {
            return
        }

        isImportingMedia = true
        defer { isImportingMedia = false }

        do {
            guard let data = try await selectedMediaItem.loadTransferable(type: Data.self) else {
                importErrorMessage = L10n.text("\(draft.mediaKind.rawValue)读取失败，请重新选择。")
                return
            }

            let ext = selectedMediaItem.supportedContentTypes.first?.preferredFilenameExtension ?? (draft.mediaKind == .video ? "mov" : "jpg")
            let relativePath = try MemoryAssetStore.saveBinaryData(data, preferredExtension: ext)
            draft.mediaAssetPath = relativePath
            draft.mediaDisplayName = selectedMediaItem.itemIdentifier ?? "\(draft.mediaKind.rawValue).\(ext)"
            draft.photoAssetPath = draft.mediaKind == .image ? relativePath : nil
            importErrorMessage = nil
        } catch {
            importErrorMessage = L10n.text("\(draft.mediaKind.rawValue)导入失败：\(error.localizedDescription)")
        }
    }
}

private struct MemoryMediaPreview: View {
    @Environment(\.locale) private var appLocale
    let memory: HolidayMemory
    var height: CGFloat

    private var relativePath: String? {
        memory.mediaAssetPath ?? memory.photoAssetPath
    }

    var body: some View {
        let _ = appLocale
        Group {
            if let relativePath, let fileURL = MemoryAssetStore.url(for: relativePath) {
                switch memory.mediaKind {
                case .image:
                    if let image = UIImage(contentsOfFile: fileURL.path) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        placeholder
                    }
                case .video:
                    if height > 220 {
                        VideoPlayer(player: AVPlayer(url: fileURL))
                    } else if let thumbnail = videoThumbnail(for: fileURL) {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .overlay(alignment: .center) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(PetPalette.album.ink)
                                    .shadow(radius: 8)
                            }
                    } else {
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(PetPalette.album.surface)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(PetPalette.album.border, lineWidth: 1))
            .overlay(
                VStack(spacing: 8) {
                    PetDoodle(animal: .bird).frame(width: 54, height: 54)
                    Text(memory.mediaKind == .video ? L10n.text("视频记录") : L10n.text("照片记录"))
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(PetPalette.album.ink)
            )
    }

    private func videoThumbnail(for url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 800, height: 800)

        do {
            let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            return nil
        }
    }
}

private struct MiniBadge: View {
    @Environment(\.locale) private var appLocale
    let label: String

    var body: some View {
        let _ = appLocale
        Text(L10n.text(label))
            .font(.caption)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(PetPalette.album.surface, in: Capsule())
            .overlay(Capsule().stroke(PetPalette.album.border, lineWidth: 1))
    }
}

#Preview {
    NavigationStack {
        AlbumTreeView(appModel: AppModel())
    }
}
