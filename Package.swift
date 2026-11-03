// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AdsKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v12)
    ],
    products: [
        .library(name: "AdsCore", targets: ["AdsCore"]),
        .library(name: "AdsAdmob", targets: ["AdsAdmob"]),
        .library(name: "AdsApplovin", targets: ["AdsApplovin"]),
        .library(name: "AdsKit", targets: ["AdsKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", "11.0.0"..<"13.0.0"),
        .package(url: "https://github.com/AppLovin/AppLovin-MAX-Swift-Package.git", "13.0.0"..<"14.0.0"),
    ],
    targets: [
        .target(
            name: "AdsCore",
            dependencies: []
        ),
        .target(
            name: "AdsAdmob",
            dependencies: [
                "AdsCore",
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads", condition: .when(platforms: [.iOS]))
            ]
        ),
        .target(
            name: "AdsApplovin",
            dependencies: [
                "AdsCore",
                .product(name: "AppLovinSDK", package: "AppLovin-MAX-Swift-Package", condition: .when(platforms: [.iOS]))
            ]
        ),
        .target(
            name: "AdsKit",
            dependencies: [
                "AdsCore",
                "AdsAdmob",
                "AdsApplovin"
            ]
        ),
        .testTarget(
            name: "AdsCoreTests",
            dependencies: ["AdsCore"]
        ),
    ]
)
