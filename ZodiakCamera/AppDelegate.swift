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

class CameraFlowViewController: CameraViewControllerRouter {
    private let keychain = KeychainSwiftWrapper(keychain: KeychainSwift())
    var popup: PopupContainer?
    
    func start() -> UIViewController {
        let factory = DefaultCameraViewFactory(cameraSettingsProvider: keychain, mode: .stream)
        //let factory = MockFactory()
        let cameraVc = CameraViewController(factory: factory, router: self)
        popup = PopupContainer(root: cameraVc)
        return popup!
    }
    
    func openSettings() {
        let settingsController = SettingsViewController(settingsProvider: keychain)
        popup?.present(settingsController, animated: true, completion: nil)
    }
}
