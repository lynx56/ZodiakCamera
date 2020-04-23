//
//  PinStorage.swift
//  ZodiakCamera
//
//  Created by Holyberry on 18.04.2020.
//  Copyright © 2020 gulnaz. All rights reserved.
//

import KeychainSwift

protocol PinStorage: class {
    var pin: String? { set get }
    var authEnabled: Bool { get }
}

extension KeychainSwift: PinStorage {
    var authEnabled: Bool {
        get {
            return pin != nil && !pin!.isEmpty
        }
    }
    
    static let pinKey = "Auth.Passcode"
    var pin: String? {
        get {
            return get(KeychainSwift.pinKey)
        }
        set {
            guard let pin = newValue else { delete(KeychainSwift.pinKey); return }
            set(pin, forKey: KeychainSwift.pinKey)
        }
    }
}

