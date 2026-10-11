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
            scripts: [
                // Must stay the last build phase. Path is relative to SRCROOT (Projects/App).
                .post(
                    script: """
                    # GoogleService-Info.plist is untracked; skip upload when it was not supplied.
                    if [ ! -f "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/GoogleService-Info.plist" ]; then
                      echo "note: GoogleService-Info.plist missing; skipping Crashlytics dSYM upload"
                      exit 0
                    fi
                    "${SRCROOT}/../../Tuist/.build/checkouts/firebase-ios-sdk/Crashlytics/run"
                    """,
                    name: "Upload dSYMs to Crashlytics",
                    inputPaths: [
                        "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}",
                        "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${PRODUCT_NAME}",
                        "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${PRODUCT_NAME}.debug.dylib",
                        "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Info.plist",
                        "$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist",
                        "$(TARGET_BUILD_DIR)/$(EXECUTABLE_PATH)"
                    ],
                    basedOnDependencyAnalysis: false
                )
            ],
            dependencies: [
                .external(name: "FirebaseAnalytics"),
                .external(name: "FirebaseCrashlytics")
            ],
            settings: .settings(base: [
                "ENABLE_USER_SCRIPT_SANDBOXING": "NO"
            ])
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
