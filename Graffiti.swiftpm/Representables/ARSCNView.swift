//
//  File.swift
//  
//
//  Created by Kyoya Yamaguchi on 2024/02/20.
//

import SwiftUI
import ARKit

struct ARSceneView: UIViewRepresentable {
    
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


//        UIImageWriteToSavedPhotosAlbum(sceneView.snapshot(), nil, nil, nil)



//setupGesture()


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
//    @objc func tap(_ recognizer: UITapGestureRecognizer) {
//        let location = recognizer.location(in: sceneView)
//        let hitTestResults = sceneView.hitTest(location)
//        guard let node = hitTestResults.first?.node else { return }
//        tapSelectedNode = node
//    }

//MARK: ARSCNView
//func addDrawing(location: CGPoint, onPlane: Bool = true) {
//    if canvasView.drawing != drawingFromHistory {
//        withAnimation {
//            drawingHistory.append(canvasView.drawing.dataRepresentation())
//        }
//    } else {
//        drawingFromHistory = PKDrawing()
//    }
//        canvasView.drawing = PKDrawing()
//        let baseNum = 0.6 / CGFloat(drawing.size.height)
//        let planeNode = SCNNode(geometry: SCNPlane(width: CGFloat(drawing.size.width) * baseNum, height: CGFloat(drawing.size.height) * baseNum))
//        planeNode.geometry!.firstMaterial?.diffuse.contents = drawing
//        let targetPos = SCNVector3(0, 0, -0.72)
//        planeNode.position = sceneView.pointOfView!.convertPosition(targetPos, to: nil)
//        planeNode.rotation = sceneView.pointOfView!.rotation
//        //        nodes.append(planeNode)
//        sceneView.scene.rootNode.addChildNode(planeNode)
//}

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
