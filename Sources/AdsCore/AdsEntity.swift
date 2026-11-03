import Foundation

#if canImport(UIKit)
import UIKit
#endif

@MainActor
public final class AdsEntity {
    private let providerAdapter: AdsProviderAdapter
    public let request: AdsRequest
    private let listener: AdsProviderListener
    private let rawAd: Any

    public init(
        providerAdapter: AdsProviderAdapter,
        request: AdsRequest,
        listener: AdsProviderListener,
        ad: Any
    ) {
        self.providerAdapter = providerAdapter
        self.request = request
        self.listener = listener
        self.rawAd = ad
        AdsLogger.d("AdsKit-AdsEntity", "init id=\(request.triggerId) unit=\(request.adUnitId) type=\(request.adType.name)")
    }

    #if canImport(UIKit)
    public func show(from viewController: UIViewController, in container: UIView? = nil) {
        AdsLogger.d("AdsKit-AdsEntity", "show id=\(request.triggerId) unit=\(request.adUnitId) type=\(request.adType.name)")
        providerAdapter.showAd(viewController: viewController, container: container, ad: rawAd, request: request, listener: listener)
    }
    #else
    public func show(from viewController: Any, in container: Any? = nil) {
        AdsLogger.d("AdsKit-AdsEntity", "show id=\(request.triggerId) unit=\(request.adUnitId) type=\(request.adType.name)")
        providerAdapter.showAd(viewController: viewController, container: container, ad: rawAd, request: request, listener: listener)
    }
    #endif

    public func destroy() {
        AdsLogger.d("AdsKit-AdsEntity", "destroy id=\(request.triggerId) unit=\(request.adUnitId) type=\(request.adType.name)")
        providerAdapter.destroyAd(ad: rawAd, request: request)
    }
}
