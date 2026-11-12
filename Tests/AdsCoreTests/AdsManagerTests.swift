import XCTest
@_spi(AdsKitInternal) @testable import AdsCore

@MainActor
final class AdsManagerTests: XCTestCase {
    private var fakeAdmobAdapter: FakeAdsProviderAdapter!
    private var fakeApplovinAdapter: FakeAdsProviderAdapter!
    private var simulatedTimeMs: Int64 = 1_000_000

    override func setUp() {
        super.setUp()
        AdsManager.shared.setLogHandler(nil)
        AdsManager.shared.resetForTest()
        AdsProviderAdapterFactory.reset()

        fakeAdmobAdapter = FakeAdsProviderAdapter(providerType: .admob)
        fakeApplovinAdapter = FakeAdsProviderAdapter(providerType: .applovin)

        simulatedTimeMs = 1_000_000
        AdsManager.shared.clockMs = { [weak self] in
            self?.simulatedTimeMs ?? 1_000_000
        }

        AdsManager.shared.testAdapterFactory = { [weak self] type in
            guard let self = self else { fatalError() }
            switch type {
            case .admob: return self.fakeAdmobAdapter
            case .applovin: return self.fakeApplovinAdapter
            }
        }
    }

    override func tearDown() {
        AdsManager.shared.resetForTest()
        super.tearDown()
    }

    func testInitialStateIsIdle() {
        XCTAssertEqual(AdsManager.shared.getInitState(), .idle)
        XCTAssertNil(AdsManager.shared.getInitializedProviderType())
    }

    func testInitializeSuccess() {
        var callbackSuccess: Bool?
        AdsManager.shared.initialize(config: AdsProviderConfig(providerType: .admob, apiKey: "app-id")) { success in
            callbackSuccess = success
        }

        XCTAssertEqual(callbackSuccess, true)
        XCTAssertEqual(AdsManager.shared.getInitState(), .ready)
        XCTAssertEqual(AdsManager.shared.getInitializedProviderType(), .admob)
        XCTAssertEqual(fakeAdmobAdapter.initializeCalls, 1)
    }

    func testInitializeFailure() {
        fakeAdmobAdapter.initSuccess = false
        var callbackSuccess: Bool?
        AdsManager.shared.initialize(config: AdsProviderConfig(providerType: .admob, apiKey: "app-id")) { success in
            callbackSuccess = success
        }

        XCTAssertEqual(callbackSuccess, false)
        XCTAssertEqual(AdsManager.shared.getInitState(), .failed)
        XCTAssertNil(AdsManager.shared.getInitializedProviderType())
    }

    func testDuplicateInitializeWithSameProviderSkips() {
        AdsManager.shared.initialize(config: AdsProviderConfig(providerType: .admob, apiKey: "app-id"))
        XCTAssertEqual(fakeAdmobAdapter.initializeCalls, 1)

        var secondResult: Bool?
        AdsManager.shared.initialize(config: AdsProviderConfig(providerType: .admob, apiKey: "app-id")) { success in
            secondResult = success
        }

        XCTAssertEqual(secondResult, true)
        XCTAssertEqual(fakeAdmobAdapter.initializeCalls, 1)
    }

    func testConcurrentInitializeIsIgnored() {
        fakeAdmobAdapter.asyncInit = true

        var firstResult: Bool?
        var secondResult: Bool?

        AdsManager.shared.initialize(config: AdsProviderConfig(providerType: .admob, apiKey: "app-id")) { success in
            firstResult = success
        }
        XCTAssertEqual(AdsManager.shared.getInitState(), .initializing)

        AdsManager.shared.initialize(config: AdsProviderConfig(providerType: .admob, apiKey: "app-id")) { success in
            secondResult = success
        }

        XCTAssertEqual(secondResult, false)
        XCTAssertNil(firstResult)

        fakeAdmobAdapter.pendingInitCompletion?(true)
        XCTAssertEqual(firstResult, true)
        XCTAssertEqual(AdsManager.shared.getInitState(), .ready)
    }

    func testSwitchingProviderDestroysOldAdapterAndClearsPreloadCache() {
        AdsManager.shared.initialize(config: AdsProviderConfig(providerType: .admob, apiKey: "app-id"))
        XCTAssertEqual(AdsManager.shared.getInitializedProviderType(), .admob)

        // Preload an ad under admob
        let request = AdsRequest(triggerId: "home_splash", adUnitId: "u1", adType: .splash, providerType: .admob)
        AdsManager.shared.preloadAd(request: request)
        XCTAssertEqual(fakeAdmobAdapter.loadAdCalls, 1)

        // Switch to AppLovin
        AdsManager.shared.initialize(config: AdsProviderConfig(providerType: .applovin, apiKey: "sdk-key"))
        XCTAssertEqual(fakeAdmobAdapter.destroyCalls, 1)
        XCTAssertEqual(AdsManager.shared.getInitializedProviderType(), .applovin)

        // Old preloaded ad should be evicted; loading with admob now fails with PROVIDER_MISMATCH
        var failedCode: String?
        let listener = TestAdListener(onFailed: { _, code in failedCode = code })
        AdsManager.shared.loadAd(request: request, adListener: listener)
        XCTAssertEqual(failedCode, "PROVIDER_MISMATCH")
    }

    func testLoadAdBeforeInitFailsFast() {
        let request = AdsRequest(triggerId: "home", adUnitId: "u1", adType: .banner, providerType: .admob)
        var failedCode: String?
        let listener = TestAdListener(onFailed: { _, code in failedCode = code })

        AdsManager.shared.loadAd(request: request, adListener: listener)
        XCTAssertEqual(failedCode, "STATE_IDLE")
    }

