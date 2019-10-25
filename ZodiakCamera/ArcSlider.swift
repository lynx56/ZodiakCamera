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
    private(set) var movingPoint: CGPoint
    
    init(lineStartPoint: CGPoint,
         lineEndPoint: CGPoint,
         movingPoint: CGPoint) {
        self.lineStartPoint = lineStartPoint
        self.lineEndPoint = lineEndPoint
        self.movingPoint = movingPoint
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
        
        let x = center.x + radius * cos(normalizedAngle)
        let y = center.y + radius * sin(normalizedAngle)
        return (CGPoint(x: x, y: y), normalizedAngle)
    }
    
    var L: CGFloat {
        let teta = endAngle - startAngle
        return radius * teta
    }
    
    func point(length: CGFloat) -> CGPoint {
        let angle = length/radius + startAngle
        var normalizedAngle = min(max(angle, startAngle), endAngle)
        
        if angle < -1.5*CGFloat.pi {
            normalizedAngle = endAngle
        }
        
        let x = center.x + radius * cos(normalizedAngle)
        let y = center.y + radius * sin(normalizedAngle)
        return .init(x: x, y: y)
    }
    
    func length(angle: CGFloat) -> CGFloat {
        return radius * abs(angle - startAngle)
    }
}

class ArcSlider: UIControl {
    private let circleView = CircleView()
    private let startImageView = UIImageView()
    private let endImageView = UIImageView()
    
    enum Constants {
        static let imageSize = CGSize(width: 15, height: 15)
        static let scaleImageOffset = CGFloat(8)
        static let lineWidth = CGFloat(1)
    }
    
    struct Settings {
        let scaleTopOffset: CGFloat
        let scaleSideOffset: CGFloat
        let color: UIColor
        let tintColor: UIColor
        let startImage: UIImage
        let endImage: UIImage
        let minValue: Int
        let maxValue: Int
        let currentValue: Int
        
        static var initial = Settings(scaleTopOffset: 20,
                                      scaleSideOffset: 10,
                                      color: .white,
                                      tintColor: .black,
                                      startImage: .empty(sized: .zero),
                                      endImage: .empty(sized: .zero),
                                      minValue: 0,
                                      maxValue: 255,
                                      currentValue: 128)
    }
    
    
    private let settings: Settings
    override init(frame: CGRect) {
        settings = .initial
        super.init(frame: frame)
        setup()
    }
    
    init(frame: CGRect,
         settings: Settings) {
        self.settings = settings
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var scaleArc: Arc!
    
    private lazy var mainArcLayer: CAShapeLayer? = {
        let lineWidth = Constants.lineWidth
        let start = CGPoint(x: self.bounds.minX + lineWidth,
                            y: self.bounds.maxY - lineWidth)
        let end = CGPoint(x: self.bounds.maxX - lineWidth,
                          y: self.bounds.maxY - lineWidth)
        let top = CGPoint(x: (self.bounds.maxX - self.bounds.minX - 2*lineWidth)/2,
                          y: self.bounds.minY + lineWidth)
        
        let arc = Arc(lineStartPoint: start,
                      lineEndPoint: end,
                      movingPoint: top)
        guard let path = arc.path else { return nil }
        
        let shapelayer = CAShapeLayer()
        shapelayer.fillColor = self.settings.color.cgColor
        shapelayer.path = path.cgPath
        shapelayer.lineWidth = lineWidth
        
        return shapelayer
    }()
    
    private lazy var scaleArcLayer: CAShapeLayer? = {
        let lineWidth = Constants.lineWidth
        let start = CGPoint(x: bounds.minX + lineWidth,
                            y: bounds.maxY - lineWidth)
        let end = CGPoint(x: bounds.maxX - lineWidth,
                          y: bounds.maxY - lineWidth)
        let top = CGPoint(x: (bounds.maxX - bounds.minX - 2*lineWidth)/2,
                          y: bounds.minY + lineWidth)
        
        let scaleStartPoint = start.applying(.init(translationX: settings.scaleSideOffset,
                                                   y: -settings.scaleTopOffset))
        let scaleEndPoint = end.applying(.init(translationX: -settings.scaleSideOffset,
                                               y: -settings.scaleTopOffset))
        let topScalePoint = top.applying(.init(translationX: settings.scaleSideOffset/2,
                                               y: settings.scaleTopOffset/2))
        
        startImageView.frame = .init(origin:  .init(x: scaleStartPoint.x - 15,
                                                    y: scaleStartPoint.y),
                                     size: .init(width: 15, height: 15))
        endImageView.frame = .init(origin: .init(x: scaleEndPoint.x, y: scaleEndPoint.y),
                                   size: .init(width: 15, height: 15))
        
        scaleArc = Arc(lineStartPoint: .init(x: startImageView.frame.maxX, y: startImageView.frame.minY - 8),
                       lineEndPoint: .init(x: endImageView.frame.minX, y: endImageView.frame.minY - 8),
                       movingPoint: .init(x: topScalePoint.x, y: topScalePoint.y - 4))
        
        startImageView.transform = .init(rotationAngle: scaleArc.startAngle + CGFloat.pi/2)
        endImageView.transform = .init(rotationAngle: scaleArc.endAngle + CGFloat.pi/2)
        
        guard let scalePath = scaleArc.path else { return nil }
        
        let scalelayer = CAShapeLayer()
        scalelayer.strokeColor = tintColor.cgColor
        scalelayer.fillColor = nil
        scalelayer.path = scalePath.cgPath
        scalelayer.lineWidth = lineWidth*2
        scalelayer.lineJoin = .round
        scalelayer.lineDashPattern = [2, 3] as [NSNumber]
        return scalelayer
    }()
    
    func setup() {
        self.tintColor = settings.tintColor
        circleView.settings =  .init(color: .black,
                                     borderWidth: 1,
                                     font: .systemFont(ofSize: 8))
        
        
        layer.addSublayer(mainArcLayer!)
        layer.addSublayer(scaleArcLayer!)
        
        startImageView.image = settings.startImage
        endImageView.image = settings.endImage
        addSubview(startImageView)
        addSubview(endImageView)
        
        self.clipsToBounds = true
        
        let traversedLength = CGFloat(settings.currentValue)/CGFloat(settings.maxValue-settings.minValue) * scaleArc.L
        
        let currentPoint = scaleArc.point(length: traversedLength)
        circleView.center = currentPoint.applying(.init(translationX: -10, y: -10))
        circleView.frame.size = .init(width: 20, height: 20)
        circleView.text = "\(settings.currentValue)"
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
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard circleMoving, let touch = touches.first else { return }
        let point = touch.location(in: self)
        guard let p = scaleArc.point(tapPoint: point) else {
            return
        }
        let traversedLength = scaleArc.length(angle: p.1)
        let v = Int(traversedLength/scaleArc.L * CGFloat(settings.maxValue-settings.minValue))
        
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



extension UIImage {
    static func empty(sized: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(sized)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}
