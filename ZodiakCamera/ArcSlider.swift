//
//  ArcSlider.swift
//  ZodiakCamera
//
//  Created by lynx on 18/10/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import UIKit

class CircleView: UIView {
    struct Settings {
        let color: UIColor
        let borderWidth: CGFloat
        let font: UIFont
        
        static let initial = Settings(color: .white, borderWidth: 0.5, font: .systemFont(ofSize: 12))
    }
    
    private lazy var label: UILabel = {
        let label = UILabel()
        addSubview(label)
        return label
    }()
    
    var text: String = "" {
        didSet {
            label.text = text
            label.sizeToFit()
        }
    }
    
    var settings: Settings = .initial {
        didSet {
            clipsToBounds = true
            layer.borderColor = settings.color.cgColor
            layer.borderWidth = settings.borderWidth
            label.textColor = settings.color
            label.font = settings.font
            setNeedsDisplay()
        }
    }
    
    override func layoutSubviews() {
        layer.cornerRadius = bounds.width/2
        label.center = .init(x: bounds.midX, y: bounds.midY)
    }
}

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


func centerArc(lineStartPoint: CGPoint, lineEndPoint: CGPoint, movingPoint: CGPoint) -> CGPoint? {
    let vector1 = CGVector(point1: movingPoint, point2: lineEndPoint)
    let vector2 = CGVector(point1: movingPoint, point2: lineStartPoint)
    let center1 = CGPoint(x: (movingPoint.x+lineEndPoint.x)/2,
                          y: (movingPoint.y+lineEndPoint.y)/2)
    
    let center2 = CGPoint(x: (movingPoint.x+lineStartPoint.x)/2,
                          y: (movingPoint.y+lineStartPoint.y)/2)
    
    
    let b1 = vector1.dx*center1.x + vector1.dy*center1.y
    let b2 = vector2.dx*center2.x + vector2.dy*center2.y
    
    let det = vector1.dx*vector2.dy - vector1.dy*vector2.dx
    
    if (abs(det) < CGFloat(1e-5)) {
        return nil
    }
    
    let centerX = vector2.dy/det*b1 - vector1.dy/det*b2
    let centerY = -vector2.dx/det*b1 + vector1.dx/det*b2
    
    return .init(x: centerX, y: centerY)
}

struct Arc {
    private(set) var radius: CGFloat
    private(set) var startAngle: CGFloat
    private(set) var endAngle: CGFloat
    private(set) var center: CGPoint
    private(set) var path: UIBezierPath?
    private(set) var lineStartPoint: CGPoint
    private(set) var lineEndPoint: CGPoint
    
    init(lineStartPoint: CGPoint,
         lineEndPoint: CGPoint,
         movingPoint: CGPoint) {
        self.lineStartPoint = lineStartPoint
        self.lineEndPoint = lineEndPoint
        center = centerArc(lineStartPoint: lineStartPoint,
                           lineEndPoint: lineEndPoint,
                           movingPoint: movingPoint)!
        
        radius = CGFloat(sqrt((movingPoint.x-center.x)*(movingPoint.x-center.x) + (movingPoint.y-center.y)*(movingPoint.y-center.y)))
        startAngle = CGFloat(atan2f(Float(lineStartPoint.y-center.y), Float(lineStartPoint.x-center.x)))
        let movingAngle = CGFloat(atan2f(Float(movingPoint.y-center.y), Float(movingPoint.x-center.x)))
        endAngle = CGFloat(atan2f(Float(lineEndPoint.y-center.y), Float(lineEndPoint.x-center.x)))
        
        
        let isClockwise =
            (endAngle>startAngle && startAngle<movingAngle && movingAngle<endAngle) ||
                (endAngle<startAngle && !(endAngle<movingAngle && movingAngle<startAngle))
        
        path = UIBezierPath(arcCenter: center,
                            radius: radius,
                            startAngle: startAngle,
                            endAngle: endAngle,
                            clockwise: isClockwise)
    }
    
