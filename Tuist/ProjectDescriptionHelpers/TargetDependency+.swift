//
//  TargetDependency+.swift
//  Manifests
//
//  Created by 영준 이 on 1/5/25.
//

import Foundation
import ProjectDescription

// MARK: Store Projects
public extension TargetDependency {
    class Projects {
        public static let ThirdParty: TargetDependency = .project(target: .projects.thirdParty,
                                               path: .projects(.projects.thirdParty))
        public static let DynamicThirdParty: TargetDependency = .project(target: .projects.dynamicThirdParty,
                                                                         path: .projects(.projects.dynamicThirdParty))
    }
}
