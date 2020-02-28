//
//  Settings.swift
//  ZodiakCamera
//
//  Created by lynx on 06/11/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import Foundation

public struct Settings {
    var resolution: Int = 0
    var mode: Int = 0
    var OSDEnable: Bool = false
    var resolutionSub: Int = 0
    var subEncFramerate: Int = 0
    var brightness: LimitValue = .initial
    var saturation: LimitValue = .initial
    var bitrate: Int = 0
    var hue: LimitValue = .initial
    var flip: Int = 0
    var ir: Bool = false
    var speed: Int = 0
    var framerate: Int = 0
    var contrast: LimitValue = .initial
}
