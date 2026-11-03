import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(UserMessagingPlatform)
import UserMessagingPlatform
#endif

@MainActor
public final class UMP {
    private static let TAG = "AdsKit-UMP"

    #if canImport(UIKit) && canImport(UserMessagingPlatform)
    public static func start(
        from viewController: UIViewController,
        callBack: @escaping @MainActor (Bool) -> Void
    ) {
        let parameters = UMPConsentRequestParameters()

        if AdsDebug.isEnabled {
            let debugSettings = UMPDebugSettings()
            debugSettings.testDeviceIdentifiers = AdsDebug.admobTestDeviceIds.isEmpty
                ? ["9204E5C14728DD6DD82CE0A440ED41F5"]
                : AdsDebug.admobTestDeviceIds
            debugSettings.geography = .EEA
            parameters.debugSettings = debugSettings
            UMPConsentInformation.sharedInstance.reset()
            AdsLogger.d(TAG, "debugSettings applied, consent reset")
        }

        AdsLogger.d(TAG, "requestConsentInfoUpdate start")
        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { requestError in
            if let error = requestError {
                AdsLogger.e(TAG, "requestConsentInfoUpdate failed: \(error.localizedDescription)")
                callBack(UMPConsentInformation.sharedInstance.canRequestAds)
                return
            }

            AdsLogger.d(TAG, "loadAndPresentIfRequired start")
            UMPConsentForm.loadAndPresentIfRequired(from: viewController) { formError in
                if let error = formError {
                    AdsLogger.e(TAG, "loadAndPresentIfRequired failed: \(error.localizedDescription)")
                } else {
                    AdsLogger.d(TAG, "consent gathered successfully")
                }
                let canRequest = UMPConsentInformation.sharedInstance.canRequestAds
                AdsLogger.d(TAG, "UMP completion canRequestAds=\(canRequest)")
                callBack(canRequest)
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
