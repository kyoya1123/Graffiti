//
//  ArrayExtension.swift
//  
//
//  Created by Kyoya Yamaguchi on 2024/02/24.
//

import Foundation

extension Array where Element: Equatable {
    mutating func remove(element: Element) {
        if let index = firstIndex(of: element) {
            remove(at: index)
        }
    }
}
