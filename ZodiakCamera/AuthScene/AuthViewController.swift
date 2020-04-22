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
    private var model: AuthViewControllerModel
    private let pinView = PinView()
    private var completionHandler: (Bool) -> Void
   
    init(model: AuthViewControllerModel,
         complete: @escaping (Bool) -> Void) {
        self.model = model
        completionHandler = complete
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
            case .success:
                self.completionHandler(true)
            }
        }
    }
    
    private func setupLayout() {
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
    
    private func handlePinViewEvent(_ event: PinView.OutputEvent) {
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
