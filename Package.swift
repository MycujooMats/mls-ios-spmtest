// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "MLSSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v11),
        .tvOS(.v11)
    ],
    products: [
        .library(name: "MLSSDK", targets: ["MLSSDK"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/Moya/Moya.git", .upToNextMajor(from: "14.0.0"))
    ],
    targets: [
        .target(
            name: "MLSSDK",
            dependencies: ["Alamofire", "Moya"],
            path: "Sources/Core",
            exclude: ["Core/App/Support Files/Info.plist", "Examples"],
            resources: [
                .copy("Core/Resources/fonts/RobotoMono-Regular.ttf"),
                .copy("Core/Resources/fonts/RobotoMono-Bold.ttf"),
                .copy("Core/Resources/fonts/NotoSansMono_ExtraCondensed-Regular.ttf")])
        
    ]
)
