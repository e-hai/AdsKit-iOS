import Foundation

@objc public enum AdsInitState: Int, Sendable, CustomStringConvertible {
    case idle = 0
    case initializing = 1
    case ready = 2
    case failed = 3

    public var description: String {
        switch self {
        case .idle: return "IDLE"
        case .initializing: return "INITIALIZING"
        case .ready: return "READY"
        case .failed: return "FAILED"
        }
    }
}
