// swift-tools-version: 5.9
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "RealmOfEmpires",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "RealmOfEmpires",
            targets: ["AppModule"],
            bundleIdentifier: "com.game.RealmOfEmpires",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .gamecontroller),
            accentColor: .presetColor(.brown),
            supportedDeviceFamilies: [.pad, .phone],
            supportedInterfaceOrientations: [
                .landscapeLeft,
                .landscapeRight
            ],
            capabilities: []
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "Sources"
        )
    ]
)
