import Foundation

@MainActor
public final class AdsProviderAdapterFactory {
    private static var registrars: [AdsProviderType: AdsProviderAdapterRegistrar] = [:]

    public static func register(_ registrar: AdsProviderAdapterRegistrar) {
        registrars[registrar.providerType] = registrar
    }

    public static func unregister(_ providerType: AdsProviderType) {
        registrars.removeValue(forKey: providerType)
    }

    public static func isAvailable(_ providerType: AdsProviderType) -> Bool {
        return registrars[providerType] != nil
    }

    public static func create(_ providerType: AdsProviderType) throws -> AdsProviderAdapter {
        guard let registrar = registrars[providerType] else {
            throw ProviderNotAvailableError(providerType: providerType)
        }
        return registrar.create()
    }

    internal static func reset() {
        registrars.removeAll()
    }
}
