//
//  AuthViewController.swift
//  ZodiakCamera
//
//  Created by lynx on 31.03.2020.
//  Copyright © 2020 gulnaz. All rights reserved.
//

import UIKit
import KeychainSwift

class AuthViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
        pinView.outputHandler = handlePinViewEvent
        
        model.outputHandler = { event in
            switch event {
            case .change(let viewState):
                self.pinView.render(.init(title: viewState.title,
                                          filledDotsCount: viewState.filledNumbers,
                                          biometricType: viewState.biometricType))
            case .success: self.showSuccessPopup(self, withTitle: L10n.AuthViewController.passcodeSaved)
            }
        }
    }
    
    private let pinView = PinView()
    
    var model = Model(mode: .auth(AuthModel(), .idle))
   // var model = Model(mode: .register(RegisterModel(), .idle))
    
    func setupLayout() {
        view.addSubview(pinView, constraints: [
            constraint(\.leadingAnchor, constant: 47),
            constraint(\.trailingAnchor, constant: -47),
            constraint(\.topAnchor, constant: 152)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.startPoint = .zero
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.colors = [UIColor(red:34.0/255.0, green:211/255.0, blue:198/255.0, alpha:1.0).cgColor,
                           UIColor(red:145/255.0, green:72.0/255.0, blue:203/255.0, alpha:1.0).cgColor]
        
        view.layer.insertSublayer(gradient, at: 0)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        model.handle(.start)
    }
    
    func handlePinViewEvent(_ event: PinView.OutputEvent) {
        switch event {
        case .backspaceTapped:
            model.handle(.tapped(.delete))
        case .biometricTapped:
            model.handle(.authentificate)
        case .numberTapped(let number):
            model.handle(.tapped(.number(number)))
        }
    }
}
