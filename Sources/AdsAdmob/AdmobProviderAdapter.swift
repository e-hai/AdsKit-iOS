import Foundation
import AdsCore

#if canImport(UIKit)
import UIKit
#endif

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

private let TAG = "AdsKit-Admob"

@MainActor
public final class AdmobProviderAdapter: NSObject, AdsProviderAdapter {
    public override init() {
        super.init()
    }

    public func initialize(
        config: AdsProviderConfig,
        completion: @escaping @MainActor (Bool) -> Void
    ) {
        AdsLogger.d(TAG, "initialize start")
        #if canImport(GoogleMobileAds)
        if AdsDebug.isEnabled && !AdsDebug.admobTestDeviceIds.isEmpty {
            GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = AdsDebug.admobTestDeviceIds
            AdsLogger.d(TAG, "testDeviceIds=\(AdsDebug.admobTestDeviceIds)")
        }

        GADMobileAds.sharedInstance().start { status in
            Task { @MainActor in
                let adapterStatuses = status.adapterStatusesByClassName
                for (adapterClass, adapterStatus) in adapterStatuses {
                    AdsLogger.d(TAG, "mediationAdapter name=\(adapterClass) description=\(adapterStatus.description) latency=\(adapterStatus.latency)")
                }
                AdsLogger.d(TAG, "initialize complete success=true adapters=\(adapterStatuses.count)")
                completion(true)
            }
        }
        #else
        AdsLogger.w(TAG, "GoogleMobileAds framework not linked; stub initialize complete")
        completion(true)
        #endif
    }

    public func openDebug(viewController: Any) {
        #if canImport(GoogleMobileAds) && canImport(UIKit)
        guard let vc = viewController as? UIViewController else {
            AdsLogger.e(TAG, "openDebug rejected error=viewController must be UIViewController")
            return
        }
        let testDeviceIds = AdsDebug.admobTestDeviceIds.isEmpty
            ? ["9204E5C14728DD6DD82CE0A440ED41F5"]
            : AdsDebug.admobTestDeviceIds
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = testDeviceIds
        GADMobileAds.sharedInstance().presentAdInspector(from: vc) { error in
            if let error = error {
                AdsLogger.e(TAG, "openAdInspector closed error=\(error.localizedDescription)")
            } else {
                AdsLogger.d(TAG, "openAdInspector closed")
            }
        }
        #else
        AdsLogger.w(TAG, "GoogleMobileAds not available on this platform")
        #endif
    }

    public func loadAd(request: AdsRequest, listener: AdsProviderListener) {
        AdsLogger.d(TAG, "loadAd id=\(request.triggerId) unit=\(request.adUnitId) type=\(request.adType.name)")
        listener.onAdStartedToLoad()

        #if canImport(GoogleMobileAds) && canImport(UIKit)
        let gadRequest = GADRequest()

        switch request.adType {
        case .banner:
            loadBanner(request: request, gadRequest: gadRequest, listener: listener, isMrec: false)
        case .mrec:
            loadBanner(request: request, gadRequest: gadRequest, listener: listener, isMrec: true)
        case .splash:
            loadAppOpen(request: request, gadRequest: gadRequest, listener: listener)
        case .rewarded:
            loadRewarded(request: request, gadRequest: gadRequest, listener: listener)
        case .interstitial:
            loadInterstitial(request: request, gadRequest: gadRequest, listener: listener)
        case .native:
            loadNative(request: request, gadRequest: gadRequest, listener: listener)
        }
        #else
        AdsLogger.w(TAG, "GoogleMobileAds not available; returning mock ad")
        listener.onAdLoaded(ad: "MockAdmobAd")
        #endif
    }

    #if canImport(GoogleMobileAds) && canImport(UIKit)
    private func loadBanner(request: AdsRequest, gadRequest: GADRequest, listener: AdsProviderListener, isMrec: Bool) {
        let adSize: GADAdSize
        if isMrec {
            adSize = GADAdSizeMediumRectangle
        } else {
            let width = UIScreen.main.bounds.width
            adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width)
        }

        let bannerView = GADBannerView(adSize: adSize)
        bannerView.adUnitID = request.adUnitId

        let delegate = AdmobBannerDelegate(request: request, listener: listener)
        bannerView.delegate = delegate
        objc_setAssociatedObject(bannerView, &AssociatedKeys.delegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        bannerView.paidEventHandler = { [weak listener] value in
            let micros = value.value.multiplying(byPowerOf10: 6).int64Value
            let paid = AdsPaidEvent(valueMicros: micros, currencyCode: value.currencyCode, precision: value.precision.rawValue)
            listener?.onAdPaidEvent(paid: paid)
        }

        bannerView.load(gadRequest)
    }

