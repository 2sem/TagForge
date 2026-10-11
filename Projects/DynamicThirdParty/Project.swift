import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.makeModule(
    name: .projects.dynamicThirdParty,
    product: .framework,
    bundleId: "\(Constants.baseBundleId).dynamicthirdparty",
    sources: [],
    dependencies: [
        .external(name: "FirebaseAnalytics"),
        .external(name: "FirebaseAuth"),
        .external(name: "FirebaseFirestore"),
        .external(name: "FirebaseStorage"),
        .external(name: "FirebaseCrashlytics"),
    ]
)
