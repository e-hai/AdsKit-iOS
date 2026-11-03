import Foundation
@_exported import AdsCore
@_exported import AdsAdmob
@_exported import AdsApplovin

@MainActor
public enum AdsKit {
    private static var isRegistered = false

    /// Automatically registers all built-in providers into the factory
    public static func registerAllProviders() {
        guard !isRegistered else { return }
        isRegistered = true
        AdmobProviderAdapterRegistrar.register()
        ApplovinProviderAdapterRegistrar.register()
    }
}
