import XCTest
@testable import AdsCore

final class AdsProviderAdapterFactoryTests: XCTestCase {
    @MainActor
    override func setUp() {
        super.setUp()
        AdsProviderAdapterFactory.reset()
    }

    @MainActor
    func testRegistrationAndAvailability() {
        XCTAssertFalse(AdsProviderAdapterFactory.isAvailable(.admob))
        XCTAssertFalse(AdsProviderAdapterFactory.isAvailable(.applovin))

        struct TestRegistrar: AdsProviderAdapterRegistrar {
            let providerType: AdsProviderType = .admob
            func create() -> AdsProviderAdapter {
                FakeAdsProviderAdapter(providerType: .admob)
            }
        }

        AdsProviderAdapterFactory.register(TestRegistrar())
        XCTAssertTrue(AdsProviderAdapterFactory.isAvailable(.admob))
        XCTAssertFalse(AdsProviderAdapterFactory.isAvailable(.applovin))

        XCTAssertNoThrow(try AdsProviderAdapterFactory.create(.admob))
        XCTAssertThrowsError(try AdsProviderAdapterFactory.create(.applovin)) { error in
            XCTAssertTrue(error is ProviderNotAvailableError)
        }
    }
}
