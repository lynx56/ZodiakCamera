//
//  NetworkListener.swift
//  Color Researcher
//
//  Created by lynx on 18/09/2019.
//  Copyright © 2019 Zerotech. All rights reserved.
//

import Foundation
import AVFoundation

protocol NetworkListener {
    func startObserving(networkConnectionChanged: @escaping(ConnectionStatus) -> Void)
    func stopObserving()
}

enum ConnectionStatus {
    case wifi
    case cellular
    case none
    
    var isReachable: Bool {
        switch self {
        case .cellular, .wifi:
            return true
        case .none:
            return false
        }
    }
}
