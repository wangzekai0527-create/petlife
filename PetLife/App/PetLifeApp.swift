import SwiftUI

@main
struct PetLifeApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootTabView(appModel: appModel)
        }
    }
}
