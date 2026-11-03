import Foundation
import AdsCore

@MainActor
public final class AdmobProviderAdapterRegistrar: AdsProviderAdapterRegistrar {
    public let providerType: AdsProviderType = .admob

    public init() {}

    public func create() -> AdsProviderAdapter {
        return AdmobProviderAdapter()
    }

    public static func register() {
        AdsProviderAdapterFactory.register(AdmobProviderAdapterRegistrar())
    }
}
