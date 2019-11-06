//
//  ArcSlider.swift
//  ZodiakCamera
//
//  Created by lynx on 18/10/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import UIKit

struct Arc {
    typealias Center = CGPoint
    private(set) var startAngle: CGFloat
    private(set) var endAngle: CGFloat
    private(set) var path: UIBezierPath
    private(set) var radius: CGFloat
    private let center: Center
    private (set) var isClockwise: Bool
    
    init(startPoint: CGPoint,
         endPoint: CGPoint,
         middlePoint: CGPoint) {
        self.center = .init(from: startPoint, to: endPoint, through: middlePoint)
        self.radius = center.distance(to: middlePoint)
        let startAngle = center.angle(to: startPoint)
        let middleAngle = center.angle(to: middlePoint)
        let endAngle = center.angle(to: endPoint)
        let isClockwise = (endAngle > startAngle && startAngle < middleAngle && middleAngle < endAngle) ||
            (endAngle < startAngle && !(endAngle < middleAngle && middleAngle < startAngle))
        
        self.path = UIBezierPath(arcCenter: center,
                                 radius: radius,
                                 startAngle: startAngle,
                                 endAngle: endAngle,
                                 clockwise: isClockwise)
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.isClockwise = isClockwise
    }
    
    init(arc: Arc,
         radius: CGFloat) {
        self.startAngle = arc.startAngle + 0.3
        self.endAngle = arc.endAngle - 0.3
        self.radius = radius
        self.center = arc.center
        self.isClockwise = arc.isClockwise
        self.path = UIBezierPath(arcCenter: center,
                                 radius: radius,
                                 startAngle: startAngle,
                                 endAngle: endAngle,
                                 clockwise: isClockwise)
    }
    
    func angle(for point: CGPoint) -> CGFloat {
        var angle = center.angle(to: point)
        
        if startAngle < 0, endAngle < 0, angle > 0 {
            angle *= -1
        }
        let normalizedAngle = min(max(angle, startAngle), endAngle)
        
        return normalizedAngle
    }
    
    func point(for angle: CGFloat) -> CGPoint {
        var mutatingAngle = angle
        if startAngle < 0, endAngle < 0, angle > 0 {
            mutatingAngle *= -1
        }
        
        let normalizedAngle = min(max(mutatingAngle, startAngle), endAngle)
        
        let x = center.x + radius * cos(normalizedAngle)
        let y = center.y + radius * sin(normalizedAngle)
        return CGPoint(x: x, y: y)
    }
    
    func angle(for traversedLength: CGFloat) -> CGFloat {
        return traversedLength/radius + startAngle
    }
    
    func length(angle: CGFloat? = nil) -> CGFloat {
        if let angle = angle {
            return radius * abs(angle - startAngle)
        }
        
        return radius * (endAngle - startAngle)
    }
}

extension Arc.Center {
    func distance(to point: CGPoint) -> CGFloat {
        return CGFloat(sqrt((self.x - point.x)*(self.x - point.x) + (self.y - point.y)*(self.y - point.y)))
    }
    
    func angle(to point: CGPoint) -> CGFloat {
        return CGFloat(atan2f(Float(point.y - self.y), Float(point.x - self.x)))
    }
    
    init(from startPoint: CGPoint, to endPoint: CGPoint, through middlePoint: CGPoint) {
        let vector1 = CGVector(point1: middlePoint, point2: endPoint)
        let vector2 = CGVector(point1: middlePoint, point2: startPoint)
        let center1 = CGPoint(x: (middlePoint.x+endPoint.x)/2,
                              y: (middlePoint.y+endPoint.y)/2)
        
        let center2 = CGPoint(x: (middlePoint.x+startPoint.x)/2,
                              y: (middlePoint.y+startPoint.y)/2)
        
        let b1 = vector1.dx*center1.x + vector1.dy*center1.y
        let b2 = vector2.dx*center2.x + vector2.dy*center2.y
        
        let det = vector1.dx*vector2.dy - vector1.dy*vector2.dx
        
        if (abs(det) < CGFloat(1e-5)) {
            self = startPoint
        }
        
        let centerX = vector2.dy/det*b1 - vector1.dy/det*b2
        let centerY = -vector2.dx/det*b1 + vector1.dx/det*b2
        
        self = .init(x: centerX, y: centerY)
    }
}
