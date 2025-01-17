import ProjectDescription

public extension Project {
    static func makeModule(
        name: String,
        product: Product,
        bundleId: String,
        infoPlist: InfoPlist = .default,
        packages: [Package] = [],
        sources: SourceFilesList = ["Sources/**"],
        resources: ResourceFileElements? = nil,
        dependencies: [TargetDependency] = []
    ) -> Project {
        let target = Target.target(
            name: name,
            destinations: [.iPhone, .iPad],
            product: product,
            bundleId: bundleId,
            infoPlist: infoPlist,
            sources: sources,
            resources: resources,
            dependencies: dependencies
        )
        
        return Project(
            name: name,
            targets: [target]
        )
    }
} 
