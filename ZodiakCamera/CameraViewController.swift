//
//  ViewController.swift
//  ZodiakCamera
//
//  Created by lynx on 14/10/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import UIKit

class CameraViewController: UIViewController {
    private let joystickView = JoystickView()
    private let panelView: PanelView
    private let imageView = UIImageView()
    private let zodiak: ZodiakProvider
    
    init(zodiak: ZodiakProvider, dataProvider: PanelDataProvider) {
        self.zodiak = zodiak
        self.panelView = PanelView(frame: .zero, provider: dataProvider)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    private func setup() {
        view.backgroundColor = .white
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView, constraints: [
            constraint(\.leadingAnchor),
            constraint(\.trailingAnchor),
            constraint(\.topAnchor),
            constraint(\.bottomAnchor, constant: -100)
        ])
        
        view.addSubview(panelView, constraints: [
            constraint(\.leftAnchor),
            constraint(\.rightAnchor),
            constraint(\.bottomAnchor)
        ])
        
        panelView.constrainToView(imageView, constraints: [
            constraint(\.topAnchor, \.bottomAnchor),
        ])
        
        view.addSubview(joystickView)
        joystickView.constrainToView(imageView, constraints: .pin)
        joystickView.backgroundColor = .clear
        panelView.eventHandler = handlePanelViewEvent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        createDisplayLink()
        
        joystickView.moveHandler = {
            self.zodiak.userManipulate(command: "\(moveToCameraCommandConverter(direction: $0))")
        }
    }
    
    func createDisplayLink() {
        let displaylink = CADisplayLink(target: self,
                                        selector: #selector(step))
        
        displaylink.add(to: .current,
                        forMode: .default)
    }
    
    @objc func step(displaylink: CADisplayLink) {
        guard let data = zodiak.image() else { return }
        imageView.image = UIImage(data: data)
    }

    private var showedSlider: ArcSlider?
    func handlePanelViewEvent(_ event: PanelView.Event) {
        switch event {
        case .itemSelected(let item):
            showedSlider?.removeFromSuperview()
            switch item {
                          case .control(let control):
                              let slider = ArcSlider(frame: .zero,
                                                     settings: .init(innerRadiusOffset: 30,
                                                                     color: UIColor.black.withAlphaComponent(0.2),
                                                                     tintColor: .white,
                                                                     startImage: control.imageMin ?? UIImage.empty(),
                                                                     endImage: control.imageMax ?? UIImage.empty(),
                                                                     minValue: control.minValue,
                                                                     maxValue: control.maxValue,
                                                                     currentValue: control.currentValue()))
                          
                            slider.valueChanged = control.newValueHandler
                              slider.alpha = 0
                              slider.isEnabled = true
                              view.addSubview(slider, constraints: [
                                      constraint(\.leftAnchor, constant: -15),
                                      constraint(\.rightAnchor, constant: 15),
                                  ])
                              slider.constrainToView(panelView, constraints: [
                                constraint(\.bottomAnchor, \.topAnchor)
                              ])
                              slider.constrain(to: constraint(\.heightAnchor, constant: 120))
                              slider.layoutIfNeeded()
                              
                              UIView.animate(withDuration: 0.2) {
                                  slider.alpha = 1
                              }
                              self.showedSlider = slider
                          case .toggle(let toggle):
                            toggle.newValueHandler(!toggle.currentValue())
                          }
        
        }
    }
}


extension Date {
    func stamp() -> Int64! {
        return Int64(self.timeIntervalSince1970 * 1000) + Int64(arc4random())
    }
}


extension String {
    func parseCGI()->Dictionary<Settings, Int> {
        var result = Dictionary<Settings, Int>()
        let components =
            self
                .removingAllWhitespaces()
                .replacingOccurrences(of: "var", with: "")
                .components(separatedBy: ";")
                .filter { !$0.isEmpty }
        for component in components {
            let keyValue = component.components(separatedBy: "=")
            guard keyValue.count == 2 else { fatalError("Format is not supported") }
            if let key = keyValue.first?.removingAllWhitespaces(),
                let value = keyValue.last?.removingAllWhitespaces() {
                result[Settings(rawValue: key)!] = Int(value)!
            }
        }
        
        return result
    }
    
    func removingAllWhitespaces() -> String {
        return removingCharacters(from: .whitespacesAndNewlines)
    }
    
    func removingCharacters(from set: CharacterSet) -> String {
        var newString = self
        newString.removeAll { char -> Bool in
            guard let scalar = char.unicodeScalars.first else { return false }
            return set.contains(scalar)
        }
        return newString
    }
}

enum Settings: String {
    case Resolution = "resolution"
    case Mode = "mode"
    case OSDEnable = "OSDEnable"
    case ResolutionSub = "resolutionsub"
    case SubEncFramerate = "sub_enc_framerate"
    case Bright = "vbright"
    case Saturation = "vsaturation"
    case bitrate = "enc_bitrate"
    case Hue = "vhue"
    case Flip = "flip"
    case IRcut = "ircut"
    case Speed = "speed"
    case Framerate = "enc_framerate"
    case Contrast = "vcontrast"
}

func moveToCameraCommandConverter(direction: JoystickView.Event) -> Int {
    switch direction {
    case .stop: return 1
    case .move(let direction):
        switch direction {
        case .down: return 2
        case .downleft: return 92
        case .downright: return 93
        case .left: return 4
        case .right: return 6
        case .up: return 0
        case .upleft: return 90
        case .upright: return 91
        }
    }
}

func settingsConverter(settings: Settings, value: String) -> (String, String) {
    switch settings {
    case .IRcut:
        return ("14", value)
    case .Bright:
        return ("1", value)
    case .Contrast:
        return ("2", value)
    case .Saturation:
        return ("8", value)
    default:
        return ("", "")
    }
}

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
                                     maxValue: 255,
                                     minValue: 0,
                                     currentValue: { self.dataProvider.brightness },
                                     newValueHandler: { self.dataProvider.brightness = $0 })
        let contrast = ControlItem(image: #imageLiteral(resourceName: "contrastMax"),
                                   imageMin: #imageLiteral(resourceName: "contrastMin"),
                                   imageMax: #imageLiteral(resourceName: "contrastMax"),
                                   maxValue: 255,
                                   minValue: 0,
                                   currentValue: { self.dataProvider.contract },
                                   newValueHandler: { self.dataProvider.contract = $0 })
        let saturation = ControlItem(image: #imageLiteral(resourceName: "saturationMin"),
                                     imageMin: #imageLiteral(resourceName: "saturationMin"),
                                     imageMax: #imageLiteral(resourceName: "saturationMax"),
                                     maxValue: 255,
                                     minValue: 0,
                                     currentValue: { self.dataProvider.saturation },
                                     newValueHandler: { self.dataProvider.saturation = $0 })
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
