import Foundation

#if canImport(UIKit)
import UIKit
#endif

@MainActor
public final class AdsManager {
    public static let shared = AdsManager()
    public static let TAG = "AdsKit"

    /// 默认预加载 TTL：55 分钟
    public static let DEFAULT_PRELOAD_TTL_MS: Int64 = 55 * 60 * 1000

    private struct PreloadedEntry {
        let ad: AdsEntity
        let cachedAtMs: Int64
        let ttlMs: Int64

        func isExpired(nowMs: Int64) -> Bool {
            return ttlMs > 0 && (nowMs - cachedAtMs) >= ttlMs
        }
    }

    private enum InternalInitState {
        case idle
        case initializing
        case ready
        case failed
    }

    private var initState: InternalInitState = .idle
    private var initToken: Int = 0
    private var adsProviderAdapter: AdsProviderAdapter?
    private var initializedProviderType: AdsProviderType?

    private var preloadedAds: [String: PreloadedEntry] = [:]

    // Test support
    internal var testAdapterFactory: ((AdsProviderType) -> AdsProviderAdapter)?
    internal var clockMs: () -> Int64 = {
        Int64(Date().timeIntervalSince1970 * 1000)
    }

    private init() {}

    // MARK: - Public State Query

    public func getInitState() -> AdsInitState {
        switch initState {
        case .idle: return .idle
        case .initializing: return .initializing
        case .ready: return .ready
        case .failed: return .failed
        }
    }

    public func getInitializedProviderType() -> AdsProviderType? {
        return initializedProviderType
    }

    private func resolveTtlMs(request: AdsRequest) -> Int64 {
        return request.preloadTtlMs ?? Self.DEFAULT_PRELOAD_TTL_MS
    }

    // MARK: - Initialize

    public func initialize(
        config: AdsProviderConfig,
        onResult: ((Bool) -> Void)? = nil
    ) {
        let providerType = config.providerType
        if testAdapterFactory == nil && !AdsProviderAdapterFactory.isAvailable(providerType) {
            AdsLogger.e(
                Self.TAG,
                "initialize failed provider=\(providerType.name) error=Provider not on classpath/linked. Add AdsAdmob or AdsApplovin."
            )
            initState = .failed
            onResult?(false)
            return
        }

        let adapter: AdsProviderAdapter
        if let factory = testAdapterFactory {
            adapter = factory(providerType)
        } else {
            do {
                adapter = try AdsProviderAdapterFactory.create(providerType)
            } catch {
                AdsLogger.e(Self.TAG, "initialize failed creating adapter: \(error)")
                initState = .failed
                onResult?(false)
                return
            }
        }

        switch initState {
        case .initializing:
            AdsLogger.w(Self.TAG, "Ignoring initialize(\(providerType.name)), another initialize is in progress.")
            onResult?(false)
            return

        case .ready:
            if initializedProviderType == providerType {
                AdsLogger.w(Self.TAG, "AdsManager already initialized with \(providerType.name). Skip duplicate initialize.")
                onResult?(true)
                return
            }
            AdsLogger.w(Self.TAG, "Reinitializing from \(initializedProviderType?.name ?? "none") to \(providerType.name). Releasing old adapter.")

        case .idle, .failed:
            break
        }

        let oldAdapter = adsProviderAdapter
        adsProviderAdapter = nil
        initializedProviderType = nil
        initState = .initializing
        initToken += 1
        let token = initToken

        oldAdapter?.destroy()
        clearPreloadedAds()

        AdsLogger.d(Self.TAG, "initialize start provider=\(providerType.name) token=\(token)")
        adapter.initialize(config: config) { [weak self] success in
            guard let self = self else { return }

            if token != self.initToken {
                AdsLogger.w(Self.TAG, "initialize staleCallback provider=\(providerType.name) token=\(token) currentToken=\(self.initToken)")
                adapter.destroy()
                return
            }

            self.initState = success ? .ready : .failed
            if success {
                self.adsProviderAdapter = adapter
                self.initializedProviderType = providerType
                AdsLogger.d(Self.TAG, "initialize complete provider=\(providerType.name) success=true state=READY")
            } else {
                self.adsProviderAdapter = nil
                self.initializedProviderType = nil
                AdsLogger.e(Self.TAG, "initialize complete provider=\(providerType.name) success=false state=FAILED")
            }
            onResult?(success)
        }
    }

    // MARK: - Destroy

    public func destroy() {
        let previousProvider = initializedProviderType?.name ?? "none"
        let toDestroy = adsProviderAdapter
        initState = .idle
        initToken += 1
        adsProviderAdapter = nil
        initializedProviderType = nil
        AdsLogger.d(Self.TAG, "destroy previousProvider=\(previousProvider)")
        toDestroy?.destroy()
        clearPreloadedAds()
    }

    private func clearPreloadedAds() {
        let entries = Array(preloadedAds.values)
        guard !entries.isEmpty else { return }
        preloadedAds.removeAll()
        AdsLogger.d(Self.TAG, "clearPreloadedAds count=\(entries.count)")
        for entry in entries {
            entry.ad.destroy()
        }
    }

    // MARK: - Preload & Load

