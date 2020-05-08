//
//  File.swift
//  ZodiakCamera
//
//  Created by Holyberry on 08.05.2020.
//  Copyright © 2020 gulnaz. All rights reserved.
//

import UIKit

class SegmentedArcSlider: UIControl {
    private let circleView = CircleView()
    private var segmentView = [Segment: UIView]()
    
    private(set) var current: Segment? {
        didSet {
            guard let current = current else { return }
            valueChanged(current)
        }
    }
    
    var valueChanged: (Segment) -> Void = { _ in }
    enum Constants {
        static let imageSize = CGSize(width: 15, height: 15)
        static let scaleImageOffset = CGFloat(4)
        static let lineWidth = CGFloat(1)
        static let circleSize = CGSize(width: 24, height: 24)
    }
    
    struct Segment: Hashable {
        var title: String?
        var value: Int
    }
    
    struct ViewModel {
        let innerRadiusOffset: CGFloat
        let color: UIColor
        let tintColor: UIColor
        let segments: [Segment]
        let currentIndex: Int?
        
        static var initial = ViewModel(innerRadiusOffset: 20,
                                       color: .white,
                                       tintColor: .black,
                                       segments: [],
                                       currentIndex: nil)
    }
    
    
    private let model: ViewModel
    override init(frame: CGRect) {
        self.model = .initial
        super.init(frame: frame)
        setup()
    }
    
    init(frame: CGRect,
         model: ViewModel) {
        self.model = model
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
    private var pointsLayer: PointsLayer!
    func setup() {
        current = model.segments[model.currentIndex ?? 0]
        self.tintColor = model.tintColor
        circleView.settings =  .init(color: .black, font: .systemFont(ofSize: 8))
        mainArc = Arc(startPoint: startPoint,
                      endPoint: endPoint,
                      middlePoint: topPoint)
        
        scaleArc = Arc(arc: self.mainArc,
                       radius: self.mainArc.radius - model.innerRadiusOffset)
        
        decorate = ArcLayer(arc: mainArc,
                            scale: scaleArc,
                            color: model.tintColor,
                            backgroundColor: model.color,
                            isDashed: false)
        
        let partLength = scaleArc.length()/CGFloat(model.segments.count - 1)
        var points: [CGPoint] = []
        for (index, segment) in model.segments.enumerated() {
            let point = scaleArc.point(forAngle: scaleArc.angle(forLength: partLength*CGFloat(index)))
            points.append(point)
            
            let roundedView = RoundedView()
            roundedView.cornerRadius = 5
            roundedView.text = segment.title ?? ""
            segmentView[segment] = roundedView
            addSubview(roundedView)
        }
        
        pointsLayer = PointsLayer(points: points, color: model.tintColor)
        self.layer.addSublayer(decorate)
        self.layer.addSublayer(pointsLayer)
        
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
                       radius: mainArc.radius - model.innerRadiusOffset)
        
        decorate.arc = mainArc
        decorate.scale = scaleArc
        
        let partLength = scaleArc.length()/CGFloat(model.segments.count - 1)
       
        var points: [CGPoint] = []
        for (index, segment) in model.segments.enumerated() {
            let point = scaleArc.point(forAngle: scaleArc.angle(forLength: partLength*CGFloat(index)))
            points.append(point)
            
            guard let view = segmentView[segment] else { continue }
            view.center = point.applying(.init(translationX: 0, y: 20))
            view.bounds.size = view.intrinsicContentSize
        }
        
        pointsLayer.points = points
        
        let rangeValues = model.segments.count
        guard rangeValues != 0 else {
            cachedBounds = .zero
            return
        }
        
        let currentPoint = points[current!.value]
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
                self.circleView.transform = .init(scaleX: 1.2, y: 1.2)
            }
        }
    }
    
    private func pointOnScale(forTouch touch: UITouch) -> CGPoint {
        let point = touch.location(in: self)
        let angle = scaleArc.angle(forPoint: point)
        let traversedLength = scaleArc.length(angle: angle)
        return scaleArc.point(forAngle: scaleArc.angle(forLength: traversedLength))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard circleMoving, let touch = touches.first else { return }
        circleView.center = pointOnScale(forTouch: touch)
        sendActions(for: .valueChanged)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let currentPoint = pointOnScale(forTouch: touch)
        let closestMeaningPoint = self.pointsLayer.points.enumerated().min(by: { $0.element.distance(to: currentPoint) < $1.element.distance(to: currentPoint) })!
        
        circleMoving = false
        UIView.animate(withDuration: 0.1) {
            self.circleView.center = closestMeaningPoint.element
            self.current = self.model.segments[closestMeaningPoint.offset]
            self.circleView.transform = .identity
        }
    }
}
