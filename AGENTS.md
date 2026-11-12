# AdsKit-iOS – AGENTS.md

This document is specifically crafted for AI coding agents (Claude, GPT, Codex, etc.) to quickly understand the codebase architecture, design invariants, memory model, and guidelines for making safe and idiomatic changes in the `AdsKit-iOS` repository.

---

## 1. What This Repository Is

`AdsKit-iOS` is an iOS ad mediation SDK written in **Swift** wrapping **Google Mobile Ads (AdMob)** and **AppLovin MAX** under a unified `AdsManager` facade.

### Key Architectural Invariants
- **Single-Adapter Mode**: `AdsManager` activates exactly one `AdsProviderAdapter` at any given time.
- **Provider Switching**: Calling `AdsManager.initialize(...)` with a different provider automatically tears down the active adapter (`destroy()`) and evicts all preloaded ads from cache.
- **Provider Registration**: Providers register via `AdsProviderAdapterFactory.register(...)` (typically triggered via `AdsKit.registerAllProviders()`).
- **MainActor Concurrency**: All public API methods, lifecycle handlers, and delegate dispatches strictly execute on the `@MainActor`.
- **GDPR Startup Order**: Both documentation and `sample/` UI follow `UMP.start(...)` → `AdsManager.initialize(...)` → `loadAd(...)` so third-party mediation adapters are not initialized prior to user consent.
- **Zero Cross-Platform Leaks**: This repository is completely self-contained and must not include any Android-specific dependencies, configurations, or references.

---

## 2. Project Layout

```
AdsKit-iOS/
├── Package.swift                    # Swift Package Manager manifest (Core, Admob, Applovin, AdsKit)
├── AdsKit.podspec                   # CocoaPods specification
├── project.yml                      # XcodeGen project specification for AdsKitDemo
├── AdsKitDemo.xcodeproj/            # Standalone iOS Application project for Simulator & Device runs
│   ├── project.pbxproj
│   ├── project.xcworkspace/
│   └── xcshareddata/xcschemes/AdsKitDemo.xcscheme
├── sample/                          # Interactive SwiftUI Demo application source
│   ├── Info.plist                   # Contains GADApplicationIdentifier & ATT permissions
│   ├── SampleApp.swift              # @main SwiftUI App entry point
│   ├── ContentView.swift            # Complete 1:1 feature demo screen
│   └── SampleConfig.swift           # Official test ad unit IDs & provider configs
├── Sources/
│   ├── AdsCore/                     # Core domain, state machine, UMP, and contracts
│   │   ├── AdsManager.swift         # Singleton facade, init state machine, preload TTL cache
│   │   ├── AdsInitState.swift       # IDLE (0), INITIALIZING (1), READY (2), FAILED (3)
│   │   ├── AdsRequest.swift         # Data structure: triggerId, adUnitId, adType, providerType, preloadTtlMs
│   │   ├── AdsType.swift            # BANNER, SPLASH, REWARDED, INTERSTITIAL, NATIVE, MREC
│   │   ├── AdsEntity.swift          # Loaded ad wrapper with show(from:in:) and destroy()
│   │   ├── AdsListener.swift        # Callback protocol + AdCallback open base class
│   │   ├── AdsPaidEvent.swift       # eCPM / revenue event data structure (valueMicros, currency, precision)
│   │   ├── AdsLogger.swift          # Internal (@_spi(AdsKitInternal)) tagged logger
│   │   ├── AdsDebug.swift           # Internal (@_spi(AdsKitInternal)) debug flag
│   │   ├── AdsLoadHandler.swift     # Lifecycle manager for individual load operations
│   │   ├── UMP/
│   │   │   └── UMP.swift            # Google User Messaging Platform consent wrapper
│   │   └── Provider/
│   │       ├── AdsProviderType.swift
│   │       ├── AdsProviderConfig.swift
│   │       ├── AdsProviderAdapter.swift
│   │       ├── AdsProviderListener.swift
│   │       ├── AdsProviderAdapterRegistrar.swift
│   │       ├── AdsProviderAdapterFactory.swift
│   │       └── ProviderNotAvailableError.swift
│   ├── AdsAdmob/                    # Google Mobile Ads (AdMob) adapter
│   │   ├── AdmobProviderAdapter.swift
│   │   └── AdmobProviderAdapterRegistrar.swift
│   ├── AdsApplovin/                 # AppLovin MAX adapter
│   │   ├── ApplovinProviderAdapter.swift
│   │   └── ApplovinProviderAdapterRegistrar.swift
│   └── AdsKit/                      # Umbrella module
│       └── AdsKit.swift             # Exports Core/Admob/Applovin and registers providers
├── Tests/
│   └── AdsCoreTests/
│       ├── AdsManagerTests.swift    # Unit tests covering initialization, state machine, and cache TTL
│       ├── FakeAdsProviderAdapter.swift
│       └── AdsProviderAdapterFactoryTests.swift
├── README.md                        # Chinese developer documentation
└── AGENTS.md                        # This agent guide
```

