import SwiftUI
import AdsKit

public struct ContentView: View {
    @State private var selectedProvider: AdsProviderType = .admob
    @State private var logs: [String] = []
    @State private var loadedEntities: [String: AdsEntity] = [:]

    public init() {}

    public var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Provider Selector
                Picker("Provider", selection: $selectedProvider) {
                    Text("AdMob").tag(AdsProviderType.admob)
                    Text("AppLovin").tag(AdsProviderType.applovin)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: selectedProvider) { newProvider in
                    reinitialize(provider: newProvider)
                }

                // Action Buttons Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    Button("Preload Splash") { preloadAd(type: .splash) }
                    Button("Load & Show Splash") { loadAndShowAd(type: .splash) }

                    Button("Preload Rewarded") { preloadAd(type: .rewarded) }
                    Button("Load & Show Rewarded") { loadAndShowAd(type: .rewarded) }

                    Button("Load Interstitial") { loadAndShowAd(type: .interstitial) }
                    Button("Open Ad Inspector") { openDebug() }
                }
                .padding(.horizontal)

                Divider()

                // Banner Container Placeholder
                Text("Banner Container")
                    .font(.caption)
                    .foregroundColor(.secondary)
                UIViewContainer()
                    .frame(height: 60)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
                    .padding(.horizontal)

                // Event Logs
                List(logs, id: \.self) { log in
                    Text(log)
                        .font(.system(size: 11, design: .monospaced))
                }
                .listStyle(.plain)
            }
            .navigationTitle("AdsKit iOS Sample")
        }
    }

    private func appendLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        logs.insert("[\(timestamp)] \(message)", at: 0)
    }

    private func reinitialize(provider: AdsProviderType) {
        let key = (provider == .admob) ? SampleConfig.admobAppId : SampleConfig.applovinSdkKey
        appendLog("Switching to \(provider.name)...")
        AdsManager.initialize(config: AdsProviderConfig(providerType: provider, apiKey: key)) { success in
            appendLog("Initialized \(provider.name): \(success)")
        }
    }

    private func preloadAd(type: AdsType) {
        let unitId = getUnitId(for: type)
        let request = AdsRequest(
            triggerId: "preload_\(type.name.lowercased())",
            adUnitId: unitId,
            adType: type,
            providerType: selectedProvider
        )
        appendLog("Preload requested: \(type.name)")
        AdsManager.preloadAd(request: request)
    }

    private func loadAndShowAd(type: AdsType) {
        let unitId = getUnitId(for: type)
        let request = AdsRequest(
            triggerId: "preload_\(type.name.lowercased())",
            adUnitId: unitId,
            adType: type,
            providerType: selectedProvider
        )

        appendLog("Loading: \(type.name)...")
        AdsManager.loadAd(request: request, adListener: SampleAdCallback(
            onLoaded: { entity in
                appendLog("\(type.name) loaded successfully")
                if let topVC = UIApplication.shared.connectedScenes
                    .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
                    .first {
                    entity.show(from: topVC)
                }
            },
            onFailed: { error, code in
                appendLog("\(type.name) failed: \(error) (\(code ?? "nil"))")
            },
            onShown: { appendLog("\(type.name) shown") },
            onClosed: { appendLog("\(type.name) closed") },
            onReward: { appendLog("\(type.name) reward earned!") }
        ))
    }

    private func openDebug() {
        if let topVC = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
            .first {
            AdsManager.openDebug(from: topVC)
        }
    }

    private func getUnitId(for type: AdsType) -> String {
        switch selectedProvider {
        case .admob:
            switch type {
            case .banner: return SampleConfig.admobBannerUnitId
            case .splash: return SampleConfig.admobAppOpenUnitId
            case .rewarded: return SampleConfig.admobRewardedUnitId
            case .interstitial: return SampleConfig.admobInterstitialUnitId
            case .native: return SampleConfig.admobNativeUnitId
            case .mrec: return SampleConfig.admobMrecUnitId
            }
        case .applovin:
            switch type {
            case .banner: return SampleConfig.applovinBannerUnitId
            case .splash: return SampleConfig.applovinAppOpenUnitId
            case .rewarded: return SampleConfig.applovinRewardedUnitId
            case .interstitial: return SampleConfig.applovinInterstitialUnitId
            case .native: return SampleConfig.applovinNativeUnitId
            case .mrec: return SampleConfig.applovinMrecUnitId
            }
        }
    }
}

private final class SampleAdCallback: AdCallback {
    private let onLoadedClosure: (AdsEntity) -> Void
    private let onFailedClosure: (String, String?) -> Void
    private let onShownClosure: () -> Void
    private let onClosedClosure: () -> Void
    private let onRewardClosure: () -> Void

    init(
        onLoaded: @escaping (AdsEntity) -> Void,
        onFailed: @escaping (String, String?) -> Void,
        onShown: @escaping () -> Void,
        onClosed: @escaping () -> Void,
        onReward: @escaping () -> Void
    ) {
        self.onLoadedClosure = onLoaded
        self.onFailedClosure = onFailed
        self.onShownClosure = onShown
        self.onClosedClosure = onClosed
        self.onRewardClosure = onReward
    }

    override func onAdLoaded(_ ad: AdsEntity) { onLoadedClosure(ad) }
    override func onAdFailedToLoad(error: String, errorCode: String?) { onFailedClosure(error, errorCode) }
    override func onAdShown() { onShownClosure() }
    override func onAdClosed() { onClosedClosure() }
    override func onAdUserEarnedReward() { onRewardClosure() }
}

private struct UIViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}
