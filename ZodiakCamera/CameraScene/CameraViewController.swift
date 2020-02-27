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
    private var factory: CameraViewControllerFactory
    
    init(factory: CameraViewControllerFactory,
         router: CameraViewControllerRouter) {
        self.router = router
        self.factory = factory
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
        factory.reloaded = { [unowned self] in self.imageProvider.start(with: self.zodiak.liveStreamUrl) }
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
        imageProvider.start(with: zodiak.liveStreamUrl)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        imageProvider.stop()
    }
    
    enum State {
        case error(Error)
        case editing
        case active(UIImage?)
        enum Error {
            case noConnection
            case unknown
        }
    }
    
    private var countErrors: Int = 0
    func update(_ state: State) {
        switch state {
        case .active(let image):
            DispatchQueue.main.async {
                self.noConnection.removeFromSuperview()
                self.ipCameraView.image = image
                self.joystickView.isHidden = false
                self.countErrors = 0
            }
        case .editing:
            joystickView.isHidden = true
        case .error:
            countErrors += 1
            if countErrors > 3 {
                DispatchQueue.main.async {
                    self.view.insertSubview(self.noConnection, aboveSubview: self.ipCameraView, constraints: .pin)
                    self.countErrors = 0
                }
            }
        }
    }
    
    private lazy var noConnection = NoConnectionView()
    func handleLiveImageEvent(_ event: LiveImageProviderState) {
        switch event {
        case .active(let image):
            update(.active(image))
        case .error(let error):
            update(.error(.noConnection))
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
            
            zodiak.chageSettings(change, handler: { result in
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
    
    static private func convertPanelChanges(_ change: PanelView.Event.PanelDataChanges) -> Settings.Change {
        switch  change{
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
    var reloaded: ()->Void { get set }
}


class DefaultCameraViewFactory: CameraViewControllerFactory {
    private var cameraSettingsProvider: CameraSettingsProvider
    private let mode: Mode
    private let zodiak: Model
    var reloaded: ()->Void = { } {
        didSet {
             self.cameraSettingsProvider.updated = reloaded
        }
    }
    enum Mode {
        case snapshot
        case stream
    }
    
    func createImageProvider() -> LiveImageProvider {
        let cameraSettings = cameraSettingsProvider.settings
        switch mode {
        case .snapshot:
            return DisplayLinkImageUpdater()
//                {
//                URL(string: "http://\(cameraSettings.host.absoluteString):\(cameraSettings.port)/snapshot.cgi?user=\(cameraSettings.login)&pwd=\(cameraSettings.password)")!
//            }
        case .stream:
            return OnlineImageProvider()
//                {
//                URL(string: "http://\(cameraSettings.host):\(cameraSettings.port)/videostream.cgi?loginuse=\(cameraSettings.login)&loginpas=\(cameraSettings.password)")!}
//            //            return IPCameraView(frame: .zero, urlProvider: urlProvider) as! T
        }
    }
    
    func createCameraProvider() -> ZodiakProvider {
        return zodiak
    }
    
    init(cameraSettingsProvider: CameraSettingsProvider, mode: Mode ) {
        self.cameraSettingsProvider = cameraSettingsProvider
        self.mode = mode
        self.zodiak = Model(cameraSettingsProvider: cameraSettingsProvider)
    }
}


struct MockFactory: CameraViewControllerFactory {
    var reloaded: () -> Void = { print("reloaded") }
    
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
        func start(with url: URL) {
            stateHandler(.active(Images.mock.image))
        }
        
        var stateHandler: (LiveImageProviderState) -> Void = { _ in }
        
        func stop() {}
        
        func configure(for: UIImageView) {}
    }
}
