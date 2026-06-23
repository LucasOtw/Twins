import SwiftUI

@main
struct TwinsApp: App {
    @State private var store = StoreManager()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(store)
                .preferredColorScheme(.dark) // ambiance soirée — voir brief §7
                .task { await store.start() }
        }
    }
}
