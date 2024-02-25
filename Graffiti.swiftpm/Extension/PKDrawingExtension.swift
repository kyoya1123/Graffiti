//
//  PKDrawingExtension.swift
//  
//
//  Created by Kyoya Yamaguchi on 2024/02/25.
//

import PencilKit

extension PKDrawing: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(dataRepresentation())
    }
    
    public var id: UUID { UUID() }
}
