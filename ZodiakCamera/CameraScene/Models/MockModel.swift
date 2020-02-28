//
//  MockModel.swift
//  ZodiakCamera
//
//  Created by lynx on 28/02/2020.
//  Copyright © 2020 gulnaz. All rights reserved.
//

import UIKit

struct MockModel: CameraViewControllerModel {
   
    var imageProviderHandler: (LiveImageProviderState) -> Void = { _ in }
    
    var imageProvider: LiveImageProvider { return MoqLiveImageProvider() }
   
    func changeSettings(_ change: SettingsChange, resultHandler: @escaping (Result<Settings, Error>) -> Void) {}
    
    func userManipulate(command: UserManipulation, resultHandler: @escaping (Result<Void, Error>) -> Void) {}
    
    struct MoqLiveImageProvider: LiveImageProvider {
        func start() {
            stateHandler(.active(Images.mock.image))
        }
        var stateHandler: (LiveImageProviderState) -> Void = { _ in }
        func stop() {}
        func configure(for: UIImageView) {}
    }
}
