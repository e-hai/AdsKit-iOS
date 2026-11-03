import Foundation
import AdsCore

@MainActor
public final class ApplovinProviderAdapterRegistrar: AdsProviderAdapterRegistrar {
    public let providerType: AdsProviderType = .applovin

    public init() {}

    public func create() -> AdsProviderAdapter {
        return ApplovinProviderAdapter()
    }

    public static func register() {
        AdsProviderAdapterFactory.register(ApplovinProviderAdapterRegistrar())
    }
}
