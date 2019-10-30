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
        view.addSubview(imageView, constraints: [
            constraint(\.leftAnchor),
            constraint(\.rightAnchor),
            constraint(\.topAnchor),
            constraint(\.bottomAnchor, constant: -60)
            ])
        
        view.addSubview(panelView, constraints: [
            constraint(\.leftAnchor),
            constraint(\.rightAnchor),
            constraint(\.bottomAnchor)
            ])
        
        panelView.constrainToView(imageView, constraints: [
            constraint(\.topAnchor, \.bottomAnchor),
            ])
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




protocol AuthService {
    func userAuth() -> (String, String)
}


protocol ZodiakProvider {
    func image() -> Data?
    func chageSettings(param: String, value: String)
    func userManipulate(command: String)
}


class Model: ZodiakProvider {
    private let authProvider: () -> (String, String)
    private var settings = Dictionary<Settings, Int>()
    private let host: URL
    
    init(authProvider: @escaping () -> (String, String),
         host: URL) {
        self.authProvider = authProvider
        self.host = host
        self.readsettings(handler: { (updatedSettings, error) in
            guard let settings = updatedSettings else { return }
            self.settings = settings
        })
    }
    
    enum Target {
        case image
        case settings
        case changeSettings
        case userManipulate
    }
    
    private func getUrl(with cgi: String) -> String {
        let (user, password) = authProvider()
        return "\(host.absoluteString)/\(cgi)?loginuse=\(user)&amp;loginpas=\(password)"
    }
    
    func image() -> Data? {
        return try? Data(contentsOf: URL(string: "http://188.242.14.235:81/snapshot.cgi?user=admin&pwd=123123")!)
    }
    
    func readsettings(handler: @escaping (Dictionary<Settings, Int>?, Error?) -> Void) {
        let url = getUrl(with: "get_camera_params.cgi")
        let task = URLSession.shared.downloadTask(with: URL(string: url)!) { (file, response, error) in
            if let file = file {
                do {
                    handler(try String(contentsOf: file).parseCGI(), nil)
                } catch {
                    handler(nil, error)
                }
            }
        }
        
        task.resume()
    }
    
    func chageSettings(param: String, value: String) {
        var cgi =  getUrl(with: "camera_control.cgi")
        cgi += "&param=\(param)&value=\(value)"
        cgi += "&\(Date().stamp())"
        
        let url = URL(string: cgi)!
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            print(error)
        }
        
        task.resume()
    }
    
    func userManipulate(command: String) {
        var cgi = getUrl(with: "decoder_control.cgi");
        cgi += "&command=\(command)"
        cgi += "&onestep=0"
        cgi += "&\(Date().stamp())"
        
        let url = URL(string: cgi)!
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            print(error)
        }
        
        task.resume()
    }
}

extension Model: PanelDataProvider {
    var brightness: Int {
        get {
            return settings[.Bright] ?? 0
        }
        set {
            chageSettings(param: Settings.Bright.rawValue, value: "\(newValue)")
        }
    }
    
    var saturation: Int {
        get {
            return settings[.Saturation] ?? 0
        }
        set {
            chageSettings(param: Settings.Saturation.rawValue, value: "\(newValue)")
        }
    }
    
    var contract: Int {
        get {
            return settings[.Contrast] ?? 0
        }
        set {
            chageSettings(param: Settings.Contrast.rawValue, value: "\(newValue)")
        }
    }
    
    var ir: Bool {
        get {
            return settings[.IRcut] == 1
        }
        set {
            chageSettings(param: Settings.IRcut.rawValue, value: "\(newValue == true ? 1 : 0)")
        }
    }
}

class MockModel: ZodiakProvider {
    private var settings = Dictionary<Settings, Int>()
    
    func image() -> Data? {
        return nil
    }
    func chageSettings(param: String, value: String) {
        print("chageSettings(param: \(param), value: \(value)")
    }
    
    func userManipulate(command: String) {
         print("userManipulate(command: \(command)")
    }
}

extension MockModel: PanelDataProvider {
    var brightness: Int {
        get {
            return settings[.Bright] ?? 0
        }
        set {
            settings[.Bright] = newValue
            chageSettings(param: Settings.Bright.rawValue, value: "\(newValue)")
        }
    }
    
    var saturation: Int {
        get {
            return settings[.Saturation] ?? 0
        }
        set {
            settings[.Saturation] = newValue
            chageSettings(param: Settings.Saturation.rawValue, value: "\(newValue)")
        }
    }
    
    var contract: Int {
        get {
            return settings[.Contrast] ?? 0
        }
        set {
            settings[.Contrast] = newValue
            chageSettings(param: Settings.Contrast.rawValue, value: "\(newValue)")
        }
    }
    
