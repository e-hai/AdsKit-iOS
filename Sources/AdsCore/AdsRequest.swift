import Foundation

public struct AdsRequest: Sendable, Equatable {
    public let triggerId: String
    public let adUnitId: String
    public let adType: AdsType
    public let providerType: AdsProviderType
    public let preloadTtlMs: Int64?

    public init(
        triggerId: String,
        adUnitId: String,
        adType: AdsType,
        providerType: AdsProviderType,
        preloadTtlMs: Int64? = nil
    ) {
        self.triggerId = triggerId
        self.adUnitId = adUnitId
        self.adType = adType
        self.providerType = providerType
        self.preloadTtlMs = preloadTtlMs
    }
}
