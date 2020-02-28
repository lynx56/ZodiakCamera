//
//  Exs.swift
//  ZodiakCamera
//
//  Created by lynx on 06/11/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import Foundation

extension Date {
    func stamp() -> Int64! {
        return Int64(self.timeIntervalSince1970 * 1000) + Int64(arc4random())
    }
}
