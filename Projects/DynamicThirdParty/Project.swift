import ProjectDescription
import ProjectDescriptionHelpers

let dynamicPackages: [Package] = [
    .remote(url: "https://github.com/firebase/firebase-ios-sdk.git", requirement: .upToNextMajor(from: "10.0.0")),
]

let project = Project.makeModule(
    name: .projects.dynamicThirdParty,
    product: .framework,
    bundleId: "\(Constants.baseBundleId).dynamicthirdparty",
    packages: dynamicPackages,
    sources: [],
    dependencies: [
        .package(product: "FirebaseAnalytics"),
        .package(product: "FirebaseAuth"),
        .package(product: "FirebaseFirestore"),
        .package(product: "FirebaseStorage"),
        .package(product: "FirebaseCrashlytics"),
    ]
)
