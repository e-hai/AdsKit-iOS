import SwiftUI
import AdsKit

@main
struct SampleApp: App {
    init() {
        // Register all providers (AdMob, AppLovin)
        AdsKit.registerAllProviders()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
