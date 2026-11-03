import Foundation
import AdsCore

/// Sample 广告位与 Provider 配置集中管理
public struct SampleConfig {
    // === Provider API Keys ===
    public static let admobAppId = "ca-app-pub-3940256099942544~1458002511"
    public static let applovinSdkKey = "YOUR_APPLOVIN_SDK_KEY"

    // === triggerId: 预加载缓存键，每个场景使用唯一值 ===
    public struct TriggerId {
        public static let banner = "demo_banner"
        public static let splash = "demo_splash"
        public static let rewarded = "demo_rewarded"
        public static let interstitial = "demo_interstitial"
        public static let native = "demo_native"
        public static let mrec = "demo_mrec"
        public static let preloadBanner = "preload_banner"
    }

    // === Google 官方 iOS 测试广告位 ===
    public struct AdMobUnit {
        public static let banner = "ca-app-pub-3940256099942544/2934735716"
        public static let rewarded = "ca-app-pub-3940256099942544/1712485313"
        public static let splash = "ca-app-pub-3940256099942544/5575463023"
        public static let interstitial = "ca-app-pub-3940256099942544/4411468910"
        public static let native = "ca-app-pub-3940256099942544/3986624511"
        public static let mrec = "ca-app-pub-3940256099942544/2934735716"
    }

    // === AppLovin MAX 广告位 ===
    public struct AppLovinUnit {
        public static let banner = "YOUR_MAX_BANNER_AD_UNIT_ID"
        public static let rewarded = "YOUR_MAX_REWARDED_AD_UNIT_ID"
        public static let splash = "YOUR_MAX_APP_OPEN_AD_UNIT_ID"
        public static let interstitial = "YOUR_MAX_INTERSTITIAL_AD_UNIT_ID"
        public static let native = "YOUR_MAX_NATIVE_AD_UNIT_ID"
        public static let mrec = "YOUR_MAX_MREC_AD_UNIT_ID"

        public static func hasRealUnits() -> Bool {
            let units = [banner, rewarded, splash, interstitial, native, mrec]
            return !units.contains(where: { $0.hasPrefix("YOUR_MAX_") })
        }
    }

    public static func providerConfig(provider: AdsProviderType) -> AdsProviderConfig {
        switch provider {
        case .admob:
            return AdsProviderConfig(providerType: .admob, apiKey: admobAppId)
        case .applovin:
            return AdsProviderConfig(providerType: .applovin, apiKey: applovinSdkKey)
        }
    }

    public static func request(
        provider: AdsProviderType,
        adType: AdsType,
        triggerId: String? = nil
    ) -> AdsRequest {
        let tid = triggerId ?? triggerIdFor(adType: adType)
        return AdsRequest(
            triggerId: tid,
            adUnitId: adUnitId(provider: provider, adType: adType),
            adType: adType,
            providerType: provider
        )
    }

    public static func preloadBannerRequest(provider: AdsProviderType) -> AdsRequest {
        return request(provider: provider, adType: .banner, triggerId: TriggerId.preloadBanner)
    }

    public static func triggerIdFor(adType: AdsType) -> String {
        switch adType {
        case .banner: return TriggerId.banner
        case .splash: return TriggerId.splash
        case .rewarded: return TriggerId.rewarded
        case .interstitial: return TriggerId.interstitial
        case .native: return TriggerId.native
        case .mrec: return TriggerId.mrec
        }
    }

    public static func adUnitId(provider: AdsProviderType, adType: AdsType) -> String {
        switch provider {
        case .admob:
            switch adType {
            case .banner: return AdMobUnit.banner
            case .rewarded: return AdMobUnit.rewarded
            case .splash: return AdMobUnit.splash
            case .interstitial: return AdMobUnit.interstitial
            case .native: return AdMobUnit.native
            case .mrec: return AdMobUnit.mrec
            }
        case .applovin:
            switch adType {
            case .banner: return AppLovinUnit.banner
            case .rewarded: return AppLovinUnit.rewarded
            case .splash: return AppLovinUnit.splash
            case .interstitial: return AppLovinUnit.interstitial
            case .native: return AppLovinUnit.native
            case .mrec: return AppLovinUnit.mrec
            }
        }
    }
}
