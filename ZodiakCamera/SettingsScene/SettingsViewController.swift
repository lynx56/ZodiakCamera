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
        var login: String? = settingsProvider.login
        var password: String? = settingsProvider.password
        var host: URL? = settingsProvider.host
        var port: Int? = settingsProvider.port
        
        form +++ Section("Настройки доступа")
            <<< TextRow() { row in
                row.title = "Логин"
                row.placeholder = "admin"
                row.value = settingsProvider.login
                row.add(rule: RuleRequired())
                row.cellUpdate({if !$1.isValid { $0.titleLabel?.textColor = .systemRed }})
            }.onChange{ [unowned self] in
                login = $0.value
            }
            <<< PasswordRow() { row in
                row.title = "Пароль"
                row.placeholder = "123123"
                row.value = settingsProvider.password
                row.add(rule: RuleRequired())
                row.cellUpdate({if !$1.isValid { $0.titleLabel?.textColor = .systemRed }})
            }.onChange{ [unowned self] in
                password = $0.value
            }
            +++ Section("Адрес")
            <<< URLRow() { row in
                row.title = "Хост"
                row.placeholder = "192.168.1.1"
                row.value = settingsProvider.host
                row.add(rule: RuleRequired())
                row.cellUpdate({if !$1.isValid { $0.titleLabel?.textColor = .systemRed }})
            }.onChange{
                host = $0.value
            }
            <<< IntRow() { row in
                row.title = "Порт"
                row.placeholder = "81"
                row.value = settingsProvider.port
                row.add(rule: RuleRequired())
                row.cellUpdate({if !$1.isValid { $0.titleLabel?.textColor = .systemRed }})
            }.onChange{ [unowned self] in
                port = $0.value
        }
        
        form +++ ButtonRow() {
            $0.title = "Сохранить"
        }.onCellSelection({ [unowned self](cell, row) in
            if self.form.validate().isEmpty {
                self.settingsProvider.login = login!
                self.settingsProvider.password = password!
                self.settingsProvider.host = host!
                self.settingsProvider.port = port!
                self.showSuccessPopup(self, withTitle: "Сохранено")
            }
        })
    }
}


protocol CameraSettingsProvider {
    var login: String { get set }
    var password: String { get set }
    var host: URL { get set }
    var port: Int { get set }
}

extension KeychainSwift: CameraSettingsProvider {
    enum Keys {
        static let login = "ZodiakCamera.CameraSettings.Login"
        static let password = "ZodiakCamera.CameraSettings.Password"
        static let host = "ZodiakCamera.CameraSettings.Host"
        static let port = "ZodiakCamera.CameraSettings.Port"
    }
    
    var login: String {
        get {
            return get(Keys.login) ?? ""
        }
        set {
            set(newValue, forKey: Keys.login)
        }
    }
    
    var password: String {
        get {
            return get(Keys.password) ?? ""
        }
        set {
            set(newValue, forKey: Keys.password)
        }
    }
    
    var host: URL {
        get {
            return URL(string: get(Keys.host) ?? "") ?? URL(string: "192.168.1.1")!
        }
        set {
            set(newValue.absoluteString, forKey: Keys.host)
        }
    }
    
    var port: Int {
        get {
            return Int(get(Keys.port) ?? "") ?? 81
        }
        set {
            set(String(newValue), forKey: Keys.port)
        }
    }
}
