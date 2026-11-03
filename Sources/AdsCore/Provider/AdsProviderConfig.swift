import Foundation

public struct AdsProviderConfig: Sendable, Equatable {
    public let providerType: AdsProviderType
    public let apiKey: String // AdMob: App ID / AppLovin: SDK Key

    public init(providerType: AdsProviderType, apiKey: String) {
        self.providerType = providerType
        self.apiKey = apiKey
    }
}
