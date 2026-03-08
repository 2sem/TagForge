import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: .projects.app,
    packages: [
        .package(id: "firebase.firebase-ios-sdk", from: "10.0.0"),
        .package(id: "alamofire.alamofire", from: "5.8.1")
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
            destinations: [.iPhone, .iPad, .macWithiPadDesign],
            product: .app,
            bundleId: Constants.baseBundleId,
            deploymentTargets: .iOS("18.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "TagForge",
                "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
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
