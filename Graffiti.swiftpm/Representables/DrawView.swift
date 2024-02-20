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
    @Binding var isCanvasVisible: Bool
    @Binding var toolPicker: PKToolPicker

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.delegate = viewModel
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.backgroundColor = isCanvasVisible ? .white : .clear
    }
}