    private func loadAppOpen(request: AdsRequest, gadRequest: GADRequest, listener: AdsProviderListener) {
        GADAppOpenAd.load(withAdUnitID: request.adUnitId, request: gadRequest) { [weak self, weak listener] ad, error in
            guard let self = self, let listener = listener else { return }
            if let error = error {
                listener.onAdFailedToLoad(error: error.localizedDescription, errorCode: "\(error._code)")
                return
            }
            guard let ad = ad else {
                listener.onAdFailedToLoad(error: "AdMob app open ad is nil", errorCode: "NIL_AD")
                return
            }

            ad.paidEventHandler = { [weak listener] value in
                let micros = value.value.multiplying(byPowerOf10: 6).int64Value
                let paid = AdsPaidEvent(valueMicros: micros, currencyCode: value.currencyCode, precision: value.precision.rawValue)
                listener?.onAdPaidEvent(paid: paid)
            }
            listener.onAdLoaded(ad: ad)
        }
    }

    private func loadRewarded(request: AdsRequest, gadRequest: GADRequest, listener: AdsProviderListener) {
        GADRewardedAd.load(withAdUnitID: request.adUnitId, request: gadRequest) { [weak self, weak listener] ad, error in
            guard let self = self, let listener = listener else { return }
            if let error = error {
                listener.onAdFailedToLoad(error: error.localizedDescription, errorCode: "\(error._code)")
                return
            }
            guard let ad = ad else {
                listener.onAdFailedToLoad(error: "AdMob rewarded ad is nil", errorCode: "NIL_AD")
                return
            }

            ad.paidEventHandler = { [weak listener] value in
                let micros = value.value.multiplying(byPowerOf10: 6).int64Value
                let paid = AdsPaidEvent(valueMicros: micros, currencyCode: value.currencyCode, precision: value.precision.rawValue)
                listener?.onAdPaidEvent(paid: paid)
            }
            listener.onAdLoaded(ad: ad)
        }
    }

    private func loadInterstitial(request: AdsRequest, gadRequest: GADRequest, listener: AdsProviderListener) {
        GADInterstitialAd.load(withAdUnitID: request.adUnitId, request: gadRequest) { [weak self, weak listener] ad, error in
            guard let self = self, let listener = listener else { return }
            if let error = error {
                listener.onAdFailedToLoad(error: error.localizedDescription, errorCode: "\(error._code)")
                return
            }
            guard let ad = ad else {
                listener.onAdFailedToLoad(error: "AdMob interstitial ad is nil", errorCode: "NIL_AD")
                return
            }

            ad.paidEventHandler = { [weak listener] value in
                let micros = value.value.multiplying(byPowerOf10: 6).int64Value
                let paid = AdsPaidEvent(valueMicros: micros, currencyCode: value.currencyCode, precision: value.precision.rawValue)
                listener?.onAdPaidEvent(paid: paid)
            }
            listener.onAdLoaded(ad: ad)
        }
    }

