// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BECVocab",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "BECVocab",
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "TranslateTool"
        )
    ]
)