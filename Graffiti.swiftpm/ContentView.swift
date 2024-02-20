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
                ARSceneView(sceneView: $viewModel.sceneView)
                    .onTapGesture {
                        if viewModel.isRecording {
                            stopRecording()
                        }
                    }
                ZStack {
                    CanvasView(viewModel: viewModel, canvasView: $viewModel.canvasView, isCanvasVisible: $viewModel.isCanvasVisible, toolPicker: $viewModel.toolPicker)
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                viewModel.canvasView.drawing = PKDrawing()
                            } label: {
                                Image(systemName: "rays")
                                    .font(.system(size: 30))
                                    .foregroundColor(.red)
                                    .padding()
                                    .background(
                                        .ultraThinMaterial
                                    )
                                    .clipShape(.circle)
                            }
                            .opacity(viewModel.isCanvasBlank ? 0 : 1)
                        }
                    }
                    .padding(20)
                }
                .opacity(viewModel.isRecording || !viewModel.isCanvasVisible ? 0 : 1)
                    Image(uiImage: viewModel.drawingImage)
                        .resizable()
                        .opacity(viewModel.isCanvasVisible || viewModel.isCanvasBlank ? 0 : 1)
            }
            .ignoresSafeArea()
            ZStack {
                VStack {
                    HStack {
                        HStack(spacing: 16) {
                            Button {
                                viewModel.addDrawing()
                            } label: {
                                Image(systemName: "plus.viewfinder")
                                    .font(.system(size: 30))
                            }
                            .disabled(viewModel.isCanvasVisible || viewModel.isCanvasBlank)
                            
                            Button {
                                viewModel.isCanvasVisible.toggle()
                                viewModel.updateToolPicker()
                            } label: {
                                Image(systemName: viewModel.isCanvasVisible ? "arkit" : "paintbrush")//"scribble.variable")
                                    .font(.system(size: 30))
                            }
//                            Button("save") {
//                                UIImageWriteToSavedPhotosAlbum(UIImage(data: viewModel.drawingImage.pngData()!)!, nil, nil, nil)
//                                viewModel.canvasView.drawing = PKDrawing()
//                            }
                        }
                        .padding()
                        .background(
                            .ultraThinMaterial
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Spacer()
                    }
                    Spacer()
                    historyCarousel
                        .opacity(viewModel.isCanvasVisible || viewModel.drawingHistory.isEmpty ? 0 : 1)
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
                                viewModel.startRecording()
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
            if viewModel.showPreviewVideo {
                viewModel.replayView
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .transition(.move(edge: .bottom))
                    .edgesIgnoringSafeArea(.all)
                
            }
        }
    }
    
    var historyCarousel: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 8) {
                ForEach(viewModel.drawingHistory.reversed(), id: \.self) { drawingData in
                    let drawing = try! PKDrawing(data: drawingData)
                    Button {
                        viewModel.canvasView.drawing = drawing
                        viewModel.drawingFromHistory = drawing
                    } label: {
                        Image(uiImage: drawing.image(from: viewModel.canvasView.bounds, scale: 3))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .background(
                                .ultraThinMaterial
                                    .opacity(0.2)
                            )
                            .environment(\.colorScheme, .dark)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(8)
        }
        .background(
            .thinMaterial
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .frame(height: 100)
        .padding(.horizontal)
    }
    
    func stopRecording() {
        RPScreenRecorder.shared().stopRecording { preview, error in
            viewModel.isRecording = false
            guard let preview = preview else { return }
            viewModel.replayView = ReplayPreviewView(replayPreviewViewController: preview, isShow: $viewModel.showPreviewVideo)
            withAnimation {
                viewModel.showPreviewVideo = true
            }
        }
    }
}

#Preview {
    ContentView(viewModel: .init())
}