---

## 3. Core Subsystems

### A. State Machine (`AdsManager`)
`AdsManager` enforces 4 mutually exclusive states:
1. `IDLE` (Initial state, or after `destroy()`)
2. `INITIALIZING` (Concurrent calls ignored while initializing)
3. `READY` (Adapter available, ads can be requested)
4. `FAILED` (Adapter creation failed or SDK initialization failed)

### B. Preload & Cache TTL
- Requests specify a unique `triggerId` string.
- Preloaded ads are indexed by `triggerId` with timestamp and TTL (default: 55 minutes).
- `loadAd()` checks `preloadedAds[triggerId]`. If present and unexpired, the cached ad is consumed immediately (single-use cache). If expired, the entry is automatically destroyed and a live network request is initiated.
- Switching providers via `initialize()` clears all cached preloads.

### C. Unified Show API (`AdsEntity.show(from:in:)`)
- **Full-Screen Ads** (`splash`, `interstitial`, `rewarded`): Presented modally from the provided `UIViewController`. The `container` parameter is ignored.
- **Container Ads** (`banner`, `mrec`, `native`): Added as subviews to the provided `UIView` container. Old views are removed and autolayout constraints are applied automatically.

---

## 4. CRITICAL: Memory Model & ARC Lifetime Rules

Because ad SDKs (Google Mobile Ads and AppLovin MAX) rely on asynchronous network calls and Objective-C delegate patterns, AI agents **MUST NEVER** violate the following memory lifetime rules:

### Rule 1: Never Use `[weak listener]` in Load Closures
In asynchronous completion handlers (such as `AppOpenAd.load`, `RewardedAd.load`, `InterstitialAd.load`), **always capture `listener` strongly**:
```swift
// ✅ CORRECT: Listener is captured strongly until network returns, then naturally released
AppOpenAd.load(with: request.adUnitId, request: gadRequest) { [listener] ad, error in
    Task { @MainActor in
        if let error = error {
            listener.onAdFailedToLoad(error: error.localizedDescription, errorCode: "\(error._code)")
            return
        }
        listener.onAdLoaded(ad: ad)
    }
}

// ❌ WRONG: providerListener is a local variable; [weak listener] becomes nil immediately!
AppOpenAd.load(...) { [weak listener] ad, error in ... }
```

### Rule 2: Active Loaders Must Be Retained
Instances of `BannerView`, `AdLoader`, `MAAdView`, `MAAppOpenAd`, `MAInterstitialAd`, and `MANativeAdLoader` must be retained in an Adapter-level array (`activeLoaders` / `activeAds`) during the loading period. Once `onAdLoaded` or `onAdFailedToLoad` triggers, remove the instance from the array.

### Rule 3: `BannerView` and `AdLoader` Require `rootViewController`
Google Mobile Ads strictly requires setting `rootViewController` **before** calling `.load(gadRequest)`:
```swift
bannerView.rootViewController = getTopViewController()
bannerView.load(gadRequest)
```

### Rule 4: `InternalProviderListener` Retains `AdsListener`
In `AdsLoadHandler.swift`, `InternalProviderListener` must retain `listener: AdsListener` strongly so that anonymous callback objects (e.g., `AdsManager.loadAd(request: req, adListener: Callback())`) are not deallocated before the async network response arrives.

