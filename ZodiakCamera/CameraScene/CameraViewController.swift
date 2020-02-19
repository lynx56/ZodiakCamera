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
    private let zodiak: ZodiakProvider
    private var imageProvider: LiveImageProvider
    private let ipCameraView = UIImageView()
    private var panelData: PanelData = PanelData(brightness: .initial, saturation: .initial, contrast: .initial, ir: false)
    
    init(factory: CameraViewControllerFactory,
         router: CameraViewControllerRouter) {
        self.router = router
        zodiak = factory.createCameraProvider()
        imageProvider = factory.createImageProvider()
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
        self.imageProvider.stateHandler = self.handleLiveImageEvent
        self.settings.addTarget(self, action: #selector(self.openSettings), for: .touchUpInside)
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tap)))
    }
    
    
    private func setupLayout() {
        self.imageProvider.configure(for: ipCameraView)
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
        imageProvider.start()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        imageProvider.stop()
    }
    
    private lazy var noConnection = NoConnectionView()
    func handleLiveImageEvent(_ event: LiveImageProviderState) {
        switch event {
        case .active(let image):
            DispatchQueue.main.async {
                self.noConnection.removeFromSuperview()
                self.ipCameraView.image = image
            }
        case .error(let error):
            DispatchQueue.main.async {
                self.view.insertSubview(self.noConnection, aboveSubview: self.ipCameraView, constraints: .pin)
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
        case .changePanelData(let changes):
            let (param, val) = CameraViewController.convertPanelChanges(changes)
            
            zodiak.chageSettings(param:  param, value: val, handler: { result in
                switch result {
                case .failure(let error): print(error)
                case .success(let settings): self.panelData = .init(brightness: settings.brightness,
                                                                    saturation: settings.saturation,
                                                                    contrast: settings.contrast,
                                                                    ir: settings.ir)
                }
            })
        }
    }
    
    static func convertPanelChanges(_ change: PanelView.Event.PanelDataChanges) -> (String, String) {
        switch  change{
        case .brightness(let value):
            return ("1", String(value))
        case .contrast(let value):
            return ("2", String(value))
        case .saturation(let value):
            return ("8", String(value))
        case .ir(let value):
            return ("14", value == true ? "1" : "0")
        }
    }
    
    func handleJoystickEvent(_ event: JoystickView.Event) {
        zodiak.userManipulate(CameraViewController.converter(event)) { result in
            switch result {
            case .success:
                return
            case .failure(let error):
                print(error)
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


protocol ActiveView: UIView&Observable { }


protocol CameraViewControllerFactory {
    func createImageProvider() -> LiveImageProvider
    func createCameraProvider() -> ZodiakProvider
}


class DefaultCameraViewFactory: CameraViewControllerFactory {
    private let cameraSettings: CameraSettingsProvider
    private let mode: Mode
    private let zodiak: Model
    
    enum Mode {
        case snapshot
        case stream
    }
    
    func createImageProvider() -> LiveImageProvider {
        switch mode {
        case .snapshot:
            return DisplayLinkImageUpdater() {
                URL(string: "http://\(self.cameraSettings.host.absoluteString):\(self.cameraSettings.port)/snapshot.cgi?user=\(self.cameraSettings.login)&pwd=\(self.cameraSettings.password)")!
            }
        case .stream:
            return OnlineImageProvider() {
                URL(string: "http://\(self.cameraSettings.host):\(self.cameraSettings.port)/videostream.cgi?loginuse=\(self.cameraSettings.login)&loginpas=\(self.cameraSettings.password)")!}
            //            return IPCameraView(frame: .zero, urlProvider: urlProvider) as! T
        }
    }
    
    func createCameraProvider() -> ZodiakProvider {
        return zodiak
    }
    
    init(cameraSettings: CameraSettingsProvider, mode: Mode) {
        self.cameraSettings = cameraSettings
        self.mode = mode
        self.zodiak = Model(cameraSettings: cameraSettings)
    }
}


struct MockFactory: CameraViewControllerFactory {
    func createImageProvider() -> LiveImageProvider {
        return MoqLiveImageProvider()
    }
    
    private let model: MockModel
    
    init() {
        model = MockModel()
    }
    
    func createCameraProvider() -> ZodiakProvider {
        return model
    }
    
    struct MoqLiveImageProvider: LiveImageProvider {
        var stateHandler: (LiveImageProviderState) -> Void = { _ in }
        
        func start() {
            stateHandler(.active(Images.mock.image))
        }
        
        func stop() {}
        
        func configure(for: UIImageView) {}
    }
}


