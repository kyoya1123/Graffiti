//
//  ViewModel.swift
//  Graffiti
//
//  Created by Kyoya Yamaguchi on 2024/02/18.
//

import UIKit
import PencilKit
import SwiftUI
import RealityKit

class ViewModel: NSObject, ObservableObject {
    @Published var canvasView = PKCanvasView()
    @Published var arView = ARView()
    @Published var selectedColor: Color = .black
    @Published var isCanvasVisible = false
    @Published var isCanvasBlank = true
    
    func addDrawing() {
        guard let drawing = canvasView.asImage()?.cgImage else { return }
        let baseNum: Float = 0.6 / Float(drawing.height)
        let modelEntity = ModelEntity(mesh: MeshResource.generatePlane(width: Float(drawing.width) * baseNum, height: Float(drawing.height) * baseNum))
        modelEntity.generateCollisionShapes(recursive: true)
        modelEntity.model?.materials = [createTexture(drawing: drawing)]
        
        let cameraTransform: Transform = arView.cameraTransform
        let localCameraPosition: SIMD3<Float> = modelEntity.convert(position: cameraTransform.translation, from: nil)
        let cameraForwardVector: SIMD3<Float> = cameraTransform.matrix.forward
        
        modelEntity.transform.translation = localCameraPosition + cameraForwardVector * 0.72
        modelEntity.transform.rotation = cameraTransform.rotation
        
        let anchor = AnchorEntity(world: .zero)
        anchor.addChild(modelEntity)
        arView.scene.addAnchor(anchor)
        arView.installGestures([.scale], for: modelEntity)
        canvasView.drawing = PKDrawing()
    }

    private func createTexture(drawing: CGImage?) -> UnlitMaterial {
        let texture = try! TextureResource.generate(from: drawing!, options: .init(semantic: .normal))
        var unlitMaterial = UnlitMaterial()
        unlitMaterial.color = .init(tint: .white, texture: .init(texture))
        unlitMaterial.blending = .transparent(opacity: .init(floatLiteral: 1))
        return unlitMaterial
    }
    
    func takePicture() {
        arView.snapshot(saveToHDR: false) { image in
            guard let image = image else { return }
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
    }
}

extension ViewModel: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        isCanvasBlank = canvasView.drawing.strokes.isEmpty
    }
}
