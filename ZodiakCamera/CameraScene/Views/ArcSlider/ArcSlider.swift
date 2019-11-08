//
//  ArcSlider.swift
//  ZodiakCamera
//
//  Created by lynx on 18/10/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import UIKit

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
        static let circleSize = CGSize(width: 24, height: 24)
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
        circleView.settings =  .init(color: .black, font: .systemFont(ofSize: 8))
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
        
        let rangeValues = settings.maxValue-settings.minValue
        guard rangeValues != 0 else {
            cachedBounds = .zero
            return
        }
        
        let traversedLength = CGFloat(currentValue)/CGFloat(rangeValues) * scaleArc.length()
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
                self.circleView.transform = .init(scaleX: 1.8, y: 1.8)
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
