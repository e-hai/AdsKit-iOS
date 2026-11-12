import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(UserMessagingPlatform)
import UserMessagingPlatform
#endif

@MainActor
public final class UMP {

    #if canImport(UIKit) && canImport(UserMessagingPlatform)
    public static func start(
        from viewController: UIViewController,
        debugEnabled: Bool = false,
        umpTestDeviceIds: [String] = [],
        callBack: @escaping @MainActor (Bool) -> Void
    ) {
        let parameters = RequestParameters()

        if debugEnabled {
            let debugSettings = DebugSettings()
            if !umpTestDeviceIds.isEmpty {
                debugSettings.testDeviceIdentifiers = umpTestDeviceIds
            }
            debugSettings.geography = .EEA
            parameters.debugSettings = debugSettings
            ConsentInformation.shared.reset()
        }

        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { requestError in
            Task { @MainActor in
                if requestError != nil {
                    callBack(ConsentInformation.shared.canRequestAds)
                    return
                }

                ConsentForm.loadAndPresentIfRequired(from: viewController) { _ in
                    Task { @MainActor in
                        callBack(ConsentInformation.shared.canRequestAds)
                    }
                }
            }
        }
    }
    #else
    public static func start(
        from viewController: Any,
        debugEnabled: Bool = false,
        umpTestDeviceIds: [String] = [],
        callBack: @escaping @MainActor (Bool) -> Void
    ) {
        callBack(true)
    }
    #endif
}
