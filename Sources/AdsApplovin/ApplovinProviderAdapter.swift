import Foundation
import AdsCore

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppLovinSDK)
import AppLovinSDK
#endif

private let TAG = "AdsKit-AppLovin"

@MainActor
public final class ApplovinProviderAdapter: NSObject, AdsProviderAdapter {
    public override init() {
        super.init()
    }

    public func initialize(
        config: AdsProviderConfig,
        completion: @escaping @MainActor (Bool) -> Void
    ) {
        AdsLogger.d(TAG, "initialize start key=\(config.apiKey)")
        #if canImport(AppLovinSDK)
        let initConfig = ALSdkInitializationConfiguration.builder(withSdkKey: config.apiKey).build()
        ALSdk.shared().initialize(with: initConfig) { sdkConfig in
            Task { @MainActor in
                AdsLogger.d(TAG, "initialize complete success=true countryCode=\(sdkConfig.countryCode)")
                completion(true)
            }
        }
        #else
        AdsLogger.w(TAG, "AppLovinSDK framework not linked; stub initialize complete")
        completion(true)
        #endif
    }

    public func openDebug(viewController: Any) {
        #if canImport(AppLovinSDK)
        ALSdk.shared().showMediationDebugger()
        AdsLogger.d(TAG, "showMediationDebugger opened")
        #else
        AdsLogger.w(TAG, "AppLovinSDK not available on this platform")
        #endif
    }

