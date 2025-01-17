//
//  Path+.swift
//  Manifests
//
//  Created by 영준 이 on 1/5/25.
//

import Foundation
import ProjectDescription

public extension Path {
    static func projects(_ path: String) -> Path { .relativeToRoot("Projects/\(path)") }
}
