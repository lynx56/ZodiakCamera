//
//  File.swift
//  ZodiakCamera
//
//  Created by Holyberry on 23.04.2020.
//  Copyright © 2020 gulnaz. All rights reserved.
//

import UIKit

protocol Successful: class {
    var delegate: ((Bool) -> Void)? { get set }
}

protocol ControllerFactory {
    func makeAuthController() -> UIViewController & Successful
    func makeRegisterController() -> UIViewController & Successful
    func makeCameraController(router: CameraViewControllerRouter) -> UIViewController
}

class DefaultControllerFactory: ControllerFactory {
    private let pinStorage: PinStorage
    private let biometricAuthentificator: BioMetricAuthenticator
    private let cameraSettingsProvider: CameraSettingsProvider
  
    init(pinStorage: PinStorage,
         biometricAuthentificator: BioMetricAuthenticator,
         cameraSettingsProvider: CameraSettingsProvider) {
        self.pinStorage = pinStorage
        self.biometricAuthentificator = biometricAuthentificator
        self.cameraSettingsProvider = cameraSettingsProvider
    }
    
    func makeAuthController() -> UIViewController & Successful {
        let model = AuthViewController.Model(mode: .auth(.init(bioMetricauthentificator: biometricAuthentificator,
                                                               pinStorage: pinStorage), .idle))
        return AuthViewController(model: model)
    }
    
    func makeRegisterController() -> UIViewController & Successful {
        let model = AuthViewController.Model(mode: .register(.init(pinStorage: pinStorage), .idle))
        return AuthViewController(model: model)
    }
    
    func makeCameraController(router: CameraViewControllerRouter) -> UIViewController {
        #if targetEnvironment(simulator)
        let model = MockModel()
        #else
        let model = Model(cameraSettingsProvider: cameraSettingsProvider, mode: .stream)
        #endif
        let cameraVc = CameraViewController(model: model, router: router)
        return PopupContainer(root: cameraVc)
    }
}