    func testProviderMismatchFailsFast() {
        AdsManager.shared.initialize(config: AdsProviderConfig(providerType: .admob, apiKey: "app-id"))
        let request = AdsRequest(triggerId: "home", adUnitId: "u1", adType: .banner, providerType: .applovin)

        var failedCode: String?
        let listener = TestAdListener(onFailed: { _, code in failedCode = code })

        AdsManager.shared.loadAd(request: request, adListener: listener)
        XCTAssertEqual(failedCode, "PROVIDER_MISMATCH")
    }

    func testPreloadAdAndLoadAdCacheHit() {
        AdsManager.shared.initialize(config: AdsProviderConfig(providerType: .admob, apiKey: "app-id"))
        let request = AdsRequest(triggerId: "reward_scene", adUnitId: "u1", adType: .rewarded, providerType: .admob)

        // Preload
        AdsManager.shared.preloadAd(request: request)
        XCTAssertEqual(fakeAdmobAdapter.loadAdCalls, 1)

        // Load Ad: should hit cache immediately without making another network call
        var loadedEntity: AdsEntity?
        let listener = TestAdListener(onLoaded: { ad in loadedEntity = ad })
        AdsManager.shared.loadAd(request: request, adListener: listener)

        XCTAssertNotNil(loadedEntity)
        XCTAssertEqual(fakeAdmobAdapter.loadAdCalls, 1) // still 1!

        // Consumed! Next load should trigger network call
        AdsManager.shared.loadAd(request: request, adListener: listener)
        XCTAssertEqual(fakeAdmobAdapter.loadAdCalls, 2)
    }

    func testPreloadTtlExpiration() {
        AdsManager.shared.initialize(config: AdsProviderConfig(providerType: .admob, apiKey: "app-id"))
        // TTL = 10_000 ms (10 seconds)
        let request = AdsRequest(triggerId: "expiring_ad", adUnitId: "u1", adType: .splash, providerType: .admob, preloadTtlMs: 10_000)

        AdsManager.shared.preloadAd(request: request)
        XCTAssertEqual(fakeAdmobAdapter.loadAdCalls, 1)

        // Advance clock by 11 seconds
        simulatedTimeMs += 11_000

        var loadedEntity: AdsEntity?
        let listener = TestAdListener(onLoaded: { ad in loadedEntity = ad })
        AdsManager.shared.loadAd(request: request, adListener: listener)

        // Expired entry discarded, network call triggered
        XCTAssertEqual(fakeAdmobAdapter.loadAdCalls, 2)
        XCTAssertNotNil(loadedEntity)
    }

    func testDestroyResetsToIdle() {
        AdsManager.shared.initialize(config: AdsProviderConfig(providerType: .admob, apiKey: "app-id"))
        XCTAssertEqual(AdsManager.shared.getInitState(), .ready)

        AdsManager.shared.destroy()
        XCTAssertEqual(AdsManager.shared.getInitState(), .idle)
        XCTAssertNil(AdsManager.shared.getInitializedProviderType())
        XCTAssertEqual(fakeAdmobAdapter.destroyCalls, 1)
    }

    func testInitializeSetsLogAndDebugSwitches() {
        let config = AdsProviderConfig(providerType: .admob, apiKey: "app-id")
        AdsManager.shared.initialize(config: config)
        XCTAssertFalse(AdsLogger.isEnabled)
        XCTAssertFalse(AdsDebug.isEnabled)

        AdsManager.shared.destroy()
        AdsManager.shared.initialize(config: config, logEnabled: true, debugEnabled: true)
        XCTAssertTrue(AdsLogger.isEnabled)
        XCTAssertTrue(AdsDebug.isEnabled)

        AdsManager.shared.destroy()
        AdsManager.shared.initialize(config: config, logEnabled: false, debugEnabled: false)
        XCTAssertFalse(AdsLogger.isEnabled)
        XCTAssertFalse(AdsDebug.isEnabled)
    }

    func testInitializeAndSetLogHandlerInterceptsLogs() {
        final class LogCollector: @unchecked Sendable {
            private let lock = NSLock()
            private var items: [(AdsLogLevel, String)] = []
            func append(_ level: AdsLogLevel, _ entry: String) {
                lock.lock()
                defer { lock.unlock() }
                items.append((level, entry))
            }
            func snapshot() -> [(AdsLogLevel, String)] {
                lock.lock()
                defer { lock.unlock() }
                return items
            }
        }

        let collector = LogCollector()
        let config = AdsProviderConfig(providerType: .admob, apiKey: "app-id")
        AdsManager.shared.initialize(
            config: config,
            logEnabled: false,
            logHandler: { level, tag, message, _ in
                collector.append(level, "[\(tag)] \(message)")
            }
        )

        let captured = collector.snapshot()
        XCTAssertTrue(captured.contains { $0.0 == .debug && $0.1.contains("initialize start") })
        XCTAssertTrue(captured.contains { $0.0 == .debug && $0.1.contains("initialize complete") })

        let countBeforeClear = captured.count
        AdsManager.shared.setLogHandler(nil)
        AdsManager.shared.destroy()
        XCTAssertEqual(collector.snapshot().count, countBeforeClear)
    }
}

// Helper listener for tests
@MainActor
private final class TestAdListener: AdCallback {
    private let onLoadedClosure: ((AdsEntity) -> Void)?
    private let onFailedClosure: ((String, String?) -> Void)?

    init(
        onLoaded: ((AdsEntity) -> Void)? = nil,
        onFailed: ((String, String?) -> Void)? = nil
    ) {
        self.onLoadedClosure = onLoaded
        self.onFailedClosure = onFailed
    }

    override func onAdLoaded(_ ad: AdsEntity) {
        onLoadedClosure?(ad)
    }

    override func onAdFailedToLoad(error: String, errorCode: String?) {
        onFailedClosure?(error, errorCode)
    }
}
