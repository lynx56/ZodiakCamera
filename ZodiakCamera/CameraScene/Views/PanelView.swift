//
//  PanelView.swift
//  ZodiakCamera
//
//  Created by lynx on 06/11/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import UIKit

class PanelView: UIView {

    private var dataProvider: PanelDataProvider
    private var items: [Item] = []
    
    enum Event {
        case itemSelected(Item)
    }
    
    var eventHandler: (Event) -> Void = { _ in }
    
    init(frame: CGRect, provider: PanelDataProvider) {
        dataProvider = provider
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
        let brightness = ControlItem(image: #imageLiteral(resourceName: "brightnessMin"),
                                     imageMin: #imageLiteral(resourceName: "brightnessMin"),
                                     imageMax: #imageLiteral(resourceName: "brightnessMax"),
                                     maxValue: self.dataProvider.brightness.maxValue,
                                     minValue: self.dataProvider.brightness.minValue,
                                     currentValue: { self.dataProvider.brightness.currentValue },
                                     newValueHandler: { self.dataProvider.brightness.currentValue = $0 })
        let contrast = ControlItem(image: #imageLiteral(resourceName: "contrastMax"),
                                   imageMin: #imageLiteral(resourceName: "contrastMin"),
                                   imageMax: #imageLiteral(resourceName: "contrastMax"),
                                   maxValue: self.dataProvider.brightness.maxValue,
                                   minValue: self.dataProvider.brightness.minValue,
                                   currentValue: { self.dataProvider.contrast.currentValue },
                                   newValueHandler: { self.dataProvider.contrast.currentValue = $0 })
        let saturation = ControlItem(image: #imageLiteral(resourceName: "saturationMin"),
                                     imageMin: #imageLiteral(resourceName: "saturationMin"),
                                     imageMax: #imageLiteral(resourceName: "saturationMax"),
                                     maxValue: self.dataProvider.brightness.maxValue,
                                     minValue: self.dataProvider.brightness.minValue,
                                     currentValue: { self.dataProvider.saturation.currentValue },
                                     newValueHandler: { self.dataProvider.saturation.currentValue = $0 })
        let ir = ToggleItem(image: UIImage(named: "ir"),
                            currentValue: { self.dataProvider.ir },
                            newValueHandler: { self.dataProvider.ir = $0 })
        items = [.control(brightness), .control(contrast), .control(saturation), .toggle(ir)]
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
            view.constrain(to:
                constraint(\.widthAnchor, constant: 44),
                constraint(\.heightAnchor, constant: 44))
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
        var currentValue: ()->Bool
        var newValueHandler: (Bool)->Void
    }
    
    enum Item {
        case control(ControlItem)
        case toggle(ToggleItem)
        func image() -> UIImage? {
            switch self {
            case .control(let control):
                return control.image
            case .toggle(let toggle):
                return toggle.image
            }
        }
    }
    
    class PanelIconView: UIView {
        private let imageView = UIImageView()
        var image: UIImage? {
            didSet {
                imageView.image = image
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
