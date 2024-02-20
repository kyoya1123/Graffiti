//
//  File.swift
//  
//
//  Created by Kyoya Yamaguchi on 2024/02/20.
//

import SwiftUI
import ARKit

struct ARSCNViewRepresentable: UIViewRepresentable {
    
    @Binding var sceneView: ARSCNView
    
    func makeUIView(context: Context) -> ARSCNView {
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.preferredFramesPerSecond = 120
        let config = ARWorldTrackingConfiguration()
        config.frameSemantics = .personSegmentationWithDepth
        sceneView.session.run(config)
        return sceneView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}
