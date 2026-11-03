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

        // Initialize AdsKit with AdMob as default
        AdsManager.initialize(
            config: AdsProviderConfig(
                providerType: .admob,
                apiKey: SampleConfig.admobAppId
            )
        ) { success in
            AdsLogger.d("SampleApp", "Default provider init success: \(success)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
