//
//  ARView.swift
//  Graffiti
//
//  Created by Kyoya Yamaguchi on 2024/02/18.
//

import SwiftUI
import RealityKit
import ARKit

struct RealityView: UIViewRepresentable {
    
    @Binding var arView: ARView
    
    func makeUIView(context: Context) -> ARView {
        arView.environment.sceneUnderstanding.options.insert(.occlusion)
        arView.renderOptions = [.disableGroundingShadows]
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