    private func loadNative(request: AdsRequest, gadRequest: GADRequest, listener: AdsProviderListener) {
        let delegate = AdmobNativeDelegate(request: request, listener: listener)
        let loader = GADAdLoader(
            adUnitID: request.adUnitId,
            rootViewController: nil,
            adTypes: [.native],
            options: nil
        )
        loader.delegate = delegate
        objc_setAssociatedObject(loader, &AssociatedKeys.delegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        loader.load(gadRequest)
    }
    #endif

    public func showAd(
        viewController: Any,
        container: Any?,
        ad: Any,
        request: AdsRequest,
        listener: AdsProviderListener
    ) {
        AdsLogger.d(TAG, "showAd id=\(request.triggerId) unit=\(request.adUnitId) type=\(request.adType.name)")

        #if canImport(GoogleMobileAds) && canImport(UIKit)
        guard let vc = viewController as? UIViewController else {
            listener.onAdFailedToShow(ad: ad, error: "viewController must be UIViewController", errorCode: "INVALID_VC")
            return
        }

        switch request.adType {
        case .banner, .mrec:
            guard let bannerView = ad as? GADBannerView else {
                listener.onAdFailedToShow(ad: ad, error: "ad must be GADBannerView", errorCode: "TYPE_MISMATCH")
                return
            }
            guard let containerView = container as? UIView else {
                listener.onAdFailedToShow(ad: ad, error: "container is required for banner/mrec ads", errorCode: "CONTAINER_REQUIRED")
                return
            }
            bannerView.rootViewController = vc
            containerView.subviews.forEach { $0.removeFromSuperview() }
            containerView.addSubview(bannerView)
            bannerView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                bannerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                bannerView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
            ])
            listener.onAdShown()

        case .splash:
            guard let appOpen = ad as? GADAppOpenAd else {
                listener.onAdFailedToShow(ad: ad, error: "ad must be GADAppOpenAd", errorCode: "TYPE_MISMATCH")
                return
            }
            let fullScreenDelegate = AdmobFullScreenDelegate(listener: listener)
            appOpen.fullScreenContentDelegate = fullScreenDelegate
            objc_setAssociatedObject(appOpen, &AssociatedKeys.fullScreenDelegateKey, fullScreenDelegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            appOpen.present(fromRootViewController: vc)

        case .rewarded:
            guard let rewarded = ad as? GADRewardedAd else {
                listener.onAdFailedToShow(ad: ad, error: "ad must be GADRewardedAd", errorCode: "TYPE_MISMATCH")
                return
            }
            let fullScreenDelegate = AdmobFullScreenDelegate(listener: listener)
            rewarded.fullScreenContentDelegate = fullScreenDelegate
            objc_setAssociatedObject(rewarded, &AssociatedKeys.fullScreenDelegateKey, fullScreenDelegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            rewarded.present(fromRootViewController: vc) {
                listener.onAdUserEarnedReward()
            }

        case .interstitial:
            guard let interstitial = ad as? GADInterstitialAd else {
                listener.onAdFailedToShow(ad: ad, error: "ad must be GADInterstitialAd", errorCode: "TYPE_MISMATCH")
                return
            }
            let fullScreenDelegate = AdmobFullScreenDelegate(listener: listener)
            interstitial.fullScreenContentDelegate = fullScreenDelegate
            objc_setAssociatedObject(interstitial, &AssociatedKeys.fullScreenDelegateKey, fullScreenDelegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            interstitial.present(fromRootViewController: vc)

        case .native:
            guard let nativeAd = ad as? GADNativeAd, let containerView = container as? UIView else {
                listener.onAdFailedToShow(ad: ad, error: "container view is required for native ad", errorCode: "CONTAINER_REQUIRED")
                return
            }
            let nativeAdView = GADNativeAdView(frame: containerView.bounds)
            nativeAdView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            nativeAdView.nativeAd = nativeAd
            containerView.subviews.forEach { $0.removeFromSuperview() }
            containerView.addSubview(nativeAdView)
            listener.onAdShown()
        }
        #else
        listener.onAdShown()
        #endif
    }

    public func destroyAd(ad: Any, request: AdsRequest) {
        AdsLogger.d(TAG, "destroyAd id=\(request.triggerId) unit=\(request.adUnitId) type=\(request.adType.name)")
        #if canImport(GoogleMobileAds) && canImport(UIKit)
        if let banner = ad as? GADBannerView {
            banner.delegate = nil
            banner.removeFromSuperview()
        }
        #endif
    }

    public func destroy() {
        AdsLogger.d(TAG, "destroy adapter")
    }
}

private struct AssociatedKeys {
    static var delegateKey: UInt8 = 0
    static var fullScreenDelegateKey: UInt8 = 1
}

#if canImport(GoogleMobileAds) && canImport(UIKit)
private final class AdmobBannerDelegate: NSObject, GADBannerViewDelegate {
    private let request: AdsRequest
    private weak var listener: AdsProviderListener?

    init(request: AdsRequest, listener: AdsProviderListener) {
        self.request = request
        self.listener = listener
    }

    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        listener?.onAdLoaded(ad: bannerView)
    }

    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        listener?.onAdFailedToLoad(error: error.localizedDescription, errorCode: "\((error as NSError).code)")
    }

    func bannerViewDidRecordClick(_ bannerView: GADBannerView) {
        listener?.onAdClicked()
    }
}

private final class AdmobFullScreenDelegate: NSObject, GADFullScreenContentDelegate {
    private weak var listener: AdsProviderListener?

    init(listener: AdsProviderListener) {
        self.listener = listener
    }

    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
        listener?.onAdShown()
    }

    func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
        listener?.onAdClicked()
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        listener?.onAdClosed()
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        listener?.onAdFailedToShow(ad: ad, error: error.localizedDescription, errorCode: "\((error as NSError).code)")
    }
}

private final class AdmobNativeDelegate: NSObject, GADNativeAdLoaderDelegate {
    private let request: AdsRequest
    private weak var listener: AdsProviderListener?

    init(request: AdsRequest, listener: AdsProviderListener) {
        self.request = request
        self.listener = listener
    }

    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        nativeAd.paidEventHandler = { [weak listener] value in
            let micros = value.value.multiplying(byPowerOf10: 6).int64Value
            let paid = AdsPaidEvent(valueMicros: micros, currencyCode: value.currencyCode, precision: value.precision.rawValue)
            listener?.onAdPaidEvent(paid: paid)
        }
        listener?.onAdLoaded(ad: nativeAd)
    }

    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        listener?.onAdFailedToLoad(error: error.localizedDescription, errorCode: "\((error as NSError).code)")
    }
}
#endif
