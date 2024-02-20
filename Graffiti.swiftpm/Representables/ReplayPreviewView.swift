//
//  File.swift
//  
//
//  Created by Kyoya Yamaguchi on 2024/02/21.
//

import ReplayKit
import SwiftUI
import UIKit

struct ReplayPreviewView: UIViewControllerRepresentable {
    let replayPreviewViewController: RPPreviewViewController
    @Binding var isShow: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> RPPreviewViewController {
        replayPreviewViewController.previewControllerDelegate = context.coordinator
        replayPreviewViewController.modalPresentationStyle = .fullScreen
        
        return replayPreviewViewController
    }
    
    func updateUIViewController(_ uiViewController: RPPreviewViewController, context: Context) { }
    
    class Coordinator: NSObject, RPPreviewViewControllerDelegate {
        var parent: ReplayPreviewView
        
        init(_ parent: ReplayPreviewView) {
            self.parent = parent
        }
        
        func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
            withAnimation {
                parent.isShow = false
            }
        }
    }
}
