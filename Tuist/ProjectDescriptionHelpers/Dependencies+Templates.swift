import ProjectDescription

public extension TargetDependency {
    static func project(name: String) -> TargetDependency {
        .project(target: name, path: .relativeToRoot("Projects/\(name)"))
    }
} 