    public func loadAd(request: AdsRequest, listener: AdsProviderListener) {
        AdsLogger.d(TAG, "loadAd id=\(request.triggerId) unit=\(request.adUnitId) type=\(request.adType.name)")
        listener.onAdStartedToLoad()

        #if canImport(AppLovinSDK) && canImport(UIKit)
        switch request.adType {
        case .banner:
            let adView = MAAdView(adUnitIdentifier: request.adUnitId)
            let delegate = ApplovinBannerDelegate(request: request, listener: listener)
            adView.delegate = delegate
            adView.revenueDelegate = delegate
            objc_setAssociatedObject(adView, &AssociatedKeys.delegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            adView.loadAd()

        case .mrec:
            let adView = MAAdView(adUnitIdentifier: request.adUnitId, adFormat: .mrec)
            let delegate = ApplovinBannerDelegate(request: request, listener: listener)
            adView.delegate = delegate
            adView.revenueDelegate = delegate
            objc_setAssociatedObject(adView, &AssociatedKeys.delegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            adView.loadAd()

        case .splash:
            let appOpen = MAAppOpenAd(adUnitIdentifier: request.adUnitId)
            let delegate = ApplovinFullscreenDelegate(request: request, listener: listener)
            appOpen.delegate = delegate
            appOpen.revenueDelegate = delegate
            objc_setAssociatedObject(appOpen, &AssociatedKeys.delegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            appOpen.load()

        case .rewarded:
            let rewarded = MARewardedAd.shared(withAdUnitIdentifier: request.adUnitId)
            let delegate = ApplovinRewardedDelegate(request: request, listener: listener)
            rewarded.delegate = delegate
            rewarded.revenueDelegate = delegate
            objc_setAssociatedObject(rewarded, &AssociatedKeys.delegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            rewarded.load()

        case .interstitial:
            let interstitial = MAInterstitialAd(adUnitIdentifier: request.adUnitId)
            let delegate = ApplovinFullscreenDelegate(request: request, listener: listener)
            interstitial.delegate = delegate
            interstitial.revenueDelegate = delegate
            objc_setAssociatedObject(interstitial, &AssociatedKeys.delegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            interstitial.load()

        case .native:
            let nativeLoader = MANativeAdLoader(adUnitIdentifier: request.adUnitId)
            let delegate = ApplovinNativeDelegate(request: request, listener: listener)
            nativeLoader.nativeAdDelegate = delegate
            nativeLoader.revenueDelegate = delegate
            objc_setAssociatedObject(nativeLoader, &AssociatedKeys.delegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            nativeLoader.loadAd()
        }
        #else
        AdsLogger.w(TAG, "AppLovinSDK not available; returning mock ad")
        listener.onAdLoaded(ad: "MockAppLovinAd")
        #endif
    }

    public func showAd(
        viewController: Any,
        container: Any?,
        ad: Any,
        request: AdsRequest,
        listener: AdsProviderListener
    ) {
        AdsLogger.d(TAG, "showAd id=\(request.triggerId) unit=\(request.adUnitId) type=\(request.adType.name)")

        #if canImport(AppLovinSDK) && canImport(UIKit)
        switch request.adType {
        case .banner, .mrec:
            guard let adView = ad as? MAAdView else {
                listener.onAdFailedToShow(ad: ad, error: "ad must be MAAdView", errorCode: "TYPE_MISMATCH")
                return
            }
            guard let containerView = container as? UIView else {
                listener.onAdFailedToShow(ad: ad, error: "container is required for banner/mrec", errorCode: "CONTAINER_REQUIRED")
                return
            }
            containerView.subviews.forEach { $0.removeFromSuperview() }
            containerView.addSubview(adView)
            adView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                adView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                adView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
            ])
            listener.onAdShown()

        case .splash:
            guard let appOpen = ad as? MAAppOpenAd else {
                listener.onAdFailedToShow(ad: ad, error: "ad must be MAAppOpenAd", errorCode: "TYPE_MISMATCH")
                return
            }
            if appOpen.isReady {
                appOpen.show()
            } else {
                listener.onAdFailedToShow(ad: ad, error: "AppOpen ad not ready", errorCode: "NOT_READY")
            }

        case .rewarded:
            guard let rewarded = ad as? MARewardedAd else {
                listener.onAdFailedToShow(ad: ad, error: "ad must be MARewardedAd", errorCode: "TYPE_MISMATCH")
                return
            }
            if rewarded.isReady {
                rewarded.show()
            } else {
                listener.onAdFailedToShow(ad: ad, error: "Rewarded ad not ready", errorCode: "NOT_READY")
            }

        case .interstitial:
            guard let interstitial = ad as? MAInterstitialAd else {
                listener.onAdFailedToShow(ad: ad, error: "ad must be MAInterstitialAd", errorCode: "TYPE_MISMATCH")
                return
            }
            if interstitial.isReady {
                interstitial.show()
            } else {
                listener.onAdFailedToShow(ad: ad, error: "Interstitial ad not ready", errorCode: "NOT_READY")
            }

        case .native:
            guard let nativeAdView = ad as? MANativeAdView, let containerView = container as? UIView else {
                listener.onAdFailedToShow(ad: ad, error: "native ad container view required", errorCode: "CONTAINER_REQUIRED")
                return
            }
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
        #if canImport(AppLovinSDK) && canImport(UIKit)
        if let adView = ad as? MAAdView {
            adView.delegate = nil
            adView.removeFromSuperview()
        }
        #endif
    }

    public func destroy() {
        AdsLogger.d(TAG, "destroy adapter")
    }
}

private struct AssociatedKeys {
    static var delegateKey: UInt8 = 0
}

#if canImport(AppLovinSDK) && canImport(UIKit)
private final class ApplovinBannerDelegate: NSObject, MAAdViewAdDelegate, MAAdRevenueDelegate {
    private let request: AdsRequest
    private weak var listener: AdsProviderListener?

    init(request: AdsRequest, listener: AdsProviderListener) {
        self.request = request
        self.listener = listener
    }

    func didLoad(_ ad: MAAd) {
        Task { @MainActor in
            listener?.onAdLoaded(ad: ad)
        }
    }

    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        Task { @MainActor in
            listener?.onAdFailedToLoad(error: error.message, errorCode: "\(error.code.rawValue)")
        }
    }

    func didDisplay(_ ad: MAAd) {
        Task { @MainActor in
            listener?.onAdShown()
        }
    }

    func didHide(_ ad: MAAd) {
        Task { @MainActor in
            listener?.onAdClosed()
        }
    }

    func didClick(_ ad: MAAd) {
        Task { @MainActor in
            listener?.onAdClicked()
        }
    }

    func didFail(toDisplay ad: MAAd, withError error: MAError) {
        Task { @MainActor in
            listener?.onAdFailedToShow(ad: ad, error: error.message, errorCode: "DISPLAY_\(error.code.rawValue)")
        }
    }

    func didExpand(_ ad: MAAd) {}
    func didCollapse(_ ad: MAAd) {}

    func didPayRevenue(for ad: MAAd) {
        let micros = Int64(ad.revenue * 1_000_000)
        let paid = AdsPaidEvent(valueMicros: micros, currencyCode: "USD", precision: 0)
        Task { @MainActor in
            listener?.onAdPaidEvent(paid: paid)
        }
    }
}

private final class ApplovinFullscreenDelegate: NSObject, MAAdDelegate, MAAdRevenueDelegate {
    private let request: AdsRequest
    private weak var listener: AdsProviderListener?

    init(request: AdsRequest, listener: AdsProviderListener) {
        self.request = request
        self.listener = listener
    }

    func didLoad(_ ad: MAAd) {
        Task { @MainActor in
            listener?.onAdLoaded(ad: ad)
        }
    }

    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        Task { @MainActor in
            listener?.onAdFailedToLoad(error: error.message, errorCode: "\(error.code.rawValue)")
        }
    }

    func didDisplay(_ ad: MAAd) {
        Task { @MainActor in
            listener?.onAdShown()
        }
    }

    func didHide(_ ad: MAAd) {
        Task { @MainActor in
            listener?.onAdClosed()
        }
    }

    func didClick(_ ad: MAAd) {
        Task { @MainActor in
            listener?.onAdClicked()
        }
    }

    func didFail(toDisplay ad: MAAd, withError error: MAError) {
        Task { @MainActor in
            listener?.onAdFailedToShow(ad: ad, error: error.message, errorCode: "DISPLAY_\(error.code.rawValue)")
        }
    }

    func didPayRevenue(for ad: MAAd) {
        let micros = Int64(ad.revenue * 1_000_000)
        let paid = AdsPaidEvent(valueMicros: micros, currencyCode: "USD", precision: 0)
        Task { @MainActor in
            listener?.onAdPaidEvent(paid: paid)
        }
    }
}

private final class ApplovinRewardedDelegate: NSObject, MARewardedAdDelegate, MAAdRevenueDelegate {
    private let request: AdsRequest
    private weak var listener: AdsProviderListener?

    init(request: AdsRequest, listener: AdsProviderListener) {
        self.request = request
        self.listener = listener
    }

    func didLoad(_ ad: MAAd) {
        Task { @MainActor in
            listener?.onAdLoaded(ad: ad)
        }
    }

    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        Task { @MainActor in
            listener?.onAdFailedToLoad(error: error.message, errorCode: "\(error.code.rawValue)")
        }
    }

    func didDisplay(_ ad: MAAd) {
        Task { @MainActor in
            listener?.onAdShown()
        }
    }

    func didHide(_ ad: MAAd) {
        Task { @MainActor in
            listener?.onAdClosed()
        }
    }

    func didClick(_ ad: MAAd) {
        Task { @MainActor in
            listener?.onAdClicked()
        }
    }

    func didFail(toDisplay ad: MAAd, withError error: MAError) {
        Task { @MainActor in
            listener?.onAdFailedToShow(ad: ad, error: error.message, errorCode: "DISPLAY_\(error.code.rawValue)")
        }
    }

    func didRewardUser(for ad: MAAd, with reward: MAReward) {
        Task { @MainActor in
            listener?.onAdUserEarnedReward()
        }
    }

    func didPayRevenue(for ad: MAAd) {
        let micros = Int64(ad.revenue * 1_000_000)
        let paid = AdsPaidEvent(valueMicros: micros, currencyCode: "USD", precision: 0)
        Task { @MainActor in
            listener?.onAdPaidEvent(paid: paid)
        }
    }
}

private final class ApplovinNativeDelegate: NSObject, MANativeAdDelegate, MAAdRevenueDelegate {
    private let request: AdsRequest
    private weak var listener: AdsProviderListener?

    init(request: AdsRequest, listener: AdsProviderListener) {
        self.request = request
        self.listener = listener
    }

    func didLoadNativeAd(_ nativeAdView: MANativeAdView?, for ad: MAAd) {
        Task { @MainActor in
            if let view = nativeAdView {
                listener?.onAdLoaded(ad: view)
            } else {
                listener?.onAdLoaded(ad: ad)
            }
        }
    }

    func didFailToLoadNativeAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        Task { @MainActor in
            listener?.onAdFailedToLoad(error: error.message, errorCode: "\(error.code.rawValue)")
        }
    }

    func didClickNativeAd(_ ad: MAAd) {
        Task { @MainActor in
            listener?.onAdClicked()
        }
    }

    func didPayRevenue(for ad: MAAd) {
        let micros = Int64(ad.revenue * 1_000_000)
        let paid = AdsPaidEvent(valueMicros: micros, currencyCode: "USD", precision: 0)
        Task { @MainActor in
            listener?.onAdPaidEvent(paid: paid)
        }
    }
}
#endif
