//
//  Settings.swift
//  ZodiakCamera
//
//  Created by lynx on 06/11/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import Foundation

struct LimitValue {
    var maxValue: Int
    var minValue: Int
    var currentValue: Int
    static let initial = LimitValue(maxValue: 0, minValue: 0, currentValue: 0)
}
