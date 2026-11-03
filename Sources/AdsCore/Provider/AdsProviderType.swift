import Foundation

@objc public enum AdsProviderType: Int, Sendable, CaseIterable {
    case admob = 0
    case applovin = 1

    public var name: String {
        switch self {
        case .admob: return "ADMOB"
        case .applovin: return "APPLOVIN"
        }
    }
}
