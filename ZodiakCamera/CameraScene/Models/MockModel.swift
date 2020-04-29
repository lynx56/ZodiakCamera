//
//  MockModel.swift
//  ZodiakCamera
//
//  Created by lynx on 28/02/2020.
//  Copyright © 2020 gulnaz. All rights reserved.
//

import UIKit

struct MockModel: CameraViewControllerModel {
    func start() {
        imageProviderHandler(.error(.invalidHost))
    }
    
    func pause() {}
    
    var contentMode: UIView.ContentMode { return .redraw }
    
   
    var imageProviderHandler: (LiveImageProviderState) -> Void = { _ in }
    
    func changeSettings(_ change: SettingsChange, resultHandler: @escaping (Result<Settings, Error>) -> Void) {}
    
    func userManipulate(command: UserManipulation, resultHandler: @escaping (Result<Void, Error>) -> Void) {}
    
    struct MoqLiveImageProvider: LiveImageProvider {
        func start() {}
        
        var stateHandler: (LiveImageProviderState) -> Void = { _ in }
        
        func stop() {}
    }
}
