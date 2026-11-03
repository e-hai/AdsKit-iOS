import Foundation

@MainActor
public protocol AdsListener: AnyObject {
    func onAdLoaded(_ ad: AdsEntity)
    func onAdFailedToLoad(error: String, errorCode: String?)
    func onAdStartedToLoad()
    func onAdShown()
    func onAdClicked()
    func onAdClosed()
    func onAdPaidEvent(_ paid: AdsPaidEvent)
    func onAdUserEarnedReward()
    func onAdFailedToShow(error: String, errorCode: String?)
}

public extension AdsListener {
    func onAdLoaded(_ ad: AdsEntity) {}
    func onAdFailedToLoad(error: String, errorCode: String?) {}
    func onAdStartedToLoad() {}
    func onAdShown() {}
    func onAdClicked() {}
    func onAdClosed() {}
    func onAdPaidEvent(_ paid: AdsPaidEvent) {}
    func onAdUserEarnedReward() {}
    func onAdFailedToShow(error: String, errorCode: String?) {}
}

open class AdCallback: AdsListener {
    public init() {}
    open func onAdLoaded(_ ad: AdsEntity) {}
    open func onAdFailedToLoad(error: String, errorCode: String?) {}
    open func onAdStartedToLoad() {}
    open func onAdShown() {}
    open func onAdClicked() {}
    open func onAdClosed() {}
    open func onAdPaidEvent(_ paid: AdsPaidEvent) {}
    open func onAdUserEarnedReward() {}
    open func onAdFailedToShow(error: String, errorCode: String?) {}
}
