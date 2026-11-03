import Foundation

@MainActor
public protocol AdsProviderAdapterRegistrar {
    var providerType: AdsProviderType { get }
    func create() -> AdsProviderAdapter
}
