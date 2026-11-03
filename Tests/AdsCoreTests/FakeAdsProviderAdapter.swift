import Foundation
@testable import AdsCore

@MainActor
final class FakeAdsProviderAdapter: AdsProviderAdapter {
    let providerType: AdsProviderType
    var initSuccess: Bool = true
    var asyncInit: Bool = false
    var pendingInitCompletion: ((Bool) -> Void)?

    var initializeCalls = 0
    var destroyCalls = 0
    var loadAdCalls = 0
    var lastRequest: AdsRequest?
    var lastListener: AdsProviderListener?

    var shouldSucceedLoad: Bool = true
    var loadErrorCode: String? = nil
    var loadErrorMessage: String = "Fake load error"

    init(providerType: AdsProviderType) {
        self.providerType = providerType
    }

    func initialize(config: AdsProviderConfig, completion: @escaping @MainActor (Bool) -> Void) {
        initializeCalls += 1
        if asyncInit {
            pendingInitCompletion = completion
        } else {
            completion(initSuccess)
        }
    }

    func loadAd(request: AdsRequest, listener: AdsProviderListener) {
        loadAdCalls += 1
        lastRequest = request
        lastListener = listener
        listener.onAdStartedToLoad()
        if shouldSucceedLoad {
            listener.onAdLoaded(ad: "fake_ad_handle_\(request.triggerId)")
        } else {
            listener.onAdFailedToLoad(error: loadErrorMessage, errorCode: loadErrorCode)
        }
    }

    func showAd(viewController: Any, container: Any?, ad: Any, request: AdsRequest, listener: AdsProviderListener) {
        listener.onAdShown()
    }

    func destroyAd(ad: Any, request: AdsRequest) {
        // no-op
    }

    func destroy() {
        destroyCalls += 1
    }

    func openDebug(viewController: Any) {
        // no-op
    }
}
