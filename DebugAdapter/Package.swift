// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "LLDBAdapter",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "LLDBAdapter", targets: ["LLDBAdapter"]),
        .library(name: "SwiftLLDB", targets: ["SwiftLLDB"]),
        .executable(name: "TestApplication", targets: ["TestApplication"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "LLDBAdapter",
            dependencies: [
                "SwiftLLDB",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx),
            ]
        ),
        .target(name: "SwiftLLDB",
            dependencies: ["CxxLLDB"],
            cSettings: [
                .headerSearchPath("../CxxLLDB/"),
            ],
            cxxSettings: [
                .headerSearchPath("../CxxLLDB/"),
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx),
            ],
            linkerSettings: [
                // Link against Xcode's LLDB.framework
                .unsafeFlags(["-F/Applications/Xcode.app/Contents/SharedFrameworks/", "-framework", "LLDB"]),
            ]
        ),
        .systemLibrary(name: "CxxLLDB"),
        .executableTarget(name: "TestApplication"),
    ]
)
