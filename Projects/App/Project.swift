import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: .projects.app,
    packages: [
        .remote(url: "https://github.com/firebase/firebase-ios-sdk.git", requirement: .upToNextMajor(from: "10.0.0")),
        .remote(url: "https://github.com/Alamofire/Alamofire.git", requirement: .upToNextMajor(from: "5.8.1"))
    ],
    settings: .settings(
        base: [:],
        configurations: [
            .debug(name: "Debug", xcconfig: "Configs/Debug.xcconfig"),
            .release(name: "Release", xcconfig: "Configs/Release.xcconfig")
        ]
    ),
    targets: [
        Target.target(
            name: .projects.app,
            destinations: [.iPhone, .iPad],
            product: .app,
            bundleId: Constants.baseBundleId,
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "TagForge",
                "UILaunchStoryboardName": "LaunchScreen",
                "UIBackgroundModes": ["remote-notification"],
                "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"]
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .project(name: .projects.thirdParty),
                .project(name: .projects.dynamicThirdParty)
            ]
        )
    ]
) 
