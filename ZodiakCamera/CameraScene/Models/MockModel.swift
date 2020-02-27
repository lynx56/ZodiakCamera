//
//  MockModel.swift
//  ZodiakCamera
//
//  Created by lynx on 06/11/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import Foundation

class MockModel: ZodiakProvider {
    func chageSettings(_ change: Settings.Change, handler: @escaping (Result<Settings, Error>) -> Void) {
        let (param, value) = change.urlParameters
        print("chageSettings(param: \(param), value: \(value)")
    }
    
    var liveStreamUrl: URL { fatalError("mock") }
    
    var snapshotUrl: URL { fatalError("mock") }
    
    func userManipulate(_ command: UserManipulation, handler: @escaping (Result<Void, Error>) -> Void) {
        userManipulate(command)
    }
    
    func userManipulate(_ command: UserManipulation) {
        print("userManipulate(command: \(command)")
    }
}
