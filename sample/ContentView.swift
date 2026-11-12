import SwiftUI
import AdsKit

public struct ContentView: View {
    @State private var selectedProvider: AdsProviderType = .admob
    @State private var initStatus: String = "未初始化"
    @State private var consentStatus: String = "未请求"
    @State private var eventLogs: [String] = []

    // Ad container view reference
    private let adContainerView = UIView()
    @State private var currentContainerEntity: AdsEntity? = nil

    public init() {}

    private var initStateText: String {
        let state = AdsManager.getInitState()
        let activeProvider = AdsManager.getInitializedProviderType()?.name
        if let active = activeProvider {
            return "\(state.description) (\(active))"
        }
        return state.description
    }

    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AdsKit Sample")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("演示 UMP 隐私同意、SDK 初始化、预加载、多种广告类型，以及 Provider 切换。")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Section 1: 隐私同意 (UMP)
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "1. 隐私同意（UMP）")

                        Text("状态: \(consentStatus)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button(action: { requestUmp() }) {
                            Text("请求 UMP 同意")
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }

                        Text("建议流程：UMP → 初始化 SDK → 加载广告（符合欧盟 GDPR 及三方中介隐私合规要求）。")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)

                    // Section 2: Provider 配置与初始化
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "2. Provider 配置与初始化")

                        Picker("Provider", selection: $selectedProvider) {
                            Text("AdMob").tag(AdsProviderType.admob)
                            Text("AppLovin").tag(AdsProviderType.applovin)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedProvider) { newProvider in
                            log("选择 Provider: \(newProvider.name)")
                        }

                        Text("当前: \(selectedProvider.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("状态: \(initStatus) | SDK: \(initStateText)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            Button(action: { initializeProvider() }) {
                                Text("初始化 SDK")
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }

                            Button(action: { destroySdk() }) {
                                Text("销毁 SDK")
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.secondary.opacity(0.2))
                                    .foregroundColor(.primary)
                                    .cornerRadius(8)
                            }
                        }

                        if selectedProvider == .applovin && !SampleConfig.AppLovinUnit.hasRealUnits() {
                            Text("AppLovin 广告位未配置：请在 SampleConfig.swift 中填写真实广告位 ID。")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)

                    // Section 3: 广告场景
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "3. 广告场景")

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            AdActionButton(title: "Banner") { loadBanner() }
                            AdActionButton(title: "开屏 Splash") { loadSplash() }
                            AdActionButton(title: "激励视频 Rewarded") { loadRewarded() }
                            AdActionButton(title: "插屏 Interstitial") { loadInterstitial() }
                            AdActionButton(title: "原生 Native") { loadNative() }
                            AdActionButton(title: "MREC") { loadMrec() }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)

                    // Section 4: 预加载
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "4. 预加载")

                        HStack(spacing: 12) {
                            Button(action: { preloadBanner() }) {
                                Text("预加载 Banner")
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }

                            Button(action: { showCachedBanner() }) {
                                Text("消费预加载 Banner")
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }

                        Text("triggerId=\(SampleConfig.TriggerId.preloadBanner)，首次 loadAd 命中缓存。")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)

                    // Section 5: 调试
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "5. 调试")

                        Button(action: { openDebug() }) {
                            Text("打开 SDK Debug 面板")
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)

                    // Section 6: Banner / Native / MREC 容器
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Banner / Native / MREC 容器")

                        AdContainerRepresentable(containerView: adContainerView)
                            .frame(height: 280)
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.tertiarySystemBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)

                    // Section 7: 事件日志
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            SectionHeader(title: "事件日志 (\(eventLogs.count))")
                            Spacer()
                            Button("清空") {
                                eventLogs.removeAll()
                            }
                            .font(.caption)
                        }

                        if eventLogs.isEmpty {
                            Text("暂无日志")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 16)
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(eventLogs.prefix(25), id: \.self) { line in
                                    Text(line)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Actions & Logic

    private func log(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        eventLogs.insert("[\(timestamp)] \(message)", at: 0)
        #if DEBUG
        print("[AdsKit-Sample] D: \(message)")
        #endif
    }

    private func isContainerAd(type: AdsType) -> Bool {
        return type == .banner || type == .native || type == .mrec
    }

    private func initializeProvider() {
        let provider = selectedProvider
        log("initializeProvider(\(provider.name)) 开始...")
        #if DEBUG
        let isDebug = true
        #else
        let isDebug = false
        #endif
        AdsManager.initialize(
            config: SampleConfig.providerConfig(provider: provider),
            logEnabled: isDebug,
            debugEnabled: isDebug
        ) { success in
            initStatus = success ? "READY (\(provider.name))" : "FAILED"
            log("初始化结果: \(initStatus)")
        }
    }

    private func destroySdk() {
        currentContainerEntity?.destroy()
        currentContainerEntity = nil
        adContainerView.subviews.forEach { $0.removeFromSuperview() }
        AdsManager.destroy()
        initStatus = "IDLE"
        log("SDK 已销毁，状态 IDLE")
    }

    private func requestUmp() {
        guard let topVC = getTopViewController() else {
            log("UMP 请求失败：未找到活跃 ViewController")
            return
        }
        log("开始请求 UMP 同意...")
        #if DEBUG
        let isDebug = true
        #else
        let isDebug = false
        #endif
        UMP.start(from: topVC, debugEnabled: isDebug) { gathered in
            consentStatus = gathered ? "已同意，可初始化广告" : "未同意或受限"
            log("UMP 结果: \(consentStatus)")
        }
    }

    private func loadAd(request: AdsRequest, onLoadedCustom: (() -> Void)? = nil) {
        log("loadAd triggerId=\(request.triggerId) type=\(request.adType.name) provider=\(request.providerType.name)")

        guard let topVC = getTopViewController() else {
            log("loadAd 错误: 未找到当前活跃 UIViewController")
            return
        }

        AdsManager.loadAd(request: request, adListener: SampleCallback(
            onStarted: { [self] in
                log("onAdStartedToLoad \(request.adType.name)")
            },
            onLoaded: { [self] ad in
                log("onAdLoaded \(request.adType.name)")
                if isContainerAd(type: request.adType) {
                    currentContainerEntity?.destroy()
                    currentContainerEntity = ad
                    adContainerView.subviews.forEach { $0.removeFromSuperview() }
                    ad.show(from: topVC, in: adContainerView)
                } else {
                    ad.show(from: topVC)
                }
                onLoadedCustom?()
            },
            onFailed: { [self] error, code in
                log("onAdFailedToLoad \(request.adType.name): \(error) (code=\(code ?? "nil"))")
            },
            onShown: { [self] in
                log("onAdShown \(request.adType.name)")
            },
            onClicked: { [self] in
                log("onAdClicked \(request.adType.name)")
            },
            onClosed: { [self] in
                log("onAdClosed \(request.adType.name)")
            },
            onReward: { [self] in
                log("onAdUserEarnedReward")
            },
            onPaid: { [self] paid in
                log("onAdPaidEvent \(request.adType.name) micros=\(paid.valueMicros) \(paid.currencyCode) precision=\(paid.precision)")
            }
        ))
    }

    private func loadBanner() {
        loadAd(request: SampleConfig.request(provider: selectedProvider, adType: .banner))
    }

    private func loadSplash() {
        loadAd(request: SampleConfig.request(provider: selectedProvider, adType: .splash))
    }

    private func loadRewarded() {
        loadAd(request: SampleConfig.request(provider: selectedProvider, adType: .rewarded))
    }

    private func loadInterstitial() {
        loadAd(request: SampleConfig.request(provider: selectedProvider, adType: .interstitial))
    }

    private func loadNative() {
        loadAd(request: SampleConfig.request(provider: selectedProvider, adType: .native))
    }

    private func loadMrec() {
        loadAd(request: SampleConfig.request(provider: selectedProvider, adType: .mrec))
    }

    private func preloadBanner() {
        let req = SampleConfig.preloadBannerRequest(provider: selectedProvider)
        log("preloadAd triggerId=\(req.triggerId) provider=\(req.providerType.name)")
        AdsManager.preloadAd(request: req)
    }

    private func showCachedBanner() {
        let req = SampleConfig.preloadBannerRequest(provider: selectedProvider)
        loadAd(request: req) {
            log("showCachedBanner: served from preload cache if available")
        }
    }

    private func openDebug() {
        guard let topVC = getTopViewController() else {
            log("openDebug 错误: 未获取到顶层 UIViewController")
            return
        }
        log("openDebug()")
        AdsManager.openDebug(from: topVC)
    }

    private func getTopViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            for window in scene.windows where window.isKeyWindow {
                var top = window.rootViewController
                while let presented = top?.presentedViewController {
                    top = presented
                }
                return top
            }
        }
        return nil
    }
}

