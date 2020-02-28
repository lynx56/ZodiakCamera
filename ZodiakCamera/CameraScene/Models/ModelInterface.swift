//
//  Model.swift
//  ZodiakCamera
//
//  Created by lynx on 28/02/2020.
//  Copyright © 2020 gulnaz. All rights reserved.
//

import Foundation

protocol CameraViewControllerModel {
    var imageProvider: LiveImageProvider { get }
    var imageProviderHandler: (LiveImageProviderState) -> Void { get set }
    func changeSettings(_ change: SettingsChange, resultHandler: @escaping (Result<Settings, Error>) -> Void)
    func userManipulate(command: UserManipulation, resultHandler: @escaping (Result<Void, Error>) -> Void)
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

enum SettingsChange {
    case brightness(Int)
    case contrast(Int)
    case saturation(Int)
    case ir(Bool)
}
