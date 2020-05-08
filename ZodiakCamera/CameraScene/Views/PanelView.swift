//
//  PanelView.swift
//  ZodiakCamera
//
//  Created by lynx on 06/11/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import UIKit

class PanelView: UIView {
    private var items: [Item] = []
    
    enum Event {
        case itemSelected(Item)
        case changePanelData(PanelDataChanges)
        
        enum PanelDataChanges {
            case brightness(Int)
            case contrast(Int)
            case saturation(Int)
            case ir(Bool)
            case resolution(CameraResolution)
        }
    }
    
    var eventHandler: (Event) -> Void = { _ in }
    
    init(frame: CGRect, provider: @escaping ()->PanelData) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
        let brightness = ControlItem(image: #imageLiteral(resourceName: "brightnessMin"),
                                     imageMin: #imageLiteral(resourceName: "brightnessMin"),
                                     imageMax: #imageLiteral(resourceName: "brightnessMax"),
                                     maxValue: provider().brightness.maxValue,
                                     minValue: provider().brightness.minValue,
                                     currentValue: { provider().brightness.currentValue },
                                     newValueHandler: {
                                        self.eventHandler(.changePanelData(.brightness($0)))})
        let contrast = ControlItem(image: #imageLiteral(resourceName: "contrastMax"),
                                   imageMin: #imageLiteral(resourceName: "contrastMin"),
                                   imageMax: #imageLiteral(resourceName: "contrastMax"),
                                   maxValue: provider().brightness.maxValue,
                                   minValue: provider().brightness.minValue,
                                   currentValue: { provider().contrast.currentValue },
                                   newValueHandler: {
                                    self.eventHandler(.changePanelData(.contrast($0)))})
        let saturation = ControlItem(image: #imageLiteral(resourceName: "saturationMin"),
                                     imageMin: #imageLiteral(resourceName: "saturationMin"),
                                     imageMax: #imageLiteral(resourceName: "saturationMax"),
                                     maxValue: provider().brightness.maxValue,
                                     minValue: provider().brightness.minValue,
                                     currentValue: { provider().saturation.currentValue },
                                      newValueHandler: {
                                        self.eventHandler(.changePanelData(.saturation($0)))})
        let ir = ToggleItem(image: #imageLiteral(resourceName: "irOff"),
                            imageSelected: #imageLiteral(resourceName: "irOn"),
                            currentValue: { provider().ir },
                            newValueHandler: {
                                self.eventHandler(.changePanelData(.ir($0)))
                                self.setNeedsLayout()
        })
        
        let sliderResolution = SegmentItem(image: Images.monitor.image,
                                           currentValue: { (provider().resolution.text, provider().resolution.rawValue) },
                                           newValueHandler: { text, index  in
                                            self.eventHandler(.changePanelData(.resolution(CameraResolution(rawValue: index)!)))
                                            self.setNeedsLayout() })
        items = [.control(brightness),
                 .control(contrast),
                 .control(saturation),
                 .segment(sliderResolution),
                 .toggle(ir)]
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let stackView = UIStackView()
    func setup() {
        for (index, item) in items.enumerated() {
            let view = PanelIconView(image: item.image())
            view.tag = index
            view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap)))
            view.constrainToView(view, constraints: [
                constraint(\.widthAnchor, \.heightAnchor)
            ])
            stackView.addArrangedSubview(view)
        }
        
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        
        addSubview(stackView, constraints: [
            constraint(\.leftAnchor, constant: 16),
            constraint(\.rightAnchor, constant: -17),
            constraint(\.topAnchor, constant: 8),
            constraint(\.bottomAnchor, constraintRelation: .lessThanOrEqual, constant: -36),
            ])
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        insertSubview(blurView, at: 0, constraints: .pin)
        
        tintColor = UIColor.white.withAlphaComponent(0.7)
        //backgroundColor = UIColor.black

    }
    var slider: ArcSlider?
    @objc func tap(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else { return }
        eventHandler(.itemSelected(items[view.tag]))
    }
    
    override func layoutSubviews() {
        stackView.subviews.forEach {
            if let panelIconView = $0 as? PanelIconView {
                panelIconView.image = items[panelIconView.tag].image()
            }
        }
    }
    
    struct ControlItem {
        var image: UIImage?
        var imageMin: UIImage?
        var imageMax: UIImage?
        var maxValue: Int
        var minValue: Int
        var currentValue: ()->Int
        var newValueHandler: (Int)->Void
    }
    
    struct ToggleItem {
        var image: UIImage?
        var imageSelected: UIImage?
        var currentValue: ()->Bool
        var newValueHandler: (Bool)->Void
    }
    
    struct SegmentItem {
        var image: UIImage?
        var currentValue: ()->(String, Int)
        var newValueHandler: (String, Int)->Void
    }
    
    enum Item {
        case control(ControlItem)
        case toggle(ToggleItem)
        case segment(SegmentItem)
        func image() -> UIImage? {
            switch self {
            case .control(let control):
                return control.image
            case .toggle(let toggle):
                return toggle.currentValue() == false ? toggle.image : toggle.imageSelected
            case .segment(let segment):
                return segment.image
            }
        }
    }
    
    class PanelIconView: UIView {
        private let imageView = UIImageView()
        var image: UIImage? {
            didSet {
                DispatchQueue.main.async {
                    self.imageView.image = self.image
                }
            }
        }
      
        init(image: UIImage?) {
            self.image = image
            super.init(frame: .zero)
            imageView.contentMode = .scaleAspectFit
            imageView.image = image
            addSubview(imageView, constraints: [
                constraint(\.leftAnchor, constant: 10),
                constraint(\.rightAnchor, constant: -10),
                constraint(\.topAnchor, constant: 10),
                constraint(\.bottomAnchor, constant: -10),
                ])
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}


extension String {
    func image(size: CGSize? = nil,
               attributes: [NSAttributedString.Key : Any]? = nil) -> UIImage? {
        let size = size ?? (self as NSString).size(withAttributes: attributes)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        NSString(string: self).draw(in: .init(origin: .zero, size: size), withAttributes: attributes)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