---

## 5. Concurrency & Thread Safety

- **`@MainActor` Isolation**: `AdsManager`, `AdsLoadHandler`, `AdsEntity`, `AdsListener`, and all adapter public interfaces are isolated to `@MainActor`.
- **Delegate Conformance**: Ad SDK delegate callbacks from Objective-C must marshal onto the main actor safely using `Task { @MainActor in ... }`:
```swift
func bannerViewDidReceiveAd(_ bannerView: BannerView) {
    Task { @MainActor in
        self.listener.onAdLoaded(ad: bannerView)
    }
}
```

---

## 6. Logging & Debug Switches

`AdsLogger` and `AdsDebug` are marked `@_spi(AdsKitInternal)` and **are not exposed to external host apps**. Both default to **`false`** and are configured via `AdsManager.initialize(config:logEnabled:debugEnabled:onResult:)`. `UMP.start(...)` uses an independent local `debugEnabled` parameter and emits no internal SDK logs:

| Parameter / API | Default | Scope & Side Effects |
|---|---|---|
| `AdsManager.initialize(..., logEnabled:)` | `false` | Sets internal `AdsLogger.isEnabled`. Controls `[AdsKit-*]` console logging only; no behavioral side effects. |
| `AdsManager.initialize(..., logHandler:)` / `setLogHandler(_:)` | `nil` | External `AdsLogHandler` interceptor (`AdsLogLevel`, `tag`, `message`, `error`). When non-nil, intercepts all SDK logs and suppresses default `print` output. |
| `AdsManager.initialize(..., debugEnabled:)` | `false` | Sets internal `AdsDebug.isEnabled`. Reserved SDK debug flag. |
| `UMP.start(from:debugEnabled:umpTestDeviceIds:callBack:)` | `false`, `[]` | Independent local UMP debug parameters (not tied to `AdsDebug`). When `debugEnabled == true`, applies EEA debug geography and resets UMP consent. Recommended to run **before** `AdsManager.initialize(...)` for GDPR compliance. |

---

## 7. Official Google AdMob iOS Test Ad Unit IDs

Always use the official demo IDs when authoring sample code or tests:

| Ad Type | Official iOS Demo Unit ID |
|---|---|
| **App Open (Splash)** | `ca-app-pub-3940256099942544/5575463023` |
| **Banner (Adaptive / Fixed)** | `ca-app-pub-3940256099942544/2934735716` |
| **Interstitial** | `ca-app-pub-3940256099942544/4411468910` |
| **Rewarded Video** | `ca-app-pub-3940256099942544/1712485313` |
| **Native Advanced** | `ca-app-pub-3940256099942544/3986624511` |
| **MREC (300x250)** | `ca-app-pub-3940256099942544/2934735716` |

---

## 8. Build, Test, and Run Commands

### A. Compile Swift Package (iOS Simulator Triple)
```bash
cd /Users/a/Develop/project/ios/AdsKit-iOS
swift build --triple arm64-apple-ios17.0-simulator
```

### B. Run Unit Tests
```bash
swift test --filter AdsCoreTests
```

### C. Build the Demo Application with `xcodebuild`
```bash
xcodebuild -project AdsKitDemo.xcodeproj -scheme AdsKitDemo -destination 'generic/platform=iOS Simulator' build
```

### D. Install & Launch Demo on Active Simulator
```bash
xcrun simctl install booted <path_to_AdsKitDemo.app>
xcrun simctl launch booted com.adskit.demo
```

---

## 9. Agent Checklist Before Committing Changes

1. **Build Verification**: Run `swift build --triple arm64-apple-ios17.0-simulator` and ensure zero errors and zero warnings.
2. **Test Verification**: Run `swift test --filter AdsCoreTests` and verify all 12 unit tests pass.
3. **Demo App Verification**: Build `AdsKitDemo.xcodeproj` with `xcodebuild` to ensure SwiftUI compatibility.
4. **Git Isolation**: Ensure no cross-references or Android code leak into this repository.
