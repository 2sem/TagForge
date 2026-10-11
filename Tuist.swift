import ProjectDescription

let tuist = Tuist(
    fullHandle: "gamehelper/tagforge",
    project: .tuist(
        compatibleXcodeVersions: .upToNextMajor("27.0"),
        generationOptions: .options(
            enableCaching: true,
            registryEnabled: true
        )
    )
)
