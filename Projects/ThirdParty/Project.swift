import ProjectDescription
import ProjectDescriptionHelpers

let staticDependencies: [TargetDependency] = [
    .external(name: "Alamofire"),
    // static framework로 사용 가능한 패키지 의존성들
]

let project = Project.makeModule(
    name: .projects.thirdParty,
    product: .staticFramework,
    bundleId: "\(Constants.baseBundleId).thirdparty",
    sources: [],
    dependencies: staticDependencies
)
