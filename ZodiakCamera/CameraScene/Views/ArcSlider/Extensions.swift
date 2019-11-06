//
//  ArcSlider.swift
//  ZodiakCamera
//
//  Created by lynx on 18/10/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import UIKit

extension CGVector {
    init(point1: CGPoint, point2: CGPoint) {
        var vector = CGVector(dx: point1.x-point2.x,
                              dy: point1.y-point2.y)
        let distance = CGFloat(sqrt(vector.dx*vector.dx + vector.dy*vector.dy))
        vector.dx = vector.dx/distance
        vector.dy = vector.dy/distance
        self = vector
    }
}

extension UIImage {
    static func empty(sized: CGSize = .zero) -> UIImage {
        UIGraphicsBeginImageContext(sized)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}
