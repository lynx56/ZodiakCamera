//
//  ViewController.swift
//  ZodiakCamera
//
//  Created by lynx on 14/10/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import UIKit

protocol CameraViewControllerRouter {
    func openSettings()
}

class CameraViewController: UIViewController {
    private let joystickView = JoystickView()
    private let panelView: PanelView
    private let router: CameraViewControllerRouter
    private let zodiak: ZodiakProvider
    private let ipCameraView: UIView
    
    init(factory: CameraViewControllerFactory,
         router: CameraViewControllerRouter) {
        self.router = router
        zodiak = factory.createCameraProvider()
        ipCameraView = factory.createCameraView()
        panelView = PanelView(frame: .zero, provider: factory.createPanelDataProvider())
        
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
        view.addSubview(ipCameraView, constraints: .pinWithoutPaddings)
        
        view.addSubview(panelView, constraints: [
            constraint(\.leftAnchor),
            constraint(\.rightAnchor),
            constraint(\.bottomAnchor)
        ])
        
        panelView.constrainToView(ipCameraView, constraints: [
            constraint(\.topAnchor, \.bottomAnchor, constant: -84),
        ])
        
        view.addSubview(joystickView)
        joystickView.constrainToView(ipCameraView, constraints: [
            constraint(\.leadingAnchor),
            constraint(\.trailingAnchor),
            constraint(\.topAnchor)
        ])
        joystickView.constrainToView(panelView, constraints: [
            constraint(\.bottomAnchor, \.topAnchor)
        ])
        joystickView.backgroundColor = .clear
        panelView.eventHandler = handlePanelViewEvent
        
        let settings = UIButton(type: .custom)
        settings.setImage(Images.settings.image, for: .normal)
        settings.tintColor = .white
        view.addSubview(settings, pairingTo: ipCameraView, constraints: [
            constraint(\.trailingAnchor, constant: -17),
            constraint(\.topAnchor, \.safeAreaLayoutGuide.topAnchor),
        ])
        settings.constrain(to:
            uconstraint(\.widthAnchor, constant: 34),
                           uconstraint(\.heightAnchor, constant: 34))
        settings.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap)))
        joystickView.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        joystickView.moveHandler = {[weak self] in
            self?.zodiak.userManipulate(CameraViewController.converter($0))
        }
    }
    
    @objc func tap(_ sender: UITapGestureRecognizer) {
        showedSlider?.removeFromSuperview()
    }
    
    @objc func openSettings(_ sender: Any) {
        router.openSettings()
    }
    
    private static var converter:(JoystickView.Event) -> UserManipulation {
        return {
            switch $0 {
            case .move(let moveDirection):
                switch moveDirection {
                case .down: return .move(.down)
                case .up: return .move(.up)
                case .left: return .move(.left)
                case .right: return .move(.right)
                case .downleft: return .move(.downleft)
                case .downright: return .move(.downright)
                case .upleft: return .move(.upleft)
                case .upright: return .move(.upright)
                }
            case .stop: return .stop
            case .start: return .start
            }
        }
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
                                                       //TODO:
                                        maxValue: control.maxValue != 0 ? control.maxValue : 255,
                                        currentValue: control.currentValue()))
                
                slider.valueChanged = control.newValueHandler
                slider.isEnabled = true
                view.addSubview(slider, constraints: [
                    constraint(\.leftAnchor, constant: -15),
                    constraint(\.rightAnchor, constant: 15),
                ])
                slider.constrainToView(panelView, constraints: [
                    constraint(\.bottomAnchor, \.topAnchor)
                ])
                slider.constrain(to: uconstraint(\.heightAnchor, constant: 120))
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


protocol CameraViewControllerFactory {
    func createCameraView() -> UIView
    func createCameraProvider() -> ZodiakProvider
    func createPanelDataProvider() -> PanelDataProvider
}


class DefaultCameraViewFactory: CameraViewControllerFactory {
    private let cameraSettings: CameraSettingsProvider
    private let mode: Mode
    private let zodiak: Model
    
    enum Mode {
        case snapshot
        case stream
    }
    
    func createCameraView() -> UIView {
        switch mode {
        case .snapshot:
            let zodiak = Model(cameraSettings: cameraSettings)
            return IPCameraViewBySnapshots(frame: .zero,
                                           imageProvider: zodiak.image)
        case .stream:
            return IPCameraView(frame: .zero, urlProvider: { URL(string: "http://\(self.cameraSettings.host):\(self.cameraSettings.port)/videostream.cgi?loginuse=\(self.cameraSettings.login)&loginpas=\(self.cameraSettings.password)")!
            })
        }
    }
    
    func createCameraProvider() -> ZodiakProvider {
        return zodiak
    }
    
    func createPanelDataProvider() -> PanelDataProvider {
        return zodiak
    }
    
    init(cameraSettings: CameraSettingsProvider, mode: Mode) {
        self.cameraSettings = cameraSettings
        self.mode = mode
        self.zodiak = Model(cameraSettings: cameraSettings)
    }
}


struct MockFactory: CameraViewControllerFactory {
    private let model: MockModel
    
    init() {
        model = MockModel()
    }
    
    func createPanelDataProvider() -> PanelDataProvider {
        return model
    }
    
    func createCameraView() -> UIView {
        return NoConnectionView()
    }
    
    func createCameraProvider() -> ZodiakProvider {
        return model
    }
}


extension UIMotionEffect {
    static func parallax(withMinDistance min: CGFloat = -30, andMaxDistance max: CGFloat = 30) -> UIMotionEffect {
        let xMotion = UIInterpolatingMotionEffect(keyPath: "layer.transform.translation.x",
                                                  type: .tiltAlongHorizontalAxis)
        xMotion.minimumRelativeValue = min
        xMotion.maximumRelativeValue = max
        
        let yMotion = UIInterpolatingMotionEffect(keyPath: "layer.transform.translation.y",
                                                  type: .tiltAlongVerticalAxis)
        yMotion.minimumRelativeValue = min
        yMotion.maximumRelativeValue = max
        
        let motionEffectsGroup = UIMotionEffectGroup()
        motionEffectsGroup.motionEffects = [xMotion, yMotion]
        return motionEffectsGroup
    }
    
    static func verticalRotation(minAngle min: CGFloat = 315, maxAngle max: CGFloat = 45) -> UIMotionEffect {
        var identity = CATransform3DIdentity
        identity.m34 = -1/500
        
        let minimum = CATransform3DRotate(identity, min * .pi / 180, 1, 0, 0)
        let maximum = CATransform3DRotate(identity, max * .pi / 180, 1, 0, 0)
        
        let effect = UIInterpolatingMotionEffect(keyPath: "layer.transform", type: .tiltAlongVerticalAxis)
        effect.minimumRelativeValue = minimum
        effect.maximumRelativeValue = maximum
        
        return effect
    }
}


