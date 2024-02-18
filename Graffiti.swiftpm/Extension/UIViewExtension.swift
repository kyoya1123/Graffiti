//
//  UIViewExtension.swift
//  Graffiti
//
//  Created by Kyoya Yamaguchi on 2024/02/18.
//

import UIKit

extension UIView {
    func asImage() -> UIImage? {
        UIGraphicsImageRenderer(bounds: bounds).image { _ in
            drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
    }
}

