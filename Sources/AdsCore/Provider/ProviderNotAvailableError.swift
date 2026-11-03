import Foundation

public struct ProviderNotAvailableError: Error, CustomStringConvertible {
    public let providerType: AdsProviderType

    public init(providerType: AdsProviderType) {
        self.providerType = providerType
    }

    public var description: String {
        return "Provider \(providerType.name) adapter not available on the classpath/binary. Make sure AdsAdmob or AdsApplovin target is linked."
    }
}
