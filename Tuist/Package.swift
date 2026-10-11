// swift-tools-version: 5.9
import PackageDescription

#if TUIST
import ProjectDescription

// Every external product stays a static framework (Tuist's default). They are linked
// into the DynamicThirdParty wrapper, which keeps a single copy of Firebase's transitive
// targets inside DynamicThirdParty.framework.
let packageSettings = PackageSettings(productTypes: [:])
#endif

let package = Package(
    name: "TagForge",
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
    ]
)
