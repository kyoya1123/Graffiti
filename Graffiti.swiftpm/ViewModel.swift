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
    //    @Published var arView = ARView()
    @Published var sceneView = ARSCNView()
    @Published var canvasView = PKCanvasView()
    @Published var toolPicker = PKToolPicker()
    @Published var isCanvasVisible = false
    @Published var isCanvasBlank = true
    
    @Published var replayView: RPPreviewView!
    @Published var isRecording = false
    @Published var isShowPreviewVideo = false
    
    @Published var drawingHistory: [Data] = []
    @Published var drawingFromHistory = PKDrawing()
    
    var textureTimer: Timer!
    var nodes = [SCNNode]()
    var number = 0
    
    let images = [UIImage(named: "drawing0"), UIImage(named: "drawing1"), UIImage(named: "drawing2")]
    
    var drawingImage: UIImage {
        canvasView.drawing.image(from: canvasView.bounds, scale: 3)
    }
    
    override init() {
        super.init()
//        textureTimer = .scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
//            self.number = self.number == 2 ? 0 : self.number + 1
//            self.updateTexture()
//        }
        
        
        setupGesture()
        updateToolPicker()
    }
    
    func setupGesture() {
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch(_:)))
        sceneView.addGestureRecognizer(pinchGestureRecognizer)
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(drag(_:)))
        sceneView.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc func pinch(_ recognizer: UIPinchGestureRecognizer) {
        let tapRecognizer = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapRecognizer)
        guard let node = hitTestResults.first?.node, recognizer.state == .changed else { return }
        
        let pinchScaleX = Float(recognizer.scale) * node.scale.x
        let pinchScaleY =  Float(recognizer.scale) * node.scale.y
        node.scale = SCNVector3(x: Float(pinchScaleX), y: Float(pinchScaleY), z: 1)
        recognizer.scale = 1
    }
    
    var dragCoordinates = SCNVector3(0, 0, 0)
    var dragSelectedNode: SCNNode!
    
    @objc func drag(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            let location = recognizer.location(in: sceneView)
            guard let hitNodeResult = sceneView.hitTest(location, options: nil).first else { return }
            dragCoordinates = hitNodeResult.worldCoordinates
            dragSelectedNode = hitNodeResult.node
        case .changed:
            let hitNode = sceneView.hitTest(recognizer.location(in: sceneView), options: nil)
            if let nodeCoordinates = hitNode.first?.worldCoordinates {
                let action = SCNAction.moveBy(x: CGFloat(nodeCoordinates.x - dragCoordinates.x),
                                              y: CGFloat(nodeCoordinates.y - dragCoordinates.y),
                                              z: CGFloat(nodeCoordinates.z - dragCoordinates.z),
                                              duration: 0.0)
                dragSelectedNode.runAction(action)
                dragCoordinates = nodeCoordinates
            }
            recognizer.setTranslation(.zero, in: sceneView)
        default:
            break
        }
    }
    
    func addDrawing() {
        if canvasView.drawing != drawingFromHistory {
            withAnimation {
                drawingHistory.append(canvasView.drawing.dataRepresentation())
            }
        } else {
            drawingFromHistory = PKDrawing()
        }
        let drawing = drawingImage
        let baseNum = 0.6 / CGFloat(drawing.size.height)
        let planeNode = SCNNode(geometry: SCNPlane(width: CGFloat(drawing.size.width) * baseNum, height: CGFloat(drawing.size.height) * baseNum))
        planeNode.geometry!.firstMaterial?.diffuse.contents = drawing
        let targetPos = SCNVector3(0, 0, -0.72)
        planeNode.position = sceneView.pointOfView!.convertPosition(targetPos, to: nil)
        planeNode.rotation = sceneView.pointOfView!.rotation
        nodes.append(planeNode)
        sceneView.scene.rootNode.addChildNode(planeNode)
        canvasView.drawing = PKDrawing()
    }
    
//    func updateTexture() {
//        if !nodes.isEmpty {
//            nodes.forEach {
//                $0.geometry?.firstMaterial?.diffuse.contents = images[number]
//            }
//        }
//    }
    
    
    
    //            func addDrawing() {
    //                guard let drawing = canvasView.drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale).cgImage else { return }
    //                let baseNum: Float = 0.6 / Float(drawing.height)
    //                let modelEntity = ModelEntity(mesh: MeshResource.generatePlane(width: Float(drawing.width) * baseNum, height: Float(drawing.height) * baseNum))
    //                modelEntity.model?.materials = [createTexture(drawing: drawing)]
    //
    //                let cameraTransform: Transform = arView.cameraTransform
    //                let localCameraPosition: SIMD3<Float> = modelEntity.convert(position: cameraTransform.translation, from: nil)
    //                let cameraForwardVector: SIMD3<Float> = cameraTransform.matrix.forward
    //
    //                modelEntity.transform.translation = localCameraPosition + cameraForwardVector * 0.72
    //                modelEntity.transform.rotation = cameraTransform.rotation
    //
    //                let anchor = AnchorEntity(world: .zero)
    //                anchor.addChild(modelEntity)
    //                arView.scene.addAnchor(anchor)
    //                arView.installGestures([.scale], for: modelEntity)
    //                canvasView.drawing = PKDrawing()
    //            }
    //
    //            private func createTexture(drawing: CGImage?) -> UnlitMaterial {
    //                let texture = try! TextureResource.generate(from: drawing!, options: .init(semantic: .hdrColor))
    //                var unlitMaterial = UnlitMaterial()
    //                unlitMaterial.color = .init(tint: .white, texture: .init(texture))
    //                unlitMaterial.blending = .transparent(opacity: .init(floatLiteral: 1))
    //                return unlitMaterial
    //                let videoMaterial = VideoMaterial(avPlayer: AVPlayer.init())
    //            }
    
    func takePicture() {
        UIImageWriteToSavedPhotosAlbum(sceneView.snapshot(), nil, nil, nil)
        //            arView.snapshot(saveToHDR: false) { image in
        //                guard let image = image else { return }
        //                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        //            }
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
    
    func startRecord() {
        RPScreenRecorder.shared().isMicrophoneEnabled = true
        if !RPScreenRecorder.shared().isRecording {
            self.isRecording = true
            RPScreenRecorder.shared().startRecording { (error) in
                guard error == nil else {
                    print("There was an error starting the recording.")
                    return
                }
                print("Started Recording Successfully")
            }
        }
    }
}

extension ViewModel: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        isCanvasBlank = canvasView.drawing.strokes.isEmpty
    }
}

struct RPPreviewView: UIViewControllerRepresentable {
    let rpPreviewViewController: RPPreviewViewController
    @Binding var isShow: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> RPPreviewViewController {
        rpPreviewViewController.previewControllerDelegate = context.coordinator
        rpPreviewViewController.modalPresentationStyle = .fullScreen
        
        return rpPreviewViewController
    }
    
    func updateUIViewController(_ uiViewController: RPPreviewViewController, context: Context) { }
    
    class Coordinator: NSObject, RPPreviewViewControllerDelegate {
        var parent: RPPreviewView
        
        init(_ parent: RPPreviewView) {
            self.parent = parent
        }
        
        func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
            withAnimation {
                parent.isShow = false
            }
        }
    }
}
