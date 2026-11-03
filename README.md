# AdsKit-iOS

Unified Ad Mediation SDK for iOS (Swift) wrapping **Google Mobile Ads (AdMob)** and **AppLovin MAX** under a single `AdsManager` facade.

### Core Features
- **Single-Adapter Mode**: One active provider at a time; clean teardown and cache eviction on provider switch.
- **MainActor Thread Guarantees**: Thread-safe API lifecycle running on the UI main actor.
- **Preload & TTL Caching**: Fire-and-forget preloading indexed by `triggerId`, with automatic expiration and cleanup.
- **Unified Show API**: `AdsEntity.show(from:in:)` handles both full-screen and view-container ads across all formats.
- **Google UMP Consent**: Built-in privacy consent gathering workflow.

---

## Supported Ad Formats

| Format | AdMob Implementation | AppLovin Implementation | Show Container |
|---|---|---|---|
| `AdsType.banner` | `GADBannerView` (Adaptive) | `MAAdView` (320x50) | Mandatory (`UIView`) |
| `AdsType.mrec` | `GADBannerView` (300x250) | `MAAdView` (MREC) | Mandatory (`UIView`) |
| `AdsType.splash` | `GADAppOpenAd` (App Open) | `MAAppOpenAd` | Ignored (Full Screen) |
| `AdsType.rewarded` | `GADRewardedAd` | `MARewardedAd` | Ignored (Full Screen) |
| `AdsType.interstitial` | `GADInterstitialAd` | `MAInterstitialAd` | Ignored (Full Screen) |
| `AdsType.native` | `GADNativeAd` / `GADNativeAdView` | `MANativeAdLoader` | Mandatory (`UIView`) |

---

## Installation

### Swift Package Manager (Recommended)

In Xcode: **File** > **Add Packages...** > Enter repository URL:
```
https://github.com/e-hai/AdsKit-iOS.git
```

Or in `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/e-hai/AdsKit-iOS.git", from: "1.0.0")
]
```

### CocoaPods

Add to your `Podfile`:
```ruby
# Full bundle
pod 'AdsKit', :git => 'https://github.com/e-hai/AdsKit-iOS.git'

# Or slim integration (AdMob only)
pod 'AdsKit/Core', :git => 'https://github.com/e-hai/AdsKit-iOS.git'
pod 'AdsKit/Admob', :git => 'https://github.com/e-hai/AdsKit-iOS.git'
```

---

## Quickstart

### 1. Initialize SDK

```swift
import AdsKit

@main
struct MyApp: App {
    init() {
        AdsKit.registerAllProviders()

        let config = AdsProviderConfig(
            providerType: .admob,
            apiKey: "ca-app-pub-3940256099942544~1458002511"
        )

        AdsManager.initialize(config: config) { success in
            print("AdsKit initialized: \(success)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 2. Privacy Consent (UMP)

```swift
import AdsKit

// In your root ViewController or View:
UMP.start(from: self) { canRequestAds in
    guard canRequestAds else { return }
    // Preload or load ads
}
```

### 3. Preload Ad (Fire & Forget)

```swift
let request = AdsRequest(
    triggerId: "home_splash",
    adUnitId: "ca-app-pub-3940256099942544/5662855259",
    adType: .splash,
    providerType: .admob
)

AdsManager.preloadAd(request: request)
```

### 4. Load & Show

```swift
AdsManager.loadAd(request: request, adListener: AdCallback(
    onLoaded: { entity in
        // Fullscreen ad
        entity.show(from: self)

        // Or Banner ad:
        // entity.show(from: self, in: bannerContainerView)
    },
    onFailed: { error, errorCode in
        print("Failed to load ad: \(error), code=\(errorCode ?? "")")
    }
))
```

---

## Running Tests

```bash
swift test --filter AdsCoreTests
```
