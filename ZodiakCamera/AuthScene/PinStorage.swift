//
//  PinStorage.swift
//  ZodiakCamera
//
//  Created by Holyberry on 18.04.2020.
//  Copyright © 2020 gulnaz. All rights reserved.
//

import KeychainSwift

protocol PinStorage {
    var pin: String? { set get }
}

extension KeychainSwift: PinStorage {
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

