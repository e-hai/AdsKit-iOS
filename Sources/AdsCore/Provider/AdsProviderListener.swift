import Foundation

@MainActor
public protocol AdsProviderListener: AnyObject, Sendable {
    func onAdStartedToLoad()
    func onAdLoaded(ad: Any)
    func onAdFailedToLoad(error: String, errorCode: String?)
    func onAdShown()
    func onAdClicked()
    func onAdPaidEvent()
    func onAdPaidEvent(paid: AdsPaidEvent)
    func onAdClosed()
    func onAdUserEarnedReward()
    func onAdFailedToShow(ad: Any, error: String, errorCode: String?)
}

public extension AdsProviderListener {
    func onAdStartedToLoad() {}
    func onAdPaidEvent() {}
    func onAdPaidEvent(paid: AdsPaidEvent) {}
    func onAdFailedToShow(ad: Any, error: String, errorCode: String?) {}
}
