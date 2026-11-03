import Foundation

@objc public enum AdsType: Int, Sendable, CaseIterable {
    case banner = 0
    case splash = 1
    case rewarded = 2
    case interstitial = 3
    case native = 4
    case mrec = 5

    public var name: String {
        switch self {
        case .banner: return "BANNER"
        case .splash: return "SPLASH"
        case .rewarded: return "REWARDED"
        case .interstitial: return "INTERSTITIAL"
        case .native: return "NATIVE"
        case .mrec: return "MREC"
        }
    }
}
