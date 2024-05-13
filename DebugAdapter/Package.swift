// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "LLDBAdapter",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "LLDBAdapter", targets: ["LLDBAdapter"]),
        .library(name: "LLDBObjC", type: .static, targets: ["LLDBObjC"]),
        .executable(name: "TestApplication", targets: ["TestApplication"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(name: "LLDBAdapter", dependencies: [
            "LLDBObjC",
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
        .target(name: "LLDBObjC",
                cSettings: [
                    .headerSearchPath("../../ExternalHeaders/"),
                    .unsafeFlags(["-std=c2x", "-stdlib=libc"])
                ], cxxSettings: [
                    .headerSearchPath("../../ExternalHeaders/"),
                    .unsafeFlags(["-fmodules", "-fcxx-modules", "-std=c++1z", "-stdlib=libc++"])
                ], linkerSettings: [
                    // Link against Xcode's LLDB.framework
                    .unsafeFlags(["-F/Applications/Xcode.app/Contents/SharedFrameworks/", "-framework", "LLDB"]),
                ]),
        .executableTarget(name: "TestApplication")
    ]
)
