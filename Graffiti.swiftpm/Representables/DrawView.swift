//
//  DrawView.swift
//  Graffiti
//
//  Created by Kyoya Yamaguchi on 2024/02/18.
//

import SwiftUI
import UIKit
import PencilKit

struct CanvasViewRepresentable: UIViewRepresentable {
    
    @ObservedObject var viewModel: ViewModel
    
    @Binding var canvasView: PKCanvasView
    @Binding var selectedColor: Color
    @Binding var isCanvasVisible: Bool
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .pencilOnly
        canvasView.delegate = viewModel
        return canvasView
    } 
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.tool = PKInkingTool(.fountainPen, color: UIColor(selectedColor))
        uiView.backgroundColor = isCanvasVisible ? .white : .clear
    }
}
