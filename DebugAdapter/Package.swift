// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "LLDBAdapter",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "LLDBAdapter", targets: ["LLDBAdapter"]),
        .library(name: "LLDBObjC", type: .static, targets: ["LLDBObjC"])
    ],
    dependencies: [
    ],
    targets: [
        .executableTarget(name: "LLDBAdapter", dependencies: ["LLDBObjC"]),
        .target(name: "LLDBObjC",
                cSettings: [
                    .headerSearchPath("../../ExternalHeaders/"),
                    .unsafeFlags(["-fmodules", "-fcxx-modules", "-std=c++11", "-stdlib=libc++"])
                ], linkerSettings: [
                    .unsafeFlags(["-F/Applications/Xcode.app/Contents/SharedFrameworks/", "-framework", "LLDB"])
                ])
    ]
)
