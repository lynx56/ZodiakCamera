//
//  ConcreteModels.swift
//  ZodiakCamera
//
//  Created by lynx on 28/02/2020.
//  Copyright © 2020 gulnaz. All rights reserved.
//

import UIKit

class Model: CameraViewControllerModel {
    var isTourShowed: Bool {
        get { viewSettingsProvider.isTourShowed }
        set { viewSettingsProvider.isTourShowed = newValue }
    }
    
    private var cameraSettingsProvider: CameraSettingsProvider
    private var viewSettingsProvider: ViewSettingsProvider
    private let mode: Mode
    private var zodiak: Api
    enum Mode {
        case snapshot
        case stream
    }
    
    private var imageProvider: LiveImageProvider?
    
    var imageProviderHandler: (LiveImageProviderState) -> Void = { _ in } {
        didSet {
            self.imageProvider?.stateHandler = imageProviderHandler
        }
    }
      
    init(cameraSettingsProvider: CameraSettingsProvider,
         mode: Mode,
         viewSettingsProvider: ViewSettingsProvider) {
        self.cameraSettingsProvider = cameraSettingsProvider
        self.mode = mode
         self.zodiak = Api(cameraSettingsProvider: cameraSettingsProvider)
        self.viewSettingsProvider = viewSettingsProvider
        self.cameraSettingsProvider.updated = { [weak self] in
            guard let self = self else { return }
            self.zodiak = Api(cameraSettingsProvider: self.cameraSettingsProvider)
            self.reinitImageProvider()
            self.imageProvider?.start()
        }
        
        reinitImageProvider()
    }
    
    func reinitImageProvider() {
        switch mode {
        case .snapshot:
            self.imageProvider = LiveImageProvideByDisplayLink(url: self.zodiak.snapshotUrl)
        case .stream:
            self.imageProvider = LiveImageProvideByStream(url: self.zodiak.liveStreamUrl)
        }
        self.imageProvider?.stateHandler = imageProviderHandler
    }
    
    var contentMode: UIView.ContentMode {
        switch mode {
        case .snapshot:
            return .redraw
        case .stream:
            return .scaleAspectFill
        }
    }
    
    deinit {
        imageProvider?.stop()
    }
    
    func start() {
        imageProvider?.start()
    }
    
    func pause() {
        imageProvider?.stop()
    }
    
    func changeSettings(_ change: SettingsChange, resultHandler: @escaping (Result<Settings, Error>) -> Void) {
        let convertedApiSettings = Model.settingsChangeToUrlParamsConverter(change)
        zodiak.changeSettings(convertedApiSettings.parameter, value: convertedApiSettings.value, handler: resultHandler)
    }
    
    func userManipulate(command: UserManipulation, resultHandler: @escaping (Result<Void, Error>) -> Void) {
        let convertedValues = Model.userManipulateConverter(command)
        zodiak.userManipulate(convertedValues.command, cancelPrevious: convertedValues.cancelOthers, handler: resultHandler)
    }
    
    static func userManipulateConverter(_ command: UserManipulation) -> (command: String, cancelOthers: Bool) {
         let convertedCommand: Int?
         var cancellOthersCommands = false
         switch command {
         case .stop:
             convertedCommand = 1
             cancellOthersCommands = true
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
         
        guard let command = convertedCommand else { return ("", false) }
        
         return ("\(command)", cancellOthersCommands)
     }
    
    static func settingsChangeToUrlParamsConverter(_ changes: SettingsChange) -> (parameter: String, value: String) {
        switch changes {
        case .brightness(let value):
            return ("1", String(value))
        case .contrast(let value):
            return ("2", String(value))
        case .saturation(let value):
            return ("8", String(value))
        case .ir(let value):
            return ("14", value == true ? "1" : "0")
        case .resolution(let resolution):
            switch resolution {
            case ._1280x720: return ("0", "2")
            case ._320x240: return ("0", "1")
            case ._640x480: return ("0", "0")
            }
        }
    }
}


protocol ViewSettingsProvider {
    var isTourShowed: Bool { get set }
}

extension UserDefaults: ViewSettingsProvider {
    var isTourShowed: Bool {
        get {
            return self.bool(forKey: "CameraViewController.isTourShowed")
        }
        set {
            self.set(newValue, forKey: "CameraViewController.isTourShowed")
        }
    }
}
