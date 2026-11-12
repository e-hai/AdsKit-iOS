import Foundation

public enum AdsLogLevel: String, Sendable {
    case debug = "D"
    case warn = "W"
    case error = "E"
}

public typealias AdsLogHandler = @Sendable (AdsLogLevel, String, String, Error?) -> Void
