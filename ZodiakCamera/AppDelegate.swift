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


protocol Coordinator {
    func start()
    func start<T>(parameters: T)
}

extension Coordinator {
    func start<T>(parameters: T) { }
}

final class AppCoordinator: Coordinator {
    private var root: UIViewController!
    private let window: UIWindow
    private var authCoordinator: AuthCoordinator?
    
    private let settingsProvider: CameraSettingsProvider = KeychainSwiftWrapper(keychain: KeychainSwift())
    private let bioMetricAuthenticator: BioMetricAuthenticator = DefaultBioMetricAuthenticator()
    private let pinStorage: PinStorage = KeychainSwift()
    
    init(window: UIWindow) {
        self.window = window
        root = PopupContainer()
        authCoordinator = DefaultAuthCoordinator(root: root, delegate: self)
    }
    
    func start() {
        window.rootViewController = root
        window.makeKeyAndVisible()
      //  pinStorage.authEnabled ? showAuth() :
            showMain()
    }
    
    private func showAuth() {
        authCoordinator?.start()
    }
    
    private func showMain() {
        #if targetEnvironment(simulator)
        let model = MockModel()
        #else
        let model = Model(cameraSettingsProvider: keychain, mode: .stream)
        #endif
        let cameraVc = CameraViewController(model: model, router: self)
        root.show(cameraVc, sender: self)
    }
    
    private var settingsController: UIViewController!
}

extension AppCoordinator: CameraViewControllerRouter {
    func openSettings() {
        settingsController = SettingsViewController(settingsProvider: settingsProvider,
                                                        biometryAuthentification: { (type: self.bioMetricAuthenticator.availableType, enable: self.pinStorage.authEnabled) },
                                                        router: self)
        root.present(settingsController, animated: true, completion: nil)
    }
}

extension AppCoordinator: SettingsViewControllerRouter {
    func openAuthentificator(wantEnable: Bool, completion: (() -> Void)?) {
        authCoordinator!.start(parameters: .manipulate(removePin: true, tryDisable: !wantEnable, manipulator: settingsController))
    }
}

extension AppCoordinator: AuthCoordinatorDelegate {
    func complete(_ success: Bool) {
        if success {
            showMain()
        }
    }
}

protocol AuthCoordinatorDelegate: AnyObject {
    func complete(_ success: Bool)
}

enum AuthParameters {
    case manipulate(removePin: Bool, tryDisable: Bool, manipulator: UIViewController)
    case auth
}

protocol AuthCoordinator: Coordinator {
    var delegate: AuthCoordinatorDelegate? { get set }
    func start(parameters: AuthParameters)
}

final class DefaultAuthCoordinator: AuthCoordinator {
    private let root: UIViewController
    weak var delegate: AuthCoordinatorDelegate?
    
    init(root: UIViewController, delegate: AuthCoordinatorDelegate) {
        self.root = root
        self.delegate = delegate
    }
    
    private var pinStorage: PinStorage = KeychainSwift()
    private var bioMetricAuthenticator: BioMetricAuthenticator = DefaultBioMetricAuthenticator()
    
    func start(parameters: AuthParameters) {
        let mode: AuthViewController.Model.Mode
        
        switch parameters {
        case .manipulate(let removePin, let tryDisable, let manipulator):
            if tryDisable == true, pinStorage.authEnabled {
                mode = .auth(.init(bioMetricauthentificator: bioMetricAuthenticator, pinStorage: pinStorage, removePin: removePin), .idle)
            } else {
                mode = .register(.init(pinStorage: pinStorage), .idle)
            }
            
            let model: AuthViewControllerModel = AuthViewController.Model(mode: mode)
            let authController = AuthViewController(model: model, complete: delegate!.complete)
            
            manipulator.present(authController, animated: true) { [weak self] in
                self?.delegate?.complete(false)
            }
            
        case .auth:
            mode = .auth(.init(bioMetricauthentificator: bioMetricAuthenticator, pinStorage: pinStorage, removePin: false), .idle)
            
            let model: AuthViewControllerModel = AuthViewController.Model(mode: mode)
            let authController = AuthViewController(model: model, complete: delegate!.complete)
            authController.modalPresentationStyle = .fullScreen
            
            root.present(authController, animated: false, completion: nil)
        }
    }
    
    func start() {
        start(parameters: .auth)
    }
}
