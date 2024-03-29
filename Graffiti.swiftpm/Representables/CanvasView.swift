//
//  DrawView.swift
//  Graffiti
//
//  Created by Kyoya Yamaguchi on 2024/02/18.
//

import SwiftUI
import UIKit
import PencilKit

struct CanvasView: UIViewRepresentable {

    @ObservedObject var viewModel: ViewModel

    @Binding var canvasView: PKCanvasView
    @Binding var isCanvasVisible: Bool
    @Binding var toolPicker: PKToolPicker

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .default
        canvasView.delegate = viewModel
        canvasView.backgroundColor = .clear
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
