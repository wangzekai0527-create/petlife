import SwiftUI

struct VideoUploadView: View {
    @Environment(\.locale) private var appLocale
    let appModel: AppModel

    var body: some View {
        let _ = appLocale
        AlbumTreeView(appModel: appModel)
    }
}

#Preview {
    NavigationStack {
        VideoUploadView(appModel: AppModel())
    }
}
