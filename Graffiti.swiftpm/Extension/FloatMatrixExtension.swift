//
//  FloatMatrixExtension.swift
//  Graffiti
//
//  Created by Kyoya Yamaguchi on 2024/02/18.
//

import simd

extension float4x4 {
    var forward: SIMD3<Float> {
        normalize(SIMD3<Float>(-columns.2.x, -columns.2.y, -columns.2.z))
    }
}
