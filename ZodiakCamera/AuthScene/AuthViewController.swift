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
    
    enum State: Equatable {
        case signOut
        case reenterPin([Int])
        case signIn
        case wrongPasscode
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
        pinView.outputHandler = handlePinViewEvent
        
        model.outputHandler = { event in
            switch event {
            case .change(let title, let filledNumbers, let biometricType):
                self.pinView.render(.init(title: title,
                                          filledDotsCount: filledNumbers,
                                          biometricType: biometricType))
            case .passcodeSaved: self.showSuccessPopup(self, withTitle: L10n.AuthViewController.passcodeSaved)
            }
        }
    }
    
    private let pinView = PinView()
    
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
        
        try! model.handle(event: .start)
    }
    
    private var model = Model(mode:.auth)
    
    private func handlePinViewEvent(_ event: PinView.OutputEvent) {
        switch event {
        case .backspaceTapped:
            try! model.handle(event: .tapped(.delete))
        case .biometricTapped:
            try! model.handle(event: .authentificate)
        case .numberTapped(let number):
            try! model.handle(event: .tapped(.number(number)))
        }
    }
}
