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
      let popup = PopupContainer(root: AuthViewController())
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = popup//cameraFlow.start()
        window?.makeKeyAndVisible()
        return true
    }
}

class CameraFlowViewController: CameraViewControllerRouter {
    private let keychain = KeychainSwiftWrapper(keychain: KeychainSwift())
    var popup: PopupContainer?
    
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
    
    func openSettings() {
        let settingsController = SettingsViewController(settingsProvider: keychain)
        popup?.present(settingsController, animated: true, completion: nil)
    }
}
