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

class ViewModel: NSObject, ObservableObject {
//    @Published var sceneView = ARSCNView()
    @Published var arView = ARView()
    
    @Published var canvasView = PKCanvasView()
    @Published var toolPicker = PKToolPicker()
    @Published var isCanvasVisible = true
    @Published var isCanvasBlank = true
    @Published var drawingHistory: [Data] = []
    var drawingFromHistory = PKDrawing()
    
    @Published var replayView: ReplayPreviewView!
    @Published var isRecording = false
    @Published var showPreviewVideo = false
    
//        var textureTimer: Timer!
////        var nodes = [SCNNode]()
//    var nodes = [ModelEntity]()
//        var number = 0
//        let images = [UIImage(named: "drawing0"), UIImage(named: "drawing1"), UIImage(named: "drawing2")]
//    
    func drawingImage(canvasSize: Bool) -> UIImage {
        canvasView.drawing.image(from: canvasSize ? canvasView.bounds : canvasView.drawing.bounds, scale: 3)
//        canvasView.drawing.image(from: canvasView.drawing.bounds, scale: 3)
    }
    
    override init() {
        super.init()
//                textureTimer = .scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
//                    self.number = self.number == 2 ? 0 : self.number + 1
//                    self.updateTexture()
//                }
        RPScreenRecorder.shared().isMicrophoneEnabled = true
//        setupGesture()
        updateToolPicker()
    }
    
//    func setupGesture() {
//        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch(_:)))
//        sceneView.addGestureRecognizer(pinchGestureRecognizer)
//        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(drag(_:)))
//        sceneView.addGestureRecognizer(panGestureRecognizer)
////        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
////        sceneView.addGestureRecognizer(tapGestureRecognizer)
//    }
//    
//    @objc func pinch(_ recognizer: UIPinchGestureRecognizer) {
//        let tapLocation = recognizer.location(in: sceneView)
//        let hitTestResults = sceneView.hitTest(tapLocation)
//        guard let node = hitTestResults.first?.node, recognizer.state == .changed else { return }
//        
//        let scalex = Float(recognizer.scale) * node.scale.x
//        let scaley =  Float(recognizer.scale) * node.scale.y
//        node.scale = SCNVector3(x: Float(scalex), y: Float(scaley), z: 1)
//        recognizer.scale = 1
//    }
    
//    var dragCoordinates = SCNVector3(0, 0, 0)
//    var dragSelectedNode: SCNNode!
//    
//    @objc func drag(_ recognizer: UIPanGestureRecognizer) {
//        switch recognizer.state {
//        case .began:
//            let location = recognizer.location(in: sceneView)
//            guard let hitNodeResult = sceneView.hitTest(location, options: nil).first else { return }
//            dragCoordinates = hitNodeResult.worldCoordinates
//            dragSelectedNode = hitNodeResult.node
//        case .changed:
//            let hitNode = sceneView.hitTest(recognizer.location(in: sceneView), options: nil)
//            if let nodeCoordinates = hitNode.first?.worldCoordinates {
//                let action = SCNAction.moveBy(x: CGFloat(nodeCoordinates.x - dragCoordinates.x),
//                                              y: CGFloat(nodeCoordinates.y - dragCoordinates.y),
//                                              z: CGFloat(nodeCoordinates.z - dragCoordinates.z),
//                                              duration: 0.0)
//                dragSelectedNode.runAction(action)
//                dragCoordinates = nodeCoordinates
//            }
//            recognizer.setTranslation(.zero, in: sceneView)
//        default:
//            break
//        }
//    }
    
    
    
//    @Published var tapSelectedNode: SCNNode?
    @Published var tapSelectedEntity: Entity?
    
//    @objc func tap(_ recognizer: UITapGestureRecognizer) {
//        let location = recognizer.location(in: sceneView)
//        let hitTestResults = sceneView.hitTest(location)
//        guard let node = hitTestResults.first?.node else { return }
//        tapSelectedNode = node
//    }
    func tap(location: CGPoint) {
        let hitTestResults = arView.hitTest(location)
        guard let node = hitTestResults.first?.entity else { return }
        tapSelectedEntity = node
    }
    
