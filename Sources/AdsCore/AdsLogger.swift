import Foundation
import os.log

public final class AdsLogger: @unchecked Sendable {
    public static var isEnabled: Bool = true

    public static func d(_ tag: String, _ message: String) {
        guard isEnabled else { return }
        print("[\(tag)] D: \(message)")
    }

    public static func w(_ tag: String, _ message: String) {
        guard isEnabled else { return }
        print("[\(tag)] W: \(message)")
    }

    public static func e(_ tag: String, _ message: String, error: Error? = nil) {
        guard isEnabled else { return }
        if let error = error {
            print("[\(tag)] E: \(message) | error=\(error)")
        } else {
            print("[\(tag)] E: \(message)")
        }
    }
}