    var ir: Bool {
        get {
            return settings[.IRcut] == 1
        }
        set {
            settings[.IRcut] = newValue == true ? 1 : 0
            chageSettings(param: Settings.IRcut.rawValue, value: "\(newValue == true ? 1 : 0)")
        }
    }
}

protocol PanelDataProvider {
    var brightness: Int { get set }
    var saturation: Int { get set }
    var contract: Int { get set }
    var ir: Bool { get set }
}

class PanelView: UIView {
    private var dataProvider: PanelDataProvider
    private var items: [Item] = []
    
    init(frame: CGRect, provider: PanelDataProvider) {
        dataProvider = provider
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
        let brightness = ControlItem(image: #imageLiteral(resourceName: "brightnessMin"),
                                     imageMin: #imageLiteral(resourceName: "brightnessMin"),
                                     imageMax: #imageLiteral(resourceName: "brightnessMax"),
                                     maxValue: 255,
                                     minValue: 0,
                                     currentValue: dataProvider.brightness,
                                     newValueHandler: { self.dataProvider.brightness = $0 })
        let contrast = ControlItem(image: #imageLiteral(resourceName: "contrastMax"),
                                   imageMin: #imageLiteral(resourceName: "contrastMin"),
                                   imageMax: #imageLiteral(resourceName: "contrastMax"),
                                   maxValue: 255,
                                   minValue: 0,
                                   currentValue: dataProvider.contract,
                                   newValueHandler: { self.dataProvider.contract = $0 })
        let saturation = ControlItem(image: #imageLiteral(resourceName: "saturationMin"),
                                     imageMin: #imageLiteral(resourceName: "saturationMin"),
                                     imageMax: #imageLiteral(resourceName: "saturationMax"),
                                     maxValue: 255,
                                     minValue: 0,
                                     currentValue: dataProvider.saturation,
                                     newValueHandler: { self.dataProvider.saturation = $0 })
        let ir = ToggleItem(image: UIImage(named: "ir"),
                            currentValue: self.dataProvider.ir,
                            newValueHandler: { self.dataProvider.ir = $0 })
        items = [.control(brightness), .control(contrast), .control(saturation), .toggle(ir)]
        setup()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if slider?.frame.contains(point) == true {
            return slider
        } else {
            return stackView.hitTest(point, with: event)
        }
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
            stackView.addArrangedSubview(view)
        }
     
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        
        addSubview(stackView, constraints: [
            constraint(\.leftAnchor, constant: 16),
            constraint(\.rightAnchor, constant: -17),
            constraint(\.topAnchor, constant: 8),
            constraint(\.bottomAnchor, constant: -8),
            ])

    }
    var slider: ArcSlider?
    @objc func tap(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else { return }
        switch items[view.tag] {
        case .control(let control):
            let frame = CGRect.zero
            let slider = ArcSlider(frame: frame,
                                   settings: .init(innerRadiusOffset: 30,
                                                   color: UIColor.black.withAlphaComponent(0.2),
                                                   tintColor: tintColor,
                                                   startImage: control.imageMin ?? UIImage.empty(),
                                                   endImage: control.imageMax ?? UIImage.empty(),
                                                   minValue: control.minValue,
                                                   maxValue: control.maxValue,
                                                   currentValue: control.currentValue))
        
            slider.addTarget(self, action: #selector(changeItemValue), for: .valueChanged)
            slider.alpha = 0
            slider.isEnabled = true
            self.addSubview(slider, constraints: [
                    constraint(\.leftAnchor, constant: -15),
                    constraint(\.rightAnchor, constant: 15),
                    constraint(\.heightAnchor, constant: 120)
                ])
            slider.constrainToView(stackView, constraints: [
                constraint(\.bottomAnchor, \.topAnchor)
                ])
            UIView.animate(withDuration: 0.2) {
                slider.alpha = 1
                slider.layoutIfNeeded()
            }
            self.slider = slider
            
        case .toggle(let toggle):
            toggle.newValueHandler(!toggle.currentValue)
        }
    }
    
    @objc func changeItemValue(_ slider: ArcSlider) {
        guard let tag = slider.superview?.tag, case let .control(control) = items[tag] else { fatalError() }
        control.newValueHandler(slider.settings.currentValue)
    }
    
    struct ControlItem {
        var image: UIImage?
        var imageMin: UIImage?
        var imageMax: UIImage?
        var maxValue: Int
        var minValue: Int
        var currentValue: Int
        var newValueHandler: (Int)->Void
    }
    
    struct ToggleItem {
        var image: UIImage?
        var currentValue: Bool
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
