//
//  Model.swift
//  ZodiakCamera
//
//  Created by lynx on 01/11/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import Foundation

class Model: ZodiakProvider {
    private let cameraSettings: CameraSettingsProvider
    private var settings = Settings()
    
    init(cameraSettings: CameraSettingsProvider) {
        self.cameraSettings = cameraSettings
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
        return "http://\(cameraSettings.host.absoluteString):\(cameraSettings.port)/\(cgi)?loginuse=\(cameraSettings.login)&amp;loginpas=\(cameraSettings.password)"
    }
    
    func image() -> Data? {
        return try? Data(contentsOf: URL(string: "http://\(cameraSettings.host.absoluteString):\(cameraSettings.port)/snapshot.cgi?user=\(cameraSettings.login)&pwd=\(cameraSettings.password)")!)
    }
    
    func readsettings(handler: @escaping (Settings?, Error?) -> Void) {
        let url = getUrl(with: "get_camera_params.cgi")
        let task = URLSession.shared.downloadTask(with: URL(string: url)!) { (file, response, error) in
            if let file = file {
                do {
                    handler(try? Settings(json: String(contentsOf: file)), nil)
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
    
    func userManipulate(_ command: UserManipulation) {
        let convertedCommand: Int?
        switch command {
        case .stop: convertedCommand = 1
        case .start: convertedCommand = nil
        case .move(let direction):
            switch direction {
            case .down: convertedCommand = 2
            case .downleft: convertedCommand = 92
            case .downright: convertedCommand = 93
            case .left: convertedCommand = 4
            case .right: convertedCommand = 6
            case .up: convertedCommand = 0
            case .upleft: convertedCommand = 90
            case .upright: convertedCommand = 91
            }
        }
        
        guard let cameraManipulate = convertedCommand else { return }
        
        userControl("\(cameraManipulate)")
    }

    
    private func userControl(_ command: String) {
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
    private func updateSettings(for keyPath: KeyPath<Settings, LimitValue>) {
        let convertedValue = settings.convert(for: keyPath)
        chageSettings(param: convertedValue.parameter, value: convertedValue.value)
    }
    
    var brightness: LimitValue {
        get {
            return settings.brightness
        }
        set {
            settings.brightness = newValue
            updateSettings(for: \.brightness)
        }
    }
    
    var saturation: LimitValue {
        get {
            return settings.saturation
        }
        set {
            updateSettings(for: \.saturation)
        }
    }
    
    var contrast: LimitValue {
        get {
            return settings.contrast
        }
        set {
            updateSettings(for: \.contrast)
        }
    }
    
    var ir: Bool {
        get {
            return settings.ir
        }
        set {
            settings.ir = newValue
            let convertedCommand = settings.convert(for: \.ir)
            chageSettings(param: convertedCommand.parameter, value: convertedCommand.value)
        }
    }
    
    
}

protocol PanelDataProvider {
    var brightness: LimitValue { get set }
    var saturation: LimitValue { get set }
    var contrast: LimitValue { get set }
    var ir: Bool { get set }
}

protocol AuthService {
    func userAuth() -> (String, String)
}


protocol ZodiakProvider {
    func image() -> Data?
    func chageSettings(param: String, value: String)
    func userManipulate(_ command: UserManipulation)
}

enum UserManipulation {
    enum Move {
        case up
        case upleft
        case left
        case downleft
        case down
        case right
        case downright
        case upright
    }
    case move(Move)
    case stop
    case start
}
