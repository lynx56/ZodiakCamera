//
//  SettingsViewController.swift
//  ZodiakCamera
//
//  Created by lynx on 15/10/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import Eureka
import UIKit
import KeychainSwift
import LocalAuthentication

class SettingsViewController: FormViewController {
    private var settingsProvider: CameraSettingsProvider
    
    init(settingsProvider: CameraSettingsProvider) {
        self.settingsProvider = settingsProvider
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    func setupView() {
        var settings = settingsProvider.settings
        
        form +++ Section(L10n.Settings.access)
            <<< TextRow() { row in
                row.title = L10n.Settings.login
                row.placeholder = "admin"
                row.value = settings.login
                row.add(rule: RuleRequired())
                row.cellUpdate({if !$1.isValid { $0.titleLabel?.textColor = .systemRed }})
            }.onChange{ settings.login = $0.value ?? "" }
            <<< PasswordRow() { row in
                row.title = L10n.Settings.password
                row.placeholder = "123123"
                row.value = settings.password
                row.add(rule: RuleRequired())
                row.cellUpdate({if !$1.isValid { $0.titleLabel?.textColor = .systemRed }})
            }.onChange { settings.password = $0.value ?? "" }
            <<< SwitchRow() { row in
                let context = LAContext()
                var error: NSError?
                let evaluated = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
                guard error == nil, evaluated else { return }
                
                switch context.biometryType {
                case .faceID:
                    row.title = L10n.Settings.faceId
                    row.hidden = false
                case .touchID:
                    row.title = L10n.Settings.faceId
                    row.hidden = false
                case .none:
                    row.hidden = true
                @unknown default:
                    row.hidden = true
                }
                row.value = settings.authEnabled
            }
            +++ Section(L10n.Settings.address)
            <<< URLRow() { row in
                row.title = L10n.Settings.host
                row.placeholder = "192.168.1.1"
                row.value = settings.host
                row.add(rule: RuleRequired())
                row.cellUpdate({if !$1.isValid { $0.titleLabel?.textColor = .systemRed }})
            }.onChange{
                settings.host = $0.value ?? URL(string: "192.168.1.1")!
            }
            <<< IntRow() { row in
                row.title = L10n.Settings.port
                row.placeholder = "81"
                row.value = settings.port
                row.add(rule: RuleRequired())
                row.cellUpdate({if !$1.isValid { $0.titleLabel?.textColor = .systemRed }})
            }.onChange { settings.port = $0.value ?? 81 }
        
        form +++ ButtonRow() {
            $0.title = L10n.Settings.save
        }.onCellSelection({ [unowned self] (cell, row) in
            if self.form.validate().isEmpty {
                self.settingsProvider.update(settings: settings)
                self.showSuccessPopup(self, withTitle: L10n.Settings.saved)
            }
        })
    }
}

struct CameraSettings {
    var login: String
    var password: String
    var host: URL
    var port: Int
    var authEnabled: Bool
}

protocol CameraSettingsProvider {
    var settings: CameraSettings { get }
    func update(settings: CameraSettings)
    var updated: ()->Void { get set }
}

class KeychainSwiftWrapper: CameraSettingsProvider {
    var updated: () -> Void = {}
    
    private var keychain: KeychainSwift
    enum Keys {
        static let login = "ZodiakCamera.CameraSettings.Login"
        static let password = "ZodiakCamera.CameraSettings.Password"
        static let host = "ZodiakCamera.CameraSettings.Host"
        static let port = "ZodiakCamera.CameraSettings.Port"
        static let authEnabled = "ZodiakCamera.CameraSettings.AuthEnabled"
    }
    
    var settings: CameraSettings {
        return .init(login: keychain.get(Keys.login) ?? "",
                     password: keychain.get(Keys.password) ?? "",
                     host: URL(string: keychain.get(Keys.host) ?? "") ?? URL(string: "192.168.1.1")!,
                     port: Int(keychain.get(Keys.port) ?? "") ?? 81,
                     authEnabled: keychain.getBool(Keys.authEnabled) ?? false)
    }
    
    init(keychain: KeychainSwift) {
        self.keychain = keychain
    }
    
    func update(settings: CameraSettings) {
        keychain.set(settings.login, forKey: Keys.login)
        keychain.set(settings.password, forKey: Keys.password)
        keychain.set(settings.host.absoluteString, forKey: Keys.host)
        keychain.set(String(settings.port), forKey: Keys.port)
        keychain.set(settings.authEnabled, forKey: Keys.authEnabled)
        updated()
    }
}

