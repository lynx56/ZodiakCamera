//
//  Model.swift
//  ZodiakCamera
//
//  Created by lynx on 28/02/2020.
//  Copyright © 2020 gulnaz. All rights reserved.
//

import UIKit

protocol CameraViewControllerModel {
    var imageProviderHandler: (LiveImageProviderState) -> Void { get set }
    func changeSettings(_ change: SettingsChange, resultHandler: @escaping (Result<Settings, Error>) -> Void)
    func userManipulate(command: UserManipulation, resultHandler: @escaping (Result<Void, Error>) -> Void)
    func start()
    func pause()
    var contentMode: UIView.ContentMode { get }
    var isTourShowed: Bool { get set }
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

public enum CameraResolution: Int, CaseIterable {
    case _640x480 = 0
    case _320x240 = 1
    case _1280x720 = 2
    
    var text: String {
        switch self {
        case ._1280x720: return "720p"
        case ._640x480: return "VGA"
        case ._320x240: return "QVGA"
        }
    }
}

enum SettingsChange {
    case brightness(Int)
    case contrast(Int)
    case saturation(Int)
    case ir(Bool)
    case resolution(CameraResolution)
}
