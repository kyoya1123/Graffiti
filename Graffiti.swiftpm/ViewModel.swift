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
    @Published var sceneView = ARSCNView()
    
    @Published var canvasView = PKCanvasView()
    @Published var toolPicker = PKToolPicker()
    @Published var isCanvasVisible = true
    @Published var isCanvasBlank = true
    @Published var drawingHistory: [Data] = []
    var drawingFromHistory = PKDrawing()
    
    @Published var replayView: ReplayPreviewView!
    @Published var isRecording = false
    @Published var showPreviewVideo = false
    
    //    var textureTimer: Timer!
    //    var nodes = [SCNNode]()
    //    var number = 0
    //    let images = [UIImage(named: "drawing0"), UIImage(named: "drawing1"), UIImage(named: "drawing2")]
    
    var drawingImage: UIImage {
        canvasView.drawing.image(from: canvasView.bounds, scale: 3)
    }
    
    override init() {
        super.init()
        //        textureTimer = .scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
        //            self.number = self.number == 2 ? 0 : self.number + 1
        //            self.updateTexture()
        //        }
        RPScreenRecorder.shared().isMicrophoneEnabled = true
        setupGesture()
        updateToolPicker()
    }
    
    func setupGesture() {
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch(_:)))
        sceneView.addGestureRecognizer(pinchGestureRecognizer)
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(drag(_:)))
        sceneView.addGestureRecognizer(panGestureRecognizer)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func pinch(_ recognizer: UIPinchGestureRecognizer) {
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation)
        guard let node = hitTestResults.first?.node, recognizer.state == .changed else { return }
        
        let scalex = Float(recognizer.scale) * node.scale.x
        let scaley =  Float(recognizer.scale) * node.scale.y
        node.scale = SCNVector3(x: Float(scalex), y: Float(scaley), z: 1)
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
    
    @Published var tapSelectedNode: SCNNode?
    
    @objc func tap(_ recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(location)
        guard let node = hitTestResults.first?.node else { return }
        tapSelectedNode = node
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
        canvasView.drawing = PKDrawing()
        let baseNum = 0.6 / CGFloat(drawing.size.height)
        let planeNode = SCNNode(geometry: SCNPlane(width: CGFloat(drawing.size.width) * baseNum, height: CGFloat(drawing.size.height) * baseNum))
        planeNode.geometry!.firstMaterial?.diffuse.contents = drawing
        let targetPos = SCNVector3(0, 0, -0.72)
        planeNode.position = sceneView.pointOfView!.convertPosition(targetPos, to: nil)
        planeNode.rotation = sceneView.pointOfView!.rotation
        //        nodes.append(planeNode)
        sceneView.scene.rootNode.addChildNode(planeNode)
    }
    
    func removeDrawing() {
        if let tapSelectedNode = tapSelectedNode {
            tapSelectedNode.removeFromParentNode()
        }
        tapSelectedNode = nil
    }
    
    func takePicture() {
        UIImageWriteToSavedPhotosAlbum(sceneView.snapshot(), nil, nil, nil)
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
}

extension ViewModel: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        isCanvasBlank = canvasView.drawing.strokes.isEmpty
    }
}
