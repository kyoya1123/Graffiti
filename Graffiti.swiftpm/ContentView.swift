//
//  ContentView.swift
//  Graffiti
//
//  Created by Kyoya Yamaguchi on 2024/02/18.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        ZStack {
            Group {
                ARViewRepresentable(arView: $viewModel.arView)
                CanvasViewRepresentable(viewModel: viewModel, canvasView: $viewModel.canvasView, selectedColor: $viewModel.selectedColor, isCanvasVisible: $viewModel.isCanvasVisible)
            }
            .ignoresSafeArea()
            ZStack {
                VStack {
                    HStack {
                        HStack(spacing: 16) {
                            Button {
                                viewModel.addDrawing()
                            } label: {
                                Image(systemName: "plus.app.fill")
                                    .font(.system(size: 30))
                            }
                            .disabled(viewModel.isCanvasVisible || viewModel.isCanvasBlank)
                            
                            Button {
                                viewModel.isCanvasVisible.toggle()
                            } label: {
                                Image(systemName: viewModel.isCanvasVisible ? "eye" : "eye.slash")
                            }
                        }
                        .padding()
                        .background(
                            .ultraThinMaterial
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Spacer()
                    }
                    Spacer()
                }
                HStack {
                    Spacer()
                    Button {
                        viewModel.takePicture()
                    } label: {
                        Image(systemName: "camera.shutter.button.fill")
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                .ultraThinMaterial
                            )
                            .environment(\.colorScheme, .dark)
                            .clipShape(Circle())
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView(viewModel: .init())
}
