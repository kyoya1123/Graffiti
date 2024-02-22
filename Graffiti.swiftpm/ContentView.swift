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
    @State var onPlane: Bool = true
    
    var body: some View {
        ZStack {
            Group {
                RealityView(arView: $viewModel.arView)
//                ARSceneView(sceneView: $viewModel.sceneView)
                    .onTapGesture { location in
                        if viewModel.isRecording {
                            stopRecording()
                        } else {
                            viewModel.tap(location: location)
                        }
                    }
                Group {
                    ZStack {
                        CanvasView(viewModel: viewModel, canvasView: $viewModel.canvasView, isCanvasVisible: $viewModel.isCanvasVisible, toolPicker: $viewModel.toolPicker)
                        VStack {
                            Spacer()
                            HStack {
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
                                Spacer()
                            }
                        }
                        .padding(20)
                    }
                    .opacity(!viewModel.isCanvasVisible ? 0 : 1)
                    Image(uiImage: viewModel.drawingImage(canvasSize: true))
                        .resizable()
                        .opacity(viewModel.isCanvasVisible || viewModel.isCanvasBlank ? 0 : 1)
                        .onTapGesture { location in
                            viewModel.addDrawing(location: location, onPlane: onPlane)
                        }
                }
                .opacity(viewModel.isRecording ? 0 : 1)
            }
            .ignoresSafeArea()
            ZStack {
                VStack {
                    VStack {
                        Text("\(Image(systemName: "hand.tap")) Tap screen to place drawing")
                            .font(.system(size: 20, weight: .medium))
//                            .padding(20)
//                            .background(
//                                .ultraThinMaterial
//                            )
//                            .clipShape(Capsule())
                        HStack {
                            Picker("Place on", selection: $onPlane) {
                                Image(systemName: "square.filled.on.square").tag(true)
                                Image(systemName: "balloon").tag(false)
                            }
                            .pickerStyle(.segmented)
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .circular))
                            .frame(width: 300)
                        }
                    }
                    .padding(20)
                    .background(
                        .ultraThinMaterial
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .opacity(viewModel.isCanvasVisible || viewModel.isCanvasBlank ? 0 : 1)
                    Spacer()
                }
                VStack {
                    HStack {
                        Button {
                            viewModel.isCanvasVisible.toggle()
                            viewModel.updateToolPicker()
                            viewModel.tapSelectedEntity = nil
                        } label: {
                            Image(systemName: viewModel.isCanvasVisible ? "arkit" : "paintbrush")
                                .font(.system(size: 30))
                        }
                        .padding()
                        .background(
                            .ultraThinMaterial
                        )
                        .clipShape(.circle)
                        Spacer()
                        if viewModel.tapSelectedEntity != nil {
                            Button {
                                viewModel.removeDrawing()
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 30))
                                    .foregroundColor(.red)
                                    .padding()
                                    .background(
                                        .ultraThinMaterial
                                    )
                                    .clipShape(.circle)
                            }
                        }
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
                            viewModel.tapSelectedEntity = nil
                        } label: {
                            Image(systemName: "camera.shutter.button.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    .ultraThinMaterial
                                )
                                .environment(\.colorScheme, .dark)
                                .clipShape(.circle)
                        }
                        Button {
                            isShowingRecordAlert = true
                            viewModel.tapSelectedEntity = nil
                        } label: {
                            Image(systemName: "record.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    .ultraThinMaterial
                                )
                                .environment(\.colorScheme, .dark)
                                .clipShape(.circle)
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
                        viewModel.tapSelectedEntity = nil
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
