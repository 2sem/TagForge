import ProjectDescription

public extension String {
    struct projects {
        public static let app = "App"
    }
}

public struct Constants {
    public static let organizationName = "toyboy2"
    public static let baseBundleId = "com.toyboy2.tagforge"
    
    public static let projects: [Path] = [String.projects.app]
        .map { "Projects/\($0)" }
} 
