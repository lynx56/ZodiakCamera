//
//  2.swift
//  ZodiakCamera
//
//  Created by lynx on 06/11/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import Foundation

extension Settings {
    init?(json: String) throws {
        let components =
            json
                .removingAllWhitespaces()
                .replacingOccurrences(of: "var", with: "")
                .components(separatedBy: ";")
                .filter { !$0.isEmpty }
        for component in components {
            let keyValue = component.components(separatedBy: "=")
            guard keyValue.count == 2 else { fatalError("Format is not supported") }
            if let key = keyValue.first?.removingAllWhitespaces(),
                let value = keyValue.last?.removingAllWhitespaces() {
                switch key {
                case "resolution": resolution = Int(value)!
                case "mode": mode = Int(value)!
                case "OSDEnable": OSDEnable = Int(value)! == 1
                case "sub_enc_framerate": subEncFramerate = Int(value)!
                case "vbright": brightness = .init(maxValue: 255, minValue: 0, currentValue: Int(value)!)
                case "vsaturation": saturation = .init(maxValue: 255, minValue: 0, currentValue: Int(value)!)
                case "enc_bitrate": bitrate = Int(value)!
                case "vhue": hue = .init(maxValue: 255, minValue: 0, currentValue: Int(value)!)
                case "flip": flip = Int(value)!
                case "ircut": ir = Int(value)! == 1
                case "speed": speed = Int(value)!
                case "enc_framerate": framerate = Int(value)!
                case "vcontrast": contrast = .init(maxValue: 255, minValue: 0, currentValue: Int(value)!)
                case "resolutionsub": resolutionSub = Int(value)!
                default: print("key not found: \(value)")
                }
            }
        }
    }
    
    func convert(for keyPath: KeyPath<Settings, LimitValue>) -> (parameter: String, value: String) {
          switch  keyPath{
          case \Settings.brightness:
              return ("1", String(self[keyPath: keyPath].currentValue))
          case \Settings.contrast:
              return ("2", String(self[keyPath: keyPath].currentValue))
          case \Settings.saturation:
              return ("8", String(self[keyPath: keyPath].currentValue))
          default:
              return ("", "")
          }
      }
    
    func convert(for keyPath: KeyPath<Settings, Bool>) -> (parameter: String, value: String) {
        switch  keyPath{
        case \Settings.ir:
            return ("14", String(self[keyPath: keyPath] == true ? 1 : 0))
        default:
            return ("", "")
        }
    }
}
