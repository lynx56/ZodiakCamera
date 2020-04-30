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
    private var panelView: PanelView!
    private let settings = UIButton(type: .custom)
    private let router: CameraViewControllerRouter
    private let ipCameraView = UIImageView()
    private var panelData: PanelData = PanelData(brightness: .initial, saturation: .initial, contrast: .initial, ir: false)
    private var model: CameraViewControllerModel
    
    init(model: CameraViewControllerModel,
         router: CameraViewControllerRouter) {
        self.router = router
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.panelView = PanelView(frame: .zero) { self.panelData }
        self.view.backgroundColor = .white
        self.setupLayout()
        self.panelView.eventHandler = self.handlePanelViewEvent
        self.joystickView.moveHandler = self.handleJoystickEvent
        model.imageProviderHandler = self.handleLiveImageEvent
        self.settings.addTarget(self, action: #selector(self.openSettings), for: .touchUpInside)
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tap)))
    }
    
    
    private func setupLayout() {
        ipCameraView.contentMode = model.contentMode
        view.addSubview(ipCameraView, constraints: .pin)
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
        settings.setImage(Images.settings.image, for: .normal)
        settings.tintColor = .white
        view.addSubview(settings, pairingTo: ipCameraView, constraints: [
            constraint(\.trailingAnchor, constant: -17),
            constraint(\.topAnchor, \.safeAreaLayoutGuide.topAnchor),
        ])
        settings.constrain(to:
            uconstraint(\.widthAnchor, constant: 34),
                           uconstraint(\.heightAnchor, constant: 34))
    }
    
    @objc func tap(_ sender: UITapGestureRecognizer) {
        showedSlider?.removeFromSuperview()
    }
    
    @objc func openSettings(_ sender: Any) {
        router.openSettings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        model.start()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        model.pause()
    }
    
    enum State {
        case error(Error)
        case editing
        case active(UIImage?)
        enum Error {
            case noConnection
            case unknown
            case internetNotAvailable
        }
    }
    
    func update(_ state: State) {
        switch state {
        case .active(let image):
            DispatchQueue.main.async {
                self.noConnection.removeFromSuperview()
                self.ipCameraView.image = image
                self.joystickView.isHidden = false
            }
        case .editing:
            joystickView.isHidden = true
        case .error(let error):
            switch error {
            case .noConnection:
                DispatchQueue.main.async {
                    self.view.insertSubview(self.noConnection, aboveSubview: self.ipCameraView, constraints: .pin)
                    self.joystickView.isHidden = true
                    self.noConnection.render(state: .init(title: L10n.Error.NoAccess.title,
                                                          description: L10n.Error.NoAccess.description,
                                                          iconName: Images.cameraWarning.name))
                }
            case .internetNotAvailable:
                DispatchQueue.main.async {
                    self.view.insertSubview(self.noConnection, aboveSubview: self.ipCameraView, constraints: .pin)
                    self.joystickView.isHidden = true
                    self.noConnection.render(state: .init(title: L10n.Error.NoInternetConnection.title,
                                                          description: L10n.Error.NoInternetConnection.description,
                                                          iconName: Images.cameraWarning.name))
                }
            case .unknown:
                break;
            }
        }
    }
    
    private lazy var noConnection = NoCameraAccessView()
    func handleLiveImageEvent(_ event: LiveImageProviderState) {
        switch event {
        case .active(let image):
            update(.active(image))
        case .error(let error):
            switch error {
            case .invalidHost:
                update(.error(.noConnection))
            case .temprorary: update(.error(.unknown))
            case .noInternetConnection:
                update(.error(.internetNotAvailable))
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
                                       model: .init(innerRadiusOffset: 30,
                                                    color: UIColor.black.withAlphaComponent(0.2),
                                                    tintColor: .white,
                                                    startImage: control.imageMin ?? UIImage.empty(),
                                                    endImage: control.imageMax ?? UIImage.empty(),
                                                    minValue: control.minValue,
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
                update(.editing)
            case .toggle(let toggle):
                toggle.newValueHandler(!toggle.currentValue())
            }
        case .changePanelData(let changes):
            let change = CameraViewController.convertPanelChanges(changes)
            
            model.changeSettings(change, resultHandler: { result in
                switch result {
                case .failure:
                    self.update(.error(.unknown))
                case .success(let settings): self.panelData = .init(brightness: settings.brightness,
                                                                    saturation: settings.saturation,
                                                                    contrast: settings.contrast,
                                                                    ir: settings.ir)
                }
            })
        }
    }
    
    static private func convertPanelChanges(_ change: PanelView.Event.PanelDataChanges) -> SettingsChange {
        switch  change {
        case .brightness(let value):
            return .brightness(value)
        case .contrast(let value):
            return .contrast(value)
        case .saturation(let value):
            return .saturation(value)
        case .ir(let value):
            return .ir(value)
        }
    }
    
    private func handleJoystickEvent(_ event: JoystickView.Event) {
        model.userManipulate(command: CameraViewController.converter(event)) { result in
            switch result {
            case .success:
                return
            case .failure:
                self.update(.error(.unknown))
            }
        }
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
}

struct PanelData {
    var brightness: LimitValue
    var saturation: LimitValue
    var contrast: LimitValue
    var ir: Bool
}

