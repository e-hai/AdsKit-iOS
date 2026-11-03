# AdsKit-iOS – AGENTS.md

This file is for AI agents (Codex, Copilot, etc.) to quickly understand the project structure, conventions, and how to make safe edits on the `AdsKit-iOS` repository.

## What This Repository Is

The iOS implementation of `AdsKit` written in Swift. It mirrors the exact architecture of `AdsKit-Android`, providing a unified `AdsManager` facade wrapping Google Mobile Ads (AdMob) and AppLovin MAX under a single API.

**Key design decision**: single-adapter mode – `AdsManager` initializes exactly one `AdsProviderAdapter` at a time. Switching providers requires reinitializing via `AdsManager.initialize()`, which destroys the old adapter and evicts preloaded ads.

## Project Layout

```
AdsKit-iOS/
├── Package.swift                    # Swift Package Manager manifest
├── AdsKit.podspec                   # CocoaPods podspec
├── Sources/
│   ├── AdsCore/                     # Core SDK (AdsManager, state machine, UMP, protocols)
│   │   ├── AdsManager.swift         # Singleton facade, state machine, preload cache
│   │   ├── AdsInitState.swift       # IDLE, INITIALIZING, READY, FAILED
│   │   ├── AdsRequest.swift         # triggerId, adUnitId, adType, providerType, preloadTtlMs
│   │   ├── AdsType.swift            # BANNER, SPLASH, REWARDED, INTERSTITIAL, NATIVE, MREC
│   │   ├── AdsEntity.swift          # Loaded ad wrapper with show() and destroy()
│   │   ├── AdsListener.swift        # Callback protocol + AdCallback base class
│   │   ├── AdsPaidEvent.swift       # Revenue event data structure
│   │   ├── AdsLogger.swift          # Tagged structured logger with AdsKit-* prefix
│   │   ├── AdsDebug.swift           # Test device IDs and debug toggles
│   │   ├── AdsLoadHandler.swift     # Provider-to-public callback mapper
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
│       └── AdsKit.swift             # Re-exports Core/Admob/Applovin and registers providers
├── Tests/
│   └── AdsCoreTests/
│       ├── AdsManagerTests.swift    # 12 unit tests for state machine & cache
│       ├── FakeAdsProviderAdapter.swift
│       └── AdsProviderAdapterFactoryTests.swift
├── Sample/                          # SwiftUI sample application
│   ├── SampleApp.swift
│   ├── ContentView.swift
│   └── SampleConfig.swift
└── README.md
```

## Module / SPM Target Options

Host apps can choose targets based on which providers they require:

| Target | Description |
|---|---|
| `AdsCore` | Core contracts, state machine, UMP, preload cache |
| `AdsAdmob` | AdMob provider adapter |
| `AdsApplovin` | AppLovin MAX provider adapter |
| `AdsKit` | Full bundle umbrella (Core + AdMob + AppLovin) |

```swift
// Package.swift dependency in host app:
.package(url: "https://github.com/e-hai/AdsKit.git", branch: "ios")
```

## Threading Model

- All public APIs (`AdsManager.initialize`, `loadAd`, `preloadAd`, `destroy`, `openDebug`) are annotated with `@MainActor`.
- Internal callbacks and adapter operations marshal to the main actor.
