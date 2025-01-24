//
//  Array+.swift
//  App
//
//  Created by 영준 이 on 1/24/25.
//

extension Array {
    func combinations(ofLength length: Int) -> [[Element]] {
        guard length > 0 else { return [[]] }
        guard length <= count else { return [] }
        
        var result: [[Element]] = []
        for (index, element) in enumerated() {
            let rest = Array(dropFirst(index + 1))
            for combination in rest.combinations(ofLength: length - 1) {
                result.append([element] + combination)
            }
        }
        
        return result
    }
}
