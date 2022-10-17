// swift-tools-version:5.7
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
    ],
    targets: [
        .executableTarget(name: "LLDBAdapter", dependencies: ["LLDBObjC"]),
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
                    // Add common locations of Xcode to rpath search paths
                    .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "/Applications/Xcode.app/Contents/SharedFrameworks/"]),
                    .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "/Applications/Xcode-beta.app/Contents/SharedFrameworks/"])
                ]),
        .executableTarget(name: "TestApplication")
    ]
)
