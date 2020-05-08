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
    
    init(arc: Arc, scale: Arc, color: UIColor, backgroundColor: UIColor, isDashed: Bool = true) {
        shapelayer = CAShapeLayer()
        shapelayer.fillColor = backgroundColor.cgColor
        shapelayer.path = arc.path.cgPath
        
        scalelayer = CAShapeLayer()
        scalelayer.strokeColor = color.cgColor
        scalelayer.fillColor = nil
        scalelayer.path = scale.path.cgPath
        scalelayer.lineJoin = .round
        if isDashed {
            scalelayer.lineDashPattern = [2, 3] as [NSNumber]
        }
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

class PointsLayer: CALayer {
    private let shapelayer: CAShapeLayer
    var points: [CGPoint] = [] {
        didSet {
            setNeedsLayout()
        }
    }
    
    init(points: [CGPoint], color: UIColor) {
        shapelayer = CAShapeLayer()
        shapelayer.fillColor = color.cgColor
        super.init()
             
        let bezierPath = UIBezierPath()
        points.forEach {
            bezierPath.move(to: $0)
            bezierPath.addArc(withCenter: $0, radius: 5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        }
        
        shapelayer.path = bezierPath.cgPath
        addSublayer(shapelayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSublayers() {
        let bezierPath = UIBezierPath()
        points.forEach {
            bezierPath.move(to: $0)
            bezierPath.addArc(withCenter: $0, radius: 5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        }
        shapelayer.path = bezierPath.cgPath
    }
}
