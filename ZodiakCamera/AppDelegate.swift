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
        
        window = UIWindow(frame: UIScreen.main.bounds)
        let appCoordinator = AppCoordinator(window: window!)
        window?.makeKeyAndVisible()
        appCoordinator.start()
        return true
    }
}
