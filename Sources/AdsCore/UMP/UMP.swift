import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(UserMessagingPlatform)
import UserMessagingPlatform
#endif

@MainActor
public final class UMP {
    private nonisolated static let TAG = "AdsKit-UMP"

    #if canImport(UIKit) && canImport(UserMessagingPlatform)
    public static func start(
        from viewController: UIViewController,
        callBack: @escaping @MainActor (Bool) -> Void
    ) {
        let parameters = RequestParameters()

        if AdsDebug.isEnabled {
            let debugSettings = DebugSettings()
            debugSettings.testDeviceIdentifiers = AdsDebug.admobTestDeviceIds.isEmpty
                ? ["9204E5C14728DD6DD82CE0A440ED41F5"]
                : AdsDebug.admobTestDeviceIds
            debugSettings.geography = .EEA
            parameters.debugSettings = debugSettings
            ConsentInformation.shared.reset()
            AdsLogger.d(TAG, "debugSettings applied, consent reset")
        }

        AdsLogger.d(TAG, "requestConsentInfoUpdate start")
        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { requestError in
            Task { @MainActor in
                if let error = requestError {
                    AdsLogger.e(TAG, "requestConsentInfoUpdate failed: \(error.localizedDescription)")
                    callBack(ConsentInformation.shared.canRequestAds)
                    return
                }

                AdsLogger.d(TAG, "loadAndPresentIfRequired start")
                ConsentForm.loadAndPresentIfRequired(from: viewController) { formError in
                    Task { @MainActor in
                        if let error = formError {
                            AdsLogger.e(TAG, "loadAndPresentIfRequired failed: \(error.localizedDescription)")
                        } else {
                            AdsLogger.d(TAG, "consent gathered successfully")
                        }
                        let canRequest = ConsentInformation.shared.canRequestAds
                        AdsLogger.d(TAG, "UMP completion canRequestAds=\(canRequest)")
                        callBack(canRequest)
                    }
                }
            }
        }
    }
    #else
    public static func start(
        from viewController: Any,
        callBack: @escaping @MainActor (Bool) -> Void
    ) {
        AdsLogger.d(TAG, "UMP not supported on this platform/configuration; passing true")
        callBack(true)
    }
    #endif
}
