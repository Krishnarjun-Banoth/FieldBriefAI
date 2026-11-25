// swift-tools-version: 6.2
import PackageDescription

// Linux-compatible core tests. The iOS app itself is generated using project.yml.
let package = Package(
    name: "FieldBriefCore",
    platforms: [.iOS(.v26)],
    products: [.library(name: "FieldBriefCore", targets: ["FieldBriefCore"])],
    targets: [
        .target(name: "FieldBriefCore", path: "FieldBriefAI/Core"),
        .testTarget(name: "FieldBriefCoreTests", dependencies: ["FieldBriefCore"], path: "CoreTests")
    ]
)
