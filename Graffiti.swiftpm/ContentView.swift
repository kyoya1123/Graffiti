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
            Color.white
            if !viewModel.animationDrawings.isEmpty {
                Image(uiImage: viewModel.drawingImage(canvasSize: true, drawing: viewModel.animationDrawings.last!))
                    .resizable()
                    .opacity(0.6)
            }
            CanvasView(viewModel: viewModel, canvasView: $viewModel.canvasView, isCanvasVisible: $viewModel.isCanvasVisible, toolPicker: $viewModel.toolPicker)
            HStack {
                Spacer()
                VStack {
                    frameList
                        .opacity(viewModel.animationDrawings.isEmpty ? 0 : 1)
                    Button {
                        withAnimation {
                            viewModel.animationDrawings.append(viewModel.canvasView.drawing)
                        }
                        viewModel.canvasView.drawing = PKDrawing()
                    } label: {
                        Image("film.badge.plus")
                            .font(.system(size: 30))
                            .foregroundColor(.accentColor)
                            .padding()
                            .background(
                                .ultraThinMaterial
                            )
                            .baselineOffset(-3)
                            .clipShape(.circle)
                    }
                    .opacity(viewModel.isCanvasBlank ? 0 : 1)
                }
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
                            .foregroundColor(viewModel.isCanvasBlank ? Color(uiColor: .lightGray) : .red)
                            .padding()
                            .background(
                                .ultraThinMaterial
                            )
                            .clipShape(.circle)
                    }
                    .disabled(viewModel.isCanvasBlank)
                    Spacer()
                }
            }
            .padding(20)
        }
    }
    
    @State var isShowingDeleteAlert = false
    
    var frameList: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 8) {
                Button {
                    isShowingDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                        .padding()
                }
                .alert("Delete All", isPresented: $isShowingDeleteAlert) {
                    Button("Delete", role: .destructive) {
                        withAnimation {
                            viewModel.animationDrawings = []
                        }
                    }
                    Button("Cancel", role: .cancel) {
                        isShowingDeleteAlert = false
                    }
                } message: {
                    Text("Are you sure you want to delete all drawings?")
                }
                ForEach(viewModel.animationDrawings, id: \.self) { drawing in
                    Menu {
                        HStack {
                            Button {
                                viewModel.canvasView.drawing = drawing
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                                    .foregroundStyle(Color.accentColor)
                            }
                            Button(role: .destructive) {
                                withAnimation {
                                    viewModel.animationDrawings.remove(element: drawing)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(uiImage: viewModel.drawingImage(canvasSize: true, drawing: drawing))
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
        .frame(width: 100)
        .padding(.vertical)
    }
    
    var addView: some View {
        VStack {
            VStack {
                Text("\(Image(systemName: "hand.tap")) Tap \(viewModel.onPlane ? "Wall or Plane" : "Screen") to Place Drawing")
                    .font(.system(size: 20, weight: .medium))
                Picker("Place on", selection: $viewModel.onPlane) {
                    Image(systemName: "square.filled.on.square").tag(true)
                    Image(systemName: "balloon").tag(false)
                }
                .pickerStyle(.segmented)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .circular))
                .frame(width: 300)
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
    
    @State var isShowingRecordAlert: Bool = false
    
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
                ForEach(Array(viewModel.drawingHistory.reversed()), id: \.self) { drawingArray in
                    let drawing = drawingArray.last!
                    Button {
                        viewModel.canvasView.drawing = drawing
                        viewModel.drawingFromHistory = drawing
                        viewModel.animationDrawings = drawingArray.dropLast()
                        viewModel.tapSelectedEntity = nil
                    } label: {
                        Image(uiImage: viewModel.drawingImage(canvasSize: true, drawing: drawing))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .background(
                                .ultraThinMaterial
                                    .opacity(0.2)
                            )
                            .environment(\.colorScheme, .dark)
                            .overlay {
                                if drawingArray.count > 1 {
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

extension PKDrawing: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(dataRepresentation())
    }
    
    public var id: UUID { UUID() }
}


extension Array where Element: Equatable {
    mutating func remove(element: Element) {
        if let index = firstIndex(of: element) {
            remove(at: index)
        }
    }
}
