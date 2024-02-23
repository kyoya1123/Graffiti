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
                RealityView(arView: $viewModel.arView)
                    .onTapGesture { location in
                        viewModel.isRecording ? stopRecording() : viewModel.tap(location: location)
                    }
                Group {
                    canvasView
                        .opacity(!viewModel.isCanvasVisible ? 0 : 1)
                    Image(uiImage: viewModel.drawingImage(canvasSize: true, drawing: viewModel.animationDrawings.isEmpty ? nil : viewModel.isCanvasBlank ? viewModel.animationDrawings.last! : nil))
                        .resizable()
                        .opacity(viewModel.isCanvasVisible || (viewModel.isCanvasBlank && viewModel.animationDrawings.isEmpty) ? 0 : 1)
                        .onTapGesture { location in
                            viewModel.addDrawing(location: location, onPlane: viewModel.onPlane)
                        }
                }
                .opacity(viewModel.isRecording ? 0 : 1)
            }
            .ignoresSafeArea()
            ZStack {
                addView
                    .opacity(viewModel.isCanvasVisible || (viewModel.isCanvasBlank && viewModel.animationDrawings.isEmpty) ? 0 : 1)
                VStack {
                    topButtons
                    Spacer()
                    historyCarousel
                        .opacity(viewModel.isCanvasVisible || viewModel.drawingHistory.isEmpty ? 0 : 1)
                }
                captureButtons
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
    
    var canvasView: some View {
        ZStack {
            CanvasView(viewModel: viewModel, canvasView: $viewModel.canvasView, isCanvasVisible: $viewModel.isCanvasVisible, toolPicker: $viewModel.toolPicker)
            HStack {
                Spacer()
                Button {
                    viewModel.animationDrawings.append(viewModel.canvasView.drawing)
                    viewModel.canvasView.drawing = PKDrawing()
                } label: {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 30))
                        .foregroundColor(.accentColor)
                        .padding()
                        .background(
                            .ultraThinMaterial
                        )
                        .clipShape(.circle)
                }
                .opacity(viewModel.isCanvasBlank ? 0 : 1)
            }
            .padding(20)
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
    }
    
    var addView: some View {
        VStack {
            VStack {
                Text("\(Image(systemName: "hand.tap")) Tap screen to place drawing")
                    .font(.system(size: 20, weight: .medium))
                HStack {
                    Picker("Place on", selection: $viewModel.onPlane) {
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
            Spacer()
        }
    }
    
    var topButtons: some View {
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
    }
    
    var captureButtons: some View {
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
    }
    
    var historyCarousel: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 8) {
                ForEach(viewModel.drawingHistory.reversed(), id: \.self) { drawingDataArray in
                    let drawing = try! PKDrawing(data: drawingDataArray.last!)
                    Button {
                        viewModel.canvasView.drawing = drawing
                        viewModel.drawingFromHistory = drawing
                        viewModel.animationDrawings = drawingDataArray.map { try! PKDrawing(data: $0) }.dropLast()
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
                            .overlay {
                                if drawingDataArray.count > 1 {
                                    VStack {
                                        HStack {
                                            Spacer()
                                            Image(systemName: "film.circle.fill")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 25, height: 25)
                                                .padding(4)
                                                .foregroundStyle(.white)
                                        }
                                        Spacer()
                                    }
                                }
                            }
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
