import Foundation
import os.log

@_spi(AdsKitInternal)
public final class AdsLogger: @unchecked Sendable {
    private static let lock = NSLock()
    private static var _isEnabled: Bool = false
    private static var _logHandler: AdsLogHandler?

    public static var isEnabled: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _isEnabled
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _isEnabled = newValue
        }
    }

    public static var logHandler: AdsLogHandler? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _logHandler
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _logHandler = newValue
        }
    }

    public static func d(_ tag: String, _ message: String) {
        dispatch(.debug, tag, message, error: nil)
    }

    public static func w(_ tag: String, _ message: String) {
        dispatch(.warn, tag, message, error: nil)
    }

    public static func e(_ tag: String, _ message: String, error: Error? = nil) {
        dispatch(.error, tag, message, error: error)
    }

    private static func dispatch(_ level: AdsLogLevel, _ tag: String, _ message: String, error: Error?) {
        lock.lock()
        let handler = _logHandler
        let enabled = _isEnabled
        lock.unlock()

        if let handler = handler {
            handler(level, tag, message, error)
            return
        }
        guard enabled else { return }
        if let error = error {
            print("[\(tag)] \(level.rawValue): \(message) | error=\(error)")
        } else {
            print("[\(tag)] \(level.rawValue): \(message)")
        }
    }
}
