//
//  MockModel.swift
//  ZodiakCamera
//
//  Created by lynx on 06/11/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import Foundation

class MockModel: ZodiakProvider, PanelDataProvider {
    var contrast: LimitValue = .initial {
        didSet {
            chageSettings(param: "contrast", value: String(contrast.currentValue))
        }
    }
    var brightness: LimitValue = .initial{
        didSet {
            chageSettings(param: "brightness", value: String(brightness.currentValue))
        }
    }
    var saturation: LimitValue = .initial{
        didSet {
            chageSettings(param: "saturation", value: String(saturation.currentValue))
        }
    }
    var ir: Bool = false{
        didSet {
            chageSettings(param: "ir", value: String(ir))
        }
    }
    
    func image() -> Data? {
        return nil
    }
    func chageSettings(param: String, value: String) {
        print("chageSettings(param: \(param), value: \(value)")
    }
    
    func userManipulate(_ command: UserManipulation) {
        print("userManipulate(command: \(command)")
    }
}
