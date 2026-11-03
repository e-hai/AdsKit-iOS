import Foundation

private let TAG = "AdsKit-AdsLoadHandler"

@MainActor
internal final class AdsLoadHandler {
    private let request: AdsRequest
    private let providerAdapter: AdsProviderAdapter

    init(request: AdsRequest, providerAdapter: AdsProviderAdapter) {
        self.request = request
        self.providerAdapter = providerAdapter
    }

    func loadAd(listener: AdsListener) {
        let triggerId = request.triggerId
        let adUnitId = request.adUnitId
        let adType = request.adType.name
        let providerType = request.providerType.name

        let providerListener = InternalProviderListener(
            request: request,
            providerAdapter: providerAdapter,
            listener: listener
        )

        AdsLogger.d(TAG, "loadAd start id=\(triggerId) unit=\(adUnitId) type=\(adType) provider=\(providerType)")
        providerAdapter.loadAd(request: request, listener: providerListener)
    }

    private final class InternalProviderListener: AdsProviderListener {
        private let request: AdsRequest
        private let providerAdapter: AdsProviderAdapter
        private let listener: AdsListener

        init(request: AdsRequest, providerAdapter: AdsProviderAdapter, listener: AdsListener) {
            self.request = request
            self.providerAdapter = providerAdapter
            self.listener = listener
        }

        func onAdStartedToLoad() {
            AdsLogger.d(TAG, "onAdStartedToLoad id=\(request.triggerId) unit=\(request.adUnitId) type=\(request.adType.name) provider=\(request.providerType.name)")
            listener.onAdStartedToLoad()
        }

        func onAdLoaded(ad: Any) {
            AdsLogger.d(TAG, "onAdLoaded id=\(request.triggerId) unit=\(request.adUnitId) type=\(request.adType.name) provider=\(request.providerType.name)")
            let entity = AdsEntity(providerAdapter: providerAdapter, request: request, listener: self, ad: ad)
            listener.onAdLoaded(entity)
        }

        func onAdFailedToLoad(error: String, errorCode: String?) {
            AdsLogger.e(TAG, "onAdFailedToLoad id=\(request.triggerId) unit=\(request.adUnitId) type=\(request.adType.name) provider=\(request.providerType.name) error=\(error) errorCode=\(errorCode ?? "nil")")
            listener.onAdFailedToLoad(error: error, errorCode: errorCode)
        }

        func onAdShown() {
            AdsLogger.d(TAG, "onAdShown id=\(request.triggerId) unit=\(request.adUnitId) type=\(request.adType.name) provider=\(request.providerType.name)")
            listener.onAdShown()
        }

        func onAdClicked() {
            AdsLogger.d(TAG, "onAdClicked id=\(request.triggerId) unit=\(request.adUnitId) type=\(request.adType.name) provider=\(request.providerType.name)")
            listener.onAdClicked()
        }

        func onAdPaidEvent() {
            AdsLogger.d(TAG, "onAdPaidEvent id=\(request.triggerId) unit=\(request.adUnitId) type=\(request.adType.name) provider=\(request.providerType.name)")
            listener.onAdPaidEvent(AdsPaidEvent())
        }

        func onAdPaidEvent(paid: AdsPaidEvent) {
            AdsLogger.d(TAG, "onAdPaidEvent id=\(request.triggerId) unit=\(request.adUnitId) type=\(request.adType.name) provider=\(request.providerType.name) valueMicros=\(paid.valueMicros) currency=\(paid.currencyCode) precision=\(paid.precision)")
            listener.onAdPaidEvent(paid)
        }

        func onAdClosed() {
            AdsLogger.d(TAG, "onAdClosed id=\(request.triggerId) unit=\(request.adUnitId) type=\(request.adType.name) provider=\(request.providerType.name)")
            listener.onAdClosed()
        }

        func onAdUserEarnedReward() {
            AdsLogger.d(TAG, "onAdUserEarnedReward id=\(request.triggerId) unit=\(request.adUnitId) type=\(request.adType.name) provider=\(request.providerType.name)")
            listener.onAdUserEarnedReward()
        }

        func onAdFailedToShow(ad: Any, error: String, errorCode: String?) {
            AdsLogger.e(TAG, "onAdFailedToShow id=\(request.triggerId) unit=\(request.adUnitId) type=\(request.adType.name) provider=\(request.providerType.name) error=\(error) errorCode=\(errorCode ?? "nil")")
            listener.onAdFailedToShow(error: error, errorCode: errorCode)
        }
    }
}
