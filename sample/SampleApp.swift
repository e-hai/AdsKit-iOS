import SwiftUI
import AdsKit

@main
struct SampleApp: App {
    init() {
        // Register all providers (AdMob, AppLovin)
        AdsKit.registerAllProviders()

        // Enable debug logs
        AdsLogger.isEnabled = true
        AdsDebug.isEnabled = true
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
