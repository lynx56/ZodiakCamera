//
//  AppCoordinator.swift
//  ZodiakCamera
//
//  Created by Holyberry on 23.04.2020.
//  Copyright © 2020 gulnaz. All rights reserved.
//

import UIKit
import KeychainSwift

protocol Coordinator {
    func start()
}

final class AppCoordinator: Coordinator {
    private var active: UIViewController!
    private let window: UIWindow
    
    private let settingsProvider: CameraSettingsProvider = KeychainSwiftWrapper(keychain: KeychainSwift())
    private let bioMetricAuthenticator: BioMetricAuthenticator = DefaultBioMetricAuthenticator()
    private let pinStorage: PinStorage = KeychainSwift()
    private let controllerFactory: ControllerFactory!
    
    init(window: UIWindow) {
        self.window = window
        controllerFactory = DefaultControllerFactory(pinStorage: pinStorage,
                                                     biometricAuthentificator: bioMetricAuthenticator,
                                                     cameraSettingsProvider: settingsProvider)
    }
    
    func start() {
        pinStorage.authEnabled ? showAuth() : showMain()
    }
    
    private func showAuth() {
        let controller = controllerFactory.makeAuthController()
        controller.delegate =
            { didAuth in
                if didAuth {
                    self.showMain()
                    controller.dismiss(animated: true, completion: nil)
                }
        }
        active = controller
        window.rootViewController = controller
        window.makeKeyAndVisible()
    }
    
    private func showMain() {
        let camera = controllerFactory.makeCameraController(router: self)
        window.rootViewController = camera
        active = camera
        window.makeKeyAndVisible()
    }
    
    private var settingsController: UIViewController!
}

extension AppCoordinator: CameraViewControllerRouter {
    func openSettings() {
        settingsController = SettingsViewController(settingsProvider: settingsProvider,
                                                        biometryAuthentification: { (type: self.bioMetricAuthenticator.availableType, enable: self.pinStorage.authEnabled) },
                                                        router: self)
        window.topViewController?.present(settingsController, animated: true, completion: nil)
    }
}

extension AppCoordinator: SettingsViewControllerRouter {
    func openAuthentificator(wantEnable: Bool, completion: (() -> Void)?) {
        if wantEnable == false, pinStorage.authEnabled {
            let controller = controllerFactory.makeAuthController()
            controller.delegate = { authPassed in
                if authPassed {
                    self.pinStorage.pin = nil
                    controller.dismiss(animated: true, completion: nil)
                }
                
            }
            window.topViewController?.present(controller, animated: true, completion: nil)
        } else {
            let controller = controllerFactory.makeRegisterController()
            controller.delegate = { success in
                controller.showSuccessPopup(controller, withTitle: "Ok")
            }
            
            window.topViewController?.present(controller, animated: true, completion: completion)
        }
    }
}


extension UIWindow {
    var topViewController: UIViewController? {
        var topController = self.rootViewController
        while let top = topController?.presentedViewController {
            topController = top
        }
        
        return topController
    }
}
