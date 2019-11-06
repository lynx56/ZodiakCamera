//
//  ArcSlider.swift
//  ZodiakCamera
//
//  Created by lynx on 18/10/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import UIKit

class ArcLayer: CALayer {
    private let shapelayer: CAShapeLayer
    private let scalelayer: CAShapeLayer
    
    var arc: Arc {
        didSet {
            setNeedsLayout()
        }
    }
    
    var scale: Arc {
        didSet {
            setNeedsLayout()
        }
    }
    
    init(arc: Arc, scale: Arc, color: UIColor, backgroundColor: UIColor) {
        shapelayer = CAShapeLayer()
        shapelayer.fillColor = backgroundColor.cgColor
        shapelayer.path = arc.path.cgPath
        
        scalelayer = CAShapeLayer()
        scalelayer.strokeColor = color.cgColor
        scalelayer.fillColor = nil
        scalelayer.path = scale.path.cgPath
        scalelayer.lineJoin = .round
        scalelayer.lineDashPattern = [2, 3] as [NSNumber]
        self.arc = arc
        self.scale = scale
        super.init()
        addSublayer(shapelayer)
        addSublayer(scalelayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSublayers() {
        shapelayer.path = arc.path.cgPath
        scalelayer.path = scale.path.cgPath
    }
}
