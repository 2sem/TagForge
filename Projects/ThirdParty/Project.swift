import ProjectDescription
import ProjectDescriptionHelpers

let staticPackages: [Package] = [
    .remote(url: "https://github.com/Alamofire/Alamofire.git", requirement: .upToNextMajor(from: "5.8.1")),
    // static framework로 사용 가능한 패키지들
]

let staticDependencies: [TargetDependency] = [
    .package(product: "Alamofire"),
    // static framework로 사용 가능한 패키지 의존성들
]

let project = Project.makeModule(
    name: .projects.thirdParty,
    product: .staticFramework,
    bundleId: "\(Constants.baseBundleId).thirdparty",
    packages: staticPackages,
    sources: [],
    dependencies: staticDependencies
)
