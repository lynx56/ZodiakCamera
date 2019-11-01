//
//  Model.swift
//  ZodiakCamera
//
//  Created by lynx on 01/11/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import Foundation

class Model: ZodiakProvider {
    private let authProvider: () -> (String, String)
    private var settings = Dictionary<Settings, Int>()
    private let host: URL
    
    init(authProvider: @escaping () -> (String, String),
         host: URL) {
        self.authProvider = authProvider
        self.host = host
        self.readsettings(handler: { (updatedSettings, error) in
            guard let settings = updatedSettings else { return }
            self.settings = settings
        })
    }
    
    enum Target {
        case image
        case settings
        case changeSettings
        case userManipulate
    }
    
    private func getUrl(with cgi: String) -> String {
        let (user, password) = authProvider()
        return "\(host.absoluteString)/\(cgi)?loginuse=\(user)&amp;loginpas=\(password)"
    }
    
    func image() -> Data? {
        return try? Data(contentsOf: URL(string: "http://188.242.14.235:81/snapshot.cgi?user=admin&pwd=123123")!)
    }
    
    func readsettings(handler: @escaping (Dictionary<Settings, Int>?, Error?) -> Void) {
        let url = getUrl(with: "get_camera_params.cgi")
        let task = URLSession.shared.downloadTask(with: URL(string: url)!) { (file, response, error) in
            if let file = file {
                do {
                    handler(try String(contentsOf: file).parseCGI(), nil)
                } catch {
                    handler(nil, error)
                }
            }
        }
        
        task.resume()
    }
    
    func chageSettings(param: String, value: String) {
        var cgi =  getUrl(with: "camera_control.cgi")
        cgi += "&param=\(param)&value=\(value)"
        cgi += "&\(Date().stamp()!)"
        print(cgi)
        let url = URL(string: cgi)!
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            print(response)
        }
        
        task.resume()
    }
    
    func userManipulate(command: String) {
        var cgi = getUrl(with: "decoder_control.cgi");
        cgi += "&command=\(command)"
        cgi += "&onestep=0"
        cgi += "&\(Date().stamp())"
        
        let url = URL(string: cgi)!
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            print(error)
        }
        
        task.resume()
    }
}

extension Model: PanelDataProvider {
    var brightness: Int {
        get {
            return settings[.Bright] ?? 0
        }
        set {
            settings[.Bright] = newValue
            let convertedValue = settingsConverter(settings: .Bright, value: "\(newValue)")
            chageSettings(param: convertedValue.0, value: convertedValue.1)
        }
    }
    
    var saturation: Int {
        get {
            return settings[.Saturation] ?? 0
        }
        set {
            settings[.Saturation] = newValue
            let convertedValue = settingsConverter(settings: .Saturation, value: "\(newValue)")
            chageSettings(param: convertedValue.0, value: convertedValue.1)
        }
    }
    
    var contract: Int {
        get {
            return settings[.Contrast] ?? 0
        }
        set {
            settings[.Contrast] = newValue
            let convertedValue = settingsConverter(settings: .Contrast, value: "\(newValue)")
            chageSettings(param: convertedValue.0, value: convertedValue.1)
        }
    }
    
    var ir: Bool {
        get {
            return settings[.IRcut] == 1
        }
        set {
            settings[.IRcut] = newValue == true ? 1 : 0
            let convertedValue = settingsConverter(settings: .IRcut, value: "\(newValue == true ? 1 : 0)")
            chageSettings(param: convertedValue.0, value: convertedValue.1)
           // chageSettings(param: Settings.IRcut.rawValue, value: "\(newValue == true ? 1 : 0)")
        }
    }
}

class MockModel: ZodiakProvider {
    private var settings = Dictionary<Settings, Int>()
    
    func image() -> Data? {
        return nil
    }
    func chageSettings(param: String, value: String) {
        print("chageSettings(param: \(param), value: \(value)")
    }
    
    func userManipulate(command: String) {
         print("userManipulate(command: \(command)")
    }
}

extension MockModel: PanelDataProvider {
    var brightness: Int {
        get {
            return settings[.Bright] ?? 0
        }
        set {
            settings[.Bright] = newValue
            chageSettings(param: Settings.Bright.rawValue, value: "\(newValue)")
        }
    }
    
    var saturation: Int {
        get {
            return settings[.Saturation] ?? 0
        }
        set {
            settings[.Saturation] = newValue
            chageSettings(param: Settings.Saturation.rawValue, value: "\(newValue)")
        }
    }
    
    var contract: Int {
        get {
            return settings[.Contrast] ?? 0
        }
        set {
            settings[.Contrast] = newValue
            chageSettings(param: Settings.Contrast.rawValue, value: "\(newValue)")
        }
    }
    
    var ir: Bool {
        get {
            return settings[.IRcut] == 1
        }
        set {
            settings[.IRcut] = newValue == true ? 1 : 0
            let convertedValue = settingsConverter(settings: .IRcut, value: "\(newValue == true ? 1 : 0)")
            chageSettings(param: convertedValue.0, value: convertedValue.1)
        }
    }
}

protocol PanelDataProvider {
    var brightness: Int { get set }
    var saturation: Int { get set }
    var contract: Int { get set }
    var ir: Bool { get set }
}

protocol AuthService {
    func userAuth() -> (String, String)
}


protocol ZodiakProvider {
    func image() -> Data?
    func chageSettings(param: String, value: String)
    func userManipulate(command: String)
}
