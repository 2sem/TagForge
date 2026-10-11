import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: .projects.app,
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
                "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
                "ITSAppUsesNonExemptEncryption": false
            ]),
            sources: ["Sources/**"],
            resources: ["Resources/**"],
            dependencies: [
                .project(name: .projects.dynamicThirdParty)
            ]
        ),
        Target.target(
            name: "AppTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "\(Constants.baseBundleId).tests",
            deploymentTargets: .iOS("18.0"),
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [
                .target(name: .projects.app)
            ]
        )
    ]
) 