    public func preloadAd(request: AdsRequest) {
        AdsLogger.d(Self.TAG, "preloadAd triggerId=\(request.triggerId) type=\(request.adType.name) provider=\(request.providerType.name)")
        let ttlMs = resolveTtlMs(request: request)

        let internalListener = PreloadCallback(
            onLoaded: { [weak self] ad in
                guard let self = self else { return }
                self.preloadedAds[request.triggerId] = PreloadedEntry(
                    ad: ad,
                    cachedAtMs: self.clockMs(),
                    ttlMs: ttlMs
                )
                AdsLogger.d(Self.TAG, "preloadAd cached triggerId=\(request.triggerId) ttlMs=\(ttlMs)")
            },
            onFailed: { error, errorCode in
                AdsLogger.e(Self.TAG, "preloadAd failed triggerId=\(request.triggerId) error=\(error) errorCode=\(errorCode ?? "nil")")
            }
        )

        executeAdsRequest(request: request, adListener: internalListener)
    }

    public func loadAd(request: AdsRequest, adListener: AdsListener) {
        executeAdsRequest(request: request, adListener: adListener)
    }

    private func executeAdsRequest(request: AdsRequest, adListener: AdsListener) {
        // 检查预加载缓存
        if let cachedEntry = preloadedAds.removeValue(forKey: request.triggerId) {
            let now = clockMs()
            if cachedEntry.isExpired(nowMs: now) {
                AdsLogger.d(Self.TAG, "loadAd cache expired triggerId=\(request.triggerId) ageMs=\(now - cachedEntry.cachedAtMs) ttlMs=\(cachedEntry.ttlMs)")
                cachedEntry.ad.destroy()
            } else {
                AdsLogger.d(Self.TAG, "loadAd from cache triggerId=\(request.triggerId) type=\(request.adType.name) provider=\(request.providerType.name)")
                adListener.onAdLoaded(cachedEntry.ad)
                return
            }
        }

        let adapter = adsProviderAdapter
        let currentProviderType = initializedProviderType
        let state = initState

        AdsLogger.d(Self.TAG, "loadAd triggerId=\(request.triggerId) type=\(request.adType.name) provider=\(request.providerType.name)")
        AdsLogger.d(Self.TAG, "loadAd stateCheck state=\(state) adapter=\(adapter != nil)")

        guard state == .ready, let activeAdapter = adapter else {
            let errorMsg = (state == .initializing)
                ? "AdsManager initializing. Wait for initialize callback then retry."
                : "AdsManager not initialized. No adapter found."
            let code: String
            switch state {
            case .idle: code = "STATE_IDLE"
            case .initializing: code = "STATE_INITIALIZING"
            case .ready: code = "STATE_READY"
            case .failed: code = "STATE_FAILED"
            }
            AdsLogger.w(Self.TAG, "loadAd rejected triggerId=\(request.triggerId) type=\(request.adType.name) errorCode=\(code)")
            adListener.onAdFailedToLoad(error: errorMsg, errorCode: code)
            return
        }

        if currentProviderType != request.providerType {
            let errorMsg = "Provider mismatch. Manager initialized with \(currentProviderType?.name ?? "nil"), request requests \(request.providerType.name)."
            AdsLogger.w(Self.TAG, "loadAd rejected triggerId=\(request.triggerId) errorCode=PROVIDER_MISMATCH init=\(currentProviderType?.name ?? "nil") request=\(request.providerType.name)")
            adListener.onAdFailedToLoad(error: errorMsg, errorCode: "PROVIDER_MISMATCH")
        } else {
            AdsLogger.d(Self.TAG, "loadAd network triggerId=\(request.triggerId) type=\(request.adType.name) provider=\(request.providerType.name)")
            AdsLoadHandler(request: request, providerAdapter: activeAdapter).loadAd(listener: adListener)
        }
    }

    // MARK: - Debug

    public func openDebug(from viewController: Any) {
        if let adapter = adsProviderAdapter {
            adapter.openDebug(viewController: viewController)
        } else {
            AdsLogger.e(Self.TAG, "openDebug rejected error=No adapter initialized")
        }
    }

    // MARK: - Test Reset

    internal func resetForTest() {
        destroy()
        testAdapterFactory = nil
        clockMs = { Int64(Date().timeIntervalSince1970 * 1000) }
    }

    // Private helper for preloading
    private final class PreloadCallback: AdCallback {
        private let onLoadedClosure: (AdsEntity) -> Void
        private let onFailedClosure: (String, String?) -> Void

        init(onLoaded: @escaping (AdsEntity) -> Void, onFailed: @escaping (String, String?) -> Void) {
            self.onLoadedClosure = onLoaded
            self.onFailedClosure = onFailed
        }

        override func onAdLoaded(_ ad: AdsEntity) {
            onLoadedClosure(ad)
        }

        override func onAdFailedToLoad(error: String, errorCode: String?) {
            onFailedClosure(error, errorCode)
        }
    }
}

// MARK: - Global Static Convenience APIs
public extension AdsManager {
    static func initialize(config: AdsProviderConfig, onResult: ((Bool) -> Void)? = nil) {
        shared.initialize(config: config, onResult: onResult)
    }

    static func preloadAd(request: AdsRequest) {
        shared.preloadAd(request: request)
    }

    static func loadAd(request: AdsRequest, adListener: AdsListener) {
        shared.loadAd(request: request, adListener: adListener)
    }

    static func destroy() {
        shared.destroy()
    }

    static func getInitState() -> AdsInitState {
        shared.getInitState()
    }

    static func getInitializedProviderType() -> AdsProviderType? {
        shared.getInitializedProviderType()
    }

    static func openDebug(from viewController: Any) {
        shared.openDebug(from: viewController)
    }
}
