//
//  ContentView.swift
//  Graffiti
//
//  Created by Kyoya Yamaguchi on 2024/02/18.
//

import SwiftUI
import ReplayKit
import PencilKit

struct ContentView: View {
    
    @ObservedObject var viewModel: ViewModel
    
    @State var isShowingRecordAlert: Bool = false
    
    var body: some View {
        ZStack {
            Group {
//                ARViewRepresentable(arView: $viewModel.arView)
                ARSCNViewRepresentable(sceneView: $viewModel.sceneView)
                    .onTapGesture {
                        if viewModel.isRecording {
                            stopRecord()
                        }
                    }
                CanvasViewRepresentable(viewModel: viewModel, canvasView: $viewModel.canvasView, selectedTool: $viewModel.selectedTool, isCanvasVisible: $viewModel.isCanvasVisible, toolPicker: $viewModel.toolPicker)
                    .opacity(viewModel.isRecording || !viewModel.isCanvasVisible ? 0 : 1)
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
                                viewModel.toolPicker.setVisible(viewModel.isCanvasVisible, forFirstResponder: viewModel.canvasView)
                                if viewModel.isCanvasVisible {
                                    DispatchQueue.main.async {
                                        viewModel.toolPicker.addObserver(viewModel.canvasView)
                                        viewModel.canvasView.becomeFirstResponder()
                                    }
                                }
                            } label: {
                                Image(systemName: viewModel.isCanvasVisible ? "eye" : "eye.slash")
                            }
                            Button("save") {
                                UIImageWriteToSavedPhotosAlbum(UIImage(data: viewModel.canvasView.drawing.image(from: viewModel.canvasView.bounds, scale: 3).pngData()!)!, nil, nil, nil)
                                viewModel.canvasView.drawing = PKDrawing()
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
                    ColorPicker("", selection: $viewModel.selectedColor, supportsOpacity: false)
                        .onChange(of: viewModel.selectedColor) {
                            viewModel.selectedTool = PKInkingTool(.fountainPen, color: UIColor(viewModel.selectedColor))
                        }
                }
                HStack {
                    Spacer()
                    VStack {
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
                        Button {
                            isShowingRecordAlert = true
                        } label: {
                            Image(systemName: "record.circle.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    .ultraThinMaterial
                                )
                                .environment(\.colorScheme, .dark)
                                .clipShape(Circle())
                        }
                        .alert("Start Recording", isPresented: $isShowingRecordAlert) {
                            Button("OK") {
                                viewModel.startRecord()
                            }
                        } message: {
                            Text("Tap screen to stop recording")
                        }
                    }
                }
                .opacity(viewModel.isCanvasVisible ? 0 : 1)
            }
            .padding()
            .opacity(viewModel.isRecording ? 0 : 1)
            if viewModel.isShowPreviewVideo {
                viewModel.replayView
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .transition(.move(edge: .bottom))
                    .edgesIgnoringSafeArea(.all)
                
            }
        }
    }
    
    func stopRecord() {
        RPScreenRecorder.shared().stopRecording { preview, error in
            viewModel.isRecording = false
            
            guard let preview = preview else { return }
            viewModel.replayView = RPPreviewView(rpPreviewViewController: preview, isShow: $viewModel.isShowPreviewVideo)
            withAnimation {
                viewModel.isShowPreviewVideo = true
            }
        }
    }
}

#Preview {
    ContentView(viewModel: .init())
}