    func addDrawing(location: CGPoint, onPlane: Bool = true) {
        if canvasView.drawing != drawingFromHistory {
            withAnimation {
                drawingHistory.append(canvasView.drawing.dataRepresentation())
            }
        } else {
            drawingFromHistory = PKDrawing()
        }
//        let filter = CIFilter.colorControls()
//        filter.inputImage = drawingImage.ciImage
//        filter.contrast = 2
        //filter.generateUIImageFromOutput(orientation: drawingImage.imageOrientation).cgImage!
        //MARK: ARSCNView
        //        canvasView.drawing = PKDrawing()
        //        let baseNum = 0.6 / CGFloat(drawing.size.height)
        //        let planeNode = SCNNode(geometry: SCNPlane(width: CGFloat(drawing.size.width) * baseNum, height: CGFloat(drawing.size.height) * baseNum))
        //        planeNode.geometry!.firstMaterial?.diffuse.contents = drawing
        //        let targetPos = SCNVector3(0, 0, -0.72)
        //        planeNode.position = sceneView.pointOfView!.convertPosition(targetPos, to: nil)
        //        planeNode.rotation = sceneView.pointOfView!.rotation
        //        //        nodes.append(planeNode)
        //        sceneView.scene.rootNode.addChildNode(planeNode)
        
        //MARK: RealityView
        if onPlane {
            let drawing = drawingImage(canvasSize: false).cgImage!
            let baseNum: Float = 0.6 / Float(max(drawing.width, drawing.height))
            let modelEntity = ModelEntity(mesh: MeshResource.generatePlane(width: Float(drawing.width) * baseNum, depth: Float(drawing.height) * baseNum))
            modelEntity.model?.materials = [createTexture(drawing: drawing)]
            modelEntity.generateCollisionShapes(recursive: true)
//            nodes.append(modelEntity)
            guard let result = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any).first else  { return }
            let anchor = AnchorEntity(raycastResult: result)
            anchor.addChild(modelEntity)
            arView.scene.addAnchor(anchor)
            arView.installGestures(.all, for: modelEntity)
            canvasView.drawing = PKDrawing()
        } else {
            let drawing = drawingImage(canvasSize: true).cgImage!
            let baseNum: Float = 0.6 / Float(drawing.height)
            let modelEntity = ModelEntity(mesh: MeshResource.generatePlane(width: Float(drawing.width) * baseNum, height: Float(drawing.height) * baseNum))
            modelEntity.model?.materials = [createTexture(drawing: drawing)]
            modelEntity.generateCollisionShapes(recursive: true)
            let cameraTransform: Transform = arView.cameraTransform
            let localCameraPosition: SIMD3<Float> = modelEntity.convert(position: cameraTransform.translation, from: nil)
            let cameraForwardVector: SIMD3<Float> = cameraTransform.matrix.forward
    
            modelEntity.transform.translation = localCameraPosition + cameraForwardVector * 0.72
            modelEntity.transform.rotation = cameraTransform.rotation
//            nodes.append(modelEntity)
            let anchor = AnchorEntity(world: .zero)
            anchor.addChild(modelEntity)
            arView.scene.addAnchor(anchor)
            arView.installGestures([.scale, .translation], for: modelEntity)
            canvasView.drawing = PKDrawing()
        }
    }
    
    //MARK: place on plane
    //    @objc func tap(_ recognizer: UITapGestureRecognizer) {
    //        let location = recognizer.location(in: sceneView)
    //        guard let query = sceneView.raycastQuery(from: location, allowing: .estimatedPlane, alignment: .any),
    //                let result = sceneView.session.raycast(query).first else { return }
    //        if canvasView.drawing != drawingFromHistory && !isCanvasBlank {
    //            withAnimation {
    //                drawingHistory.append(canvasView.drawing.dataRepresentation())
    //            }
    //        } else {
    //            drawingFromHistory = PKDrawing()
    //        }
    //        let drawing = drawingImage
    //        canvasView.drawing = PKDrawing()
    //        let baseNum = 0.6 / CGFloat(drawing.size.height)
    //        let planeNode = SCNNode(geometry: SCNPlane(width: CGFloat(drawing.size.width) * baseNum, height: CGFloat(drawing.size.height) * baseNum))
    //        planeNode.geometry!.firstMaterial?.diffuse.contents = drawing
    //        planeNode.transform = SCNMatrix4(result.worldTransform)
    //        planeNode.eulerAngles.x += -Float.pi / 2
    //        //        nodes.append(planeNode)
    //        sceneView.scene.rootNode.addChildNode(planeNode)
    //    }
    
    func removeDrawing() {
        if let tapSelectedNode = tapSelectedEntity {
//            tapSelectedNode.removeFromParentNode()
            tapSelectedNode.removeFromParent()
        }
        tapSelectedEntity = nil
    }
    
    func takePicture() {
        //        UIImageWriteToSavedPhotosAlbum(sceneView.snapshot(), nil, nil, nil)
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
    
    
    
//        func updateTexture() {
//            if !nodes.isEmpty {
//                nodes.forEach {
//                    $0.model?.materials = [createTexture(drawing: images[number]?.cgImage!)]
////                    $0.geometry?.firstMaterial?.diffuse.contents = images[number]
//                }
//            }
//        }
    
    private func createTexture(drawing: CGImage?) -> UnlitMaterial {
        let texture = try! TextureResource.generate(from: drawing!, options: .init(semantic: .hdrColor))
        var unlitMaterial = UnlitMaterial()
        unlitMaterial.color = .init(tint: .white, texture: .init(texture))
        unlitMaterial.blending = .transparent(opacity: .init(floatLiteral: 1))
        return unlitMaterial
    }
}

extension ViewModel: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        isCanvasBlank = canvasView.drawing.strokes.isEmpty
    }
}