// MARK: - Subviews & Callbacks

private struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
    }
}

private struct AdActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentColor.opacity(0.12))
                .foregroundColor(.accentColor)
                .cornerRadius(8)
        }
    }
}

private struct AdContainerRepresentable: UIViewRepresentable {
    let containerView: UIView

    func makeUIView(context: Context) -> UIView {
        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

private final class SampleCallback: AdCallback {
    private let onStartedClosure: () -> Void
    private let onLoadedClosure: (AdsEntity) -> Void
    private let onFailedClosure: (String, String?) -> Void
    private let onShownClosure: () -> Void
    private let onClickedClosure: () -> Void
    private let onClosedClosure: () -> Void
    private let onRewardClosure: () -> Void
    private let onPaidClosure: (AdsPaidEvent) -> Void

    init(
        onStarted: @escaping () -> Void,
        onLoaded: @escaping (AdsEntity) -> Void,
        onFailed: @escaping (String, String?) -> Void,
        onShown: @escaping () -> Void,
        onClicked: @escaping () -> Void,
        onClosed: @escaping () -> Void,
        onReward: @escaping () -> Void,
        onPaid: @escaping (AdsPaidEvent) -> Void
    ) {
        self.onStartedClosure = onStarted
        self.onLoadedClosure = onLoaded
        self.onFailedClosure = onFailed
        self.onShownClosure = onShown
        self.onClickedClosure = onClicked
        self.onClosedClosure = onClosed
        self.onRewardClosure = onReward
        self.onPaidClosure = onPaid
    }

    override func onAdStartedToLoad() { onStartedClosure() }
    override func onAdLoaded(_ ad: AdsEntity) { onLoadedClosure(ad) }
    override func onAdFailedToLoad(error: String, errorCode: String?) { onFailedClosure(error, errorCode) }
    override func onAdShown() { onShownClosure() }
    override func onAdClicked() { onClickedClosure() }
    override func onAdClosed() { onClosedClosure() }
    override func onAdUserEarnedReward() { onRewardClosure() }
    override func onAdPaidEvent(_ paid: AdsPaidEvent) { onPaidClosure(paid) }
}
