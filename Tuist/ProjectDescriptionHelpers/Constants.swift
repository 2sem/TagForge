import ProjectDescription

public extension String {
    struct projects {
        public static let app = "App"
        public static let thirdParty = "ThirdParty"
        public static let dynamicThirdParty = "DynamicThirdParty"
    }
}

public struct Constants {
    public static let organizationName = "toyboy2"
    public static let baseBundleId = "com.toyboy2.tagforge"
    
    public static let projects: [Path] = [String.projects.app, String.projects.thirdParty, String.projects.dynamicThirdParty]
        .map { "Projects/\($0)" }
} 
