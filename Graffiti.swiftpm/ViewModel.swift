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
import ReplayKit
import ARKit
import SceneKit
import AVKit

class AnimationData {
    var modelEntity: ModelEntity
    var materials: [UnlitMaterial]
    var count: Int = 0
    var drawings: [PKDrawing]
    
    init(modelEntity: ModelEntity, materials: [UnlitMaterial], drawings: [PKDrawing]) {
        self.modelEntity = modelEntity
        self.materials = materials
        self.drawings = drawings
    }
}

class ViewModel: NSObject, ObservableObject {
    
    @Published var arView = ARView()
    @Published var onPlane: Bool = true
    
    @Published var canvasView = PKCanvasView()
    @Published var toolPicker = PKToolPicker()
    @Published var isCanvasVisible = true
    @Published var isCanvasBlank = true
    @Published var drawingHistory: [[PKDrawing]] = []
    var drawingFromHistory = PKDrawing()
    @Published var animationDrawings: [PKDrawing] = []
//    @Published var preMadeMaterials: [UnlitMaterial] = []
    
    @Published var replayView: ReplayPreviewView!
    @Published var isRecording = false
    @Published var showPreviewVideo = true
    
    var animationEntities = [UInt64: AnimationData]()
    var textureTimer: Timer!
    
    func drawingImage(canvasSize: Bool, drawing: PKDrawing? = nil) -> UIImage {
        (drawing ?? canvasView.drawing).image(from: canvasSize ? canvasView.bounds : canvasView.drawing.bounds, scale: 3)
    }
    
    override init() {
        super.init()
        textureTimer = .scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            self.updateTexture()
        }
        RPScreenRecorder.shared().isMicrophoneEnabled = true
    }
    
    @Published var tapSelectedEntity: Entity?
    
    func tap(location: CGPoint) {
        let hitTestResults = arView.hitTest(location)
        guard let node = hitTestResults.first?.entity else { return }
        tapSelectedEntity = node
    }
    
    func addDrawing(location: CGPoint, onPlane: Bool = true) {
        if !animationDrawings.isEmpty, !isCanvasBlank {
            animationDrawings.append(canvasView.drawing)
//            preMadeMaterials.append(createTexture(drawing: drawingImage(canvasSize: true).cgImage))
        }

        if canvasView.drawing != drawingFromHistory && (!animationDrawings.isEmpty || (animationDrawings.isEmpty && !isCanvasBlank)) {
            withAnimation {
                drawingHistory.append(animationDrawings.isEmpty ? [canvasView.drawing] : animationDrawings)
            }
            saveDrawingHistory()
        } else {
            drawingFromHistory = PKDrawing()
        }
        
        let drawing = animationDrawings.isEmpty ? drawingImage(canvasSize: !onPlane).cgImage! : drawingImage(canvasSize: true, drawing: animationDrawings.first).cgImage!
        let mesh: MeshResource = {
            if onPlane {
                let baseNum: Float = 0.6 / Float(max(drawing.width, drawing.height))
                return .generatePlane(width: Float(drawing.width) * baseNum, depth: Float(drawing.height) * baseNum)
            } else {
                let baseNum: Float = 0.6 / Float(drawing.height)
                return .generatePlane(width: Float(drawing.width) * baseNum, height: Float(drawing.height) * baseNum)
            }
        }()
        
        let modelEntity = ModelEntity(mesh: mesh)
        modelEntity.model?.materials = [createTexture(drawing: drawing)]
        modelEntity.generateCollisionShapes(recursive: true)
        
        var anchor: AnchorEntity!
        if onPlane {
            guard let result = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any).first else  { return }
            #if !(targetEnvironment(simulator))
            anchor = AnchorEntity(raycastResult: result)
            #endif
        } else {
            let cameraTransform: Transform = arView.cameraTransform
            let localCameraPosition: SIMD3<Float> = modelEntity.convert(position: cameraTransform.translation, from: nil)
            let cameraForwardVector: SIMD3<Float> = cameraTransform.matrix.forward
            modelEntity.transform.translation = localCameraPosition + cameraForwardVector * 0.72
            modelEntity.transform.rotation = cameraTransform.rotation
            anchor = AnchorEntity(world: .zero)
        }
        
        if !animationDrawings.isEmpty {
            animationEntities[modelEntity.id] = AnimationData(modelEntity: modelEntity, materials: animationDrawings.map { createTexture(drawing: drawingImage(canvasSize: true, drawing: $0).cgImage) }, drawings: animationDrawings)
        }
        anchor.addChild(modelEntity)
        arView.scene.addAnchor(anchor)
        arView.installGestures(onPlane ? .all : [.scale, .translation], for: modelEntity)
        canvasView.drawing = PKDrawing()
        animationDrawings = []
    }
    
    func removeDrawing() {
        if let tapSelectedEntity = tapSelectedEntity {
            tapSelectedEntity.removeFromParent()
            animationEntities.removeValue(forKey: tapSelectedEntity.id)
        }
        tapSelectedEntity = nil
    }
    
    func takePicture() {
        arView.snapshot(saveToHDR: false) { image in
            guard let image = image else { return }
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
    }
    
    func updateToolPicker() {
        toolPicker.setVisible(isCanvasVisible, forFirstResponder: canvasView)
        if isCanvasVisible {
            DispatchQueue.main.async {
                self.toolPicker.addObserver(self.canvasView)
                self.canvasView.becomeFirstResponder()
            }
        }
    }
    
    func startRecording() {
        if !RPScreenRecorder.shared().isRecording {
            isRecording = true
            RPScreenRecorder.shared().startRecording { error in
                if let error = error {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func updateTexture() {
        guard !animationEntities.isEmpty else { return }
        animationEntities.forEach {
            let animationData = $0.value
            animationData.count = animationData.count == animationData.materials.count - 1 ? 0 : animationData.count + 1
            animationData.modelEntity.model?.materials = [animationData.materials[animationData.count]]
        }
    }
    
    
    
    func createTexture(drawing: CGImage?) -> UnlitMaterial {
        guard let texture = try? TextureResource.generate(from: drawing!, options: .init(semantic: .hdrColor)) else { return UnlitMaterial() }
        var unlitMaterial = UnlitMaterial()
        unlitMaterial.color = .init(tint: .white, texture: .init(texture))
        unlitMaterial.blending = .transparent(opacity: .init(floatLiteral: 1))
        return unlitMaterial
    }
    
    func saveDrawingHistory() {
        DispatchQueue.global(qos: .background).async {
            UserDefaults.standard.set(self.drawingHistory.map { $0.map { $0.dataRepresentation() }}, forKey: "drawingHistory")
        }
    }
}

extension ViewModel: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        isCanvasBlank = canvasView.drawing.strokes.isEmpty
    }
}
