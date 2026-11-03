import Foundation

@MainActor
public protocol AdsProviderAdapter: AnyObject {
    func initialize(
        config: AdsProviderConfig,
        completion: @escaping @MainActor (Bool) -> Void
    )

    func loadAd(
        request: AdsRequest,
        listener: AdsProviderListener
    )

    func showAd(
        viewController: Any,
        container: Any?,
        ad: Any,
        request: AdsRequest,
        listener: AdsProviderListener
    )

    func destroyAd(
        ad: Any,
        request: AdsRequest
    )

    func destroy()

    func openDebug(viewController: Any)
}
