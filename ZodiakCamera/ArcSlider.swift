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
        label.sizeToFit()
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

class ArcSlider: UIControl {
    private let circleView = CircleView()
    private let startImageView = UIImageView()
    private let endImageView = UIImageView()
    private(set) var currentValue = 0 {
        didSet {
            circleView.text = "\(currentValue)"
            valueChanged(currentValue)
        }
    }
    var valueChanged: (Int) -> Void = { _ in }
    enum Constants {
        static let imageSize = CGSize(width: 15, height: 15)
        static let scaleImageOffset = CGFloat(4)
        static let lineWidth = CGFloat(1)
        static let circleSize = CGSize(width: 20, height: 20)
    }
    
    struct Settings {
        let innerRadiusOffset: CGFloat
        let color: UIColor
        let tintColor: UIColor
        let startImage: UIImage
        let endImage: UIImage
        let minValue: Int
        let maxValue: Int
        let currentValue: Int
        
        static var initial = Settings(innerRadiusOffset: 20,
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
    private var mainArc: Arc!
    
    private var startPoint: CGPoint {
        return .init(x: self.bounds.minX,
                     y: self.bounds.maxY)
    }
    private var endPoint: CGPoint {
        return .init(x: self.bounds.maxX,
                            y: self.bounds.maxY)
    }
    private var topPoint: CGPoint {
        return .init(x: (self.bounds.maxX - self.bounds.minX)/2,
                     y: self.bounds.minY)
    }
    private var decorate: ArcLayer!
    
    func setup() {
        self.tintColor = settings.tintColor
        self.currentValue = settings.currentValue
        circleView.settings =  .init(color: .black,
                                     borderWidth: 1,
                                     font: .systemFont(ofSize: 8))
        mainArc = Arc(startPoint: startPoint,
                      endPoint: endPoint,
                      middlePoint: topPoint)
        
        scaleArc = Arc(arc: self.mainArc,
                       radius: self.mainArc.radius - settings.innerRadiusOffset)
        
        decorate = ArcLayer(arc: mainArc,
                            scale: scaleArc,
                            color: settings.tintColor,
                            backgroundColor: settings.color)
        
        self.layer.addSublayer(decorate)
        startImageView.image = settings.startImage
        endImageView.image = settings.endImage
        
        addSubview(startImageView)
        addSubview(endImageView)
        
        self.clipsToBounds = true
        circleView.backgroundColor = .white
        addSubview(circleView)
    }
    
    private var cachedBounds: CGRect = .zero
    override func layoutSubviews() {
        if cachedBounds == bounds {
            return
        }
            
        mainArc = Arc(startPoint: startPoint,
                      endPoint: endPoint,
                      middlePoint: topPoint)
        
        scaleArc = Arc(arc: mainArc,
                       radius: mainArc.radius - settings.innerRadiusOffset)
        
        decorate.arc = mainArc
        decorate.scale = scaleArc
        
        let scaleStartPoint = scaleArc.point(for: scaleArc.startAngle)
        let scaleEndPoint = scaleArc.point(for: scaleArc.endAngle)
        
        startImageView.transform = .identity
        endImageView.transform = .identity
        startImageView.frame = .init(origin:  .init(x: scaleStartPoint.x - Constants.imageSize.width - Constants.scaleImageOffset,
                                                    y: scaleStartPoint.y + Constants.scaleImageOffset),
                                     size: Constants.imageSize)
        endImageView.frame = .init(origin: .init(x: scaleEndPoint.x + Constants.scaleImageOffset, y: scaleEndPoint.y + Constants.scaleImageOffset),
                                   size: Constants.imageSize)
        
        startImageView.transform = .init(rotationAngle: scaleArc.startAngle + .pi/2)
        endImageView.transform = .init(rotationAngle: scaleArc.endAngle + .pi/2)
        
        let traversedLength = CGFloat(currentValue)/CGFloat(settings.maxValue-settings.minValue) * scaleArc.length()
        let currentPoint = scaleArc.point(for: scaleArc.angle(for: traversedLength))
        circleView.center = currentPoint
        circleView.bounds.size = Constants.circleSize
        circleView.setNeedsLayout()
        cachedBounds = self.bounds
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
        let angle = scaleArc.angle(for: point)
        let traversedLength = scaleArc.length(angle: angle)
        let currentPoint = scaleArc.point(for: scaleArc.angle(for: traversedLength))
        circleView.center = currentPoint
        currentValue = Int(traversedLength/scaleArc.length() * CGFloat(settings.maxValue-settings.minValue))
       
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


extension UIImage {
    static func empty(sized: CGSize = .zero) -> UIImage {
        UIGraphicsBeginImageContext(sized)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}
