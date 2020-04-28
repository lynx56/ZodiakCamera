//
//  IPCameraView.swift
//  ZodiakCamera
//
//  Created by lynx on 02/12/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import UIKit
import Combine

protocol LiveImageProvider {
    var stateHandler: (LiveImageProviderState)->Void { get set }
    func start()
    func stop()
}

enum LiveImageProviderState {
    case active(UIImage?)
    case error(Error)
}