    func point(tapPoint: CGPoint) -> (CGPoint, CGFloat)? {
        let dx = center.x - tapPoint.x
        let dy = center.y - tapPoint.y
        let angle = atan2(dy, dx) - CGFloat.pi
        
        var normalizedAngle = min(max(angle, startAngle), endAngle)
        if angle < -1.5*CGFloat.pi {
            normalizedAngle = endAngle
        }
        print(startAngle, endAngle, angle, normalizedAngle)
        
        let x = center.x + radius * cos(normalizedAngle)
        let y = center.y + radius * sin(normalizedAngle)
        return (CGPoint(x: x, y: y), normalizedAngle)
    }
    
    var L: CGFloat {
        let teta = endAngle - startAngle
        return radius * teta
    }
    
    func length(angle: CGFloat) -> CGFloat {
        return radius * abs(angle - startAngle)
    }
}

class ArcSlider: UIControl {
    private let circleView = CircleView()
    private let startLabel = UILabel()
    private let endLabel = UILabel()
    private var color = UIColor.gray
    private let lineWidth: CGFloat = 1
    private var insets: (CGFloat, CGFloat) = (10, 20)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    init(frame: CGRect,
         insets: (CGFloat, CGFloat) = (10, 20),
         color: UIColor,
         tintColor: UIColor) {
        super.init(frame: frame)
        self.insets = insets
        self.color = color
        self.tintColor = tintColor
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var scaleArc: Arc!
    func setup() {
        circleView.settings =  .init(color: .black,
                                     borderWidth: 1,
                                     font: .systemFont(ofSize: 8))
        
        let start = CGPoint(x: bounds.minX + lineWidth,
                            y: bounds.maxY - lineWidth)
        let end = CGPoint(x: bounds.maxX - lineWidth,
                          y: bounds.maxY - lineWidth)
        let top = CGPoint(x: (bounds.maxX - bounds.minX - 2*lineWidth)/2,
                          y: bounds.minY + lineWidth)
        
        let arc = Arc(lineStartPoint: start,
                      lineEndPoint: end,
                      movingPoint: top)
        guard let path = arc.path else { return }
        
        let shapelayer = CAShapeLayer()
        shapelayer.fillColor = color.cgColor
        shapelayer.path = path.cgPath
        shapelayer.lineWidth = lineWidth
        layer.addSublayer(shapelayer)
        let topScalePoint = top.applying(.init(translationX: insets.0/2, y: insets.1/2))
        
        scaleArc = Arc(lineStartPoint: start.applying(.init(translationX: insets.0, y: -insets.1)),
                       lineEndPoint: end.applying(.init(translationX: -insets.0, y: -insets.1)),
                       movingPoint: topScalePoint)
        guard let scalePath = scaleArc.path else { return }
        
        let scalelayer = CAShapeLayer()
        scalelayer.strokeColor = tintColor.cgColor
        scalelayer.fillColor = nil
        scalelayer.path = scalePath.cgPath
        scalelayer.lineWidth = lineWidth*2
        scalelayer.lineJoin = .round
        scalelayer.lineDashPattern = [2, 3] as [NSNumber]
        layer.addSublayer(scalelayer)
        self.clipsToBounds = true
        
        circleView.center = CGPoint(x: topScalePoint.x-10, y: topScalePoint.y-10)
        circleView.frame.size = .init(width: 20, height: 20)
        circleView.text = "125"
        circleView.backgroundColor = .white
        addSubview(circleView)
    }
    private var circleMoving = false
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if circleView.bounds.contains(touch.location(in: circleView)) {
            circleMoving = true
            UIView.animate(withDuration: 0.1) {
                self.circleView.transform = .init(scaleX: 1.4, y: 1.4)
            }
        }
    }
    
    private var maxValue = 255
    private var minValue = 0
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard circleMoving, let touch = touches.first else { return }
        let point = touch.location(in: self)
        guard let p = scaleArc.point(tapPoint: point) else {
            return
        }
        let v = Int(scaleArc.length(angle: p.1)/scaleArc.L * CGFloat (maxValue-minValue))
        circleView.text = "\(v)"
        circleView.center = CGPoint(x: p.0.x, y: p.0.y)
        sendActions(for: .valueChanged)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        circleMoving = false
        if circleView.transform != .identity {
            UIView.animate(withDuration: 0.1) {
                self.circleView.transform = .identity
            }
        }
    }
}
