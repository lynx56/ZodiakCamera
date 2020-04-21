//
//  AppDelegate.swift
//  ZodiakCamera
//
//  Created by lynx on 14/10/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import UIKit
import KeychainSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let cameraFlow = CameraFlowViewController()
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = cameraFlow.start()
        window?.makeKeyAndVisible()
        return true
    }
}

class CameraFlowViewController: CameraViewControllerRouter, SettingsViewControllerRouter {
    private let keychain = KeychainSwiftWrapper(keychain: KeychainSwift())
    var popup: PopupContainer?
    var bioMetricAuthenticator: BioMetricAuthenticator = DefaultBioMetricAuthenticator()
    
    func start() -> UIViewController {
        #if targetEnvironment(simulator)
        let model = MockModel()
        #else
        let model = Model(cameraSettingsProvider: keychain, mode: .stream)
        #endif
        let cameraVc = CameraViewController(model: model, router: self)
        popup = PopupContainer(root: cameraVc)
        return popup!
    }
    
    private var settingsController: SettingsViewController?
    private var pinStorage: PinStorage = KeychainSwift()
    func openSettings() {
        settingsController = SettingsViewController(settingsProvider: keychain,
                                                    biometryAuthentification: { (type: self.bioMetricAuthenticator.availableType, enable: self.pinStorage.authEnabled) },
                                                    router: self)
        popup?.present(settingsController!, animated: true, completion: nil)
    }
    
    func openAuthentificator(wantEnable: Bool, completion: (()->Void)?) {
        let model: AuthViewControllerModel
        
        if wantEnable == false, pinStorage.authEnabled {
            model = AuthViewController.Model(mode: .auth(.init(bioMetricauthentificator: bioMetricAuthenticator, pinStorage: pinStorage, removePin: true), .idle))
        } else {
            model = AuthViewController.Model(mode: .register(.init(pinStorage: pinStorage), .idle))
        }
     
        let authController = AuthViewController(model: model)
        settingsController?.present(authController, animated: true, completion: completion)
    }
}
