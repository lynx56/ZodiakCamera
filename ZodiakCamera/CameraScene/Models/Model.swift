//
//  ConcreteModels.swift
//  ZodiakCamera
//
//  Created by lynx on 28/02/2020.
//  Copyright © 2020 gulnaz. All rights reserved.
//

import UIKit

class Model: CameraViewControllerModel {
    private var cameraSettingsProvider: CameraSettingsProvider
    private let mode: Mode
    private let zodiak: Api
    enum Mode {
        case snapshot
        case stream
    }
    
    private var cachedImageProvider: LiveImageProvider?
    
    var imageProvider: LiveImageProvider {
        if cachedImageProvider == nil {
            switch mode {
            case .snapshot:
                cachedImageProvider = LiveImageProvideByDisplayLink(url: zodiak.snapshotUrl)
            case .stream:
                cachedImageProvider = LiveImageProvideByStream(url: zodiak.liveStreamUrl)
            }
        }
        
        return cachedImageProvider!
    }
    var imageProviderHandler: (LiveImageProviderState) -> Void = { _ in } {
        didSet {
            cachedImageProvider?.stateHandler = imageProviderHandler
        }
    }
    
    init(cameraSettingsProvider: CameraSettingsProvider, mode: Mode) {
        self.cameraSettingsProvider = cameraSettingsProvider
        self.mode = mode
        self.zodiak = Api(cameraSettingsProvider: cameraSettingsProvider)
        self.cameraSettingsProvider.updated = { self.cachedImageProvider = nil }
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
        }
    }
}
