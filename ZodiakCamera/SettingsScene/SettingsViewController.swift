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

protocol SettingsViewControllerRouter {
    func openAuthentificator(wantEnable: Bool, completion: (()->Void)?)
}
 
class SettingsViewController: FormViewController {
    private let settingsProvider: CameraSettingsProvider
    private let biometryAuthentification: () -> (type: BiometricType, enabled: Bool)
    private let router: SettingsViewControllerRouter
    
    init(settingsProvider: CameraSettingsProvider,
         biometryAuthentification: @escaping () -> (type: BiometricType, enabled: Bool),
         router: SettingsViewControllerRouter) {
        self.settingsProvider = settingsProvider
        self.biometryAuthentification = biometryAuthentification
        self.router = router
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    private func setupView() {
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
            <<< SwitchRow() { row in row.tag = "Auth" }
                .onChange { [weak self] row in
                guard let self = self else { return }
                if row.value != self.biometryAuthentification().enabled {
                    self.router.openAuthentificator(wantEnable: row.value!, completion: {
                        self.form.rowBy(tag: "Auth")?.updateCell()
                    })
                }
            }.cellUpdate({ (cell, row) in
                let biometryAuthentification = self.biometryAuthentification()
                switch biometryAuthentification.type {
                case .faceId:
                    row.title = L10n.Settings.faceId
                    row.hidden = false
                case .touchId:
                    row.title = L10n.Settings.faceId
                    row.hidden = false
                case .none:
                    row.hidden = true
                }
                row.value = biometryAuthentification.enabled
                row.reload()
            })
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
    }
    
    var settings: CameraSettings {
        return .init(login: keychain.get(Keys.login) ?? "",
                     password: keychain.get(Keys.password) ?? "",
                     host: URL(string: keychain.get(Keys.host) ?? "") ?? URL(string: "192.168.1.1")!,
                     port: Int(keychain.get(Keys.port) ?? "") ?? 81)
    }
    
    init(keychain: KeychainSwift) {
        self.keychain = keychain
    }
    
    func update(settings: CameraSettings) {
        keychain.set(settings.login, forKey: Keys.login)
        keychain.set(settings.password, forKey: Keys.password)
        keychain.set(settings.host.absoluteString, forKey: Keys.host)
        keychain.set(String(settings.port), forKey: Keys.port)
        updated()
    }
}

