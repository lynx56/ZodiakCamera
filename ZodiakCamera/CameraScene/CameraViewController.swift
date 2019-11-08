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
    private let imageView = UIImageView()
    private let zodiak: ZodiakProvider
    private let router: CameraViewControllerRouter
      
    init(zodiak: ZodiakProvider, dataProvider: PanelDataProvider, router: CameraViewControllerRouter) {
        self.zodiak = zodiak
        self.panelView = PanelView(frame: .zero, provider: dataProvider)
        self.router = router
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        imageView.image = UIImage(named: "mock")
    }
    
    private func setup() {
        view.backgroundColor = .white
        imageView.contentMode = .redraw
        view.addSubview(imageView, constraints: [
            constraint(\.leadingAnchor),
            constraint(\.trailingAnchor),
            constraint(\.topAnchor),
            constraint(\.bottomAnchor)
        ])
        
        view.addSubview(panelView, constraints: [
            constraint(\.leftAnchor),
            constraint(\.rightAnchor),
            constraint(\.bottomAnchor)
        ])
        
        panelView.constrainToView(imageView, constraints: [
            constraint(\.topAnchor, \.bottomAnchor, constant: -84),
        ])
        
        view.addSubview(joystickView)
        joystickView.constrainToView(imageView, constraints: [
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
        settings.setImage(UIImage(named: "settings"), for: .normal)
        settings.tintColor = .white
        view.addSubview(settings, pairingTo: imageView, constraints: [
            constraint(\.trailingAnchor, constant: -17),
            constraint(\.topAnchor, constant: 34),
        ])
        settings.constrain(to:
            constraint(\.widthAnchor, constant: 34),
            constraint(\.heightAnchor, constant: 34))
        settings.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        imageView.isHidden = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap)))
    }
    var ipCameraView: IPCameraView!
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //createDisplayLink()
        
        ipCameraView = IPCameraView(frame: self.view.bounds)
        view.addSubview(ipCameraView)
        ipCameraView.startWithURL(url: URL(string: "http://188.242.14.235:81/videostream.cgi?loginuse=admin&loginpas=123123123")!)
        
        joystickView.moveHandler = {[weak self] in
            self?.zodiak.userManipulate(CameraViewController.converter($0))
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        ipCameraView.stop()
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
    
    private func createDisplayLink() {
        let displaylink = CADisplayLink(target: self,
                                        selector: #selector(update))
        
        displaylink.add(to: .current,
                        forMode: .default)
    }
    
    @objc private func update(displaylink: CADisplayLink) {
        guard let data = zodiak.image() else { return }
        imageView.image = UIImage(data: data)?.resizeWithScaleAspectFitMode(to: UIScreen.main.bounds.size) //imageView.bounds.size)
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
