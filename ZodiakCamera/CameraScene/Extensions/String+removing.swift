//
//  Exs.swift
//  ZodiakCamera
//
//  Created by lynx on 06/11/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import Foundation

extension String {
    func removingAllWhitespaces() -> String {
        return removingCharacters(from: .whitespacesAndNewlines)
    }
    
    func removingCharacters(from set: CharacterSet) -> String {
        var newString = self
        newString.removeAll { char -> Bool in
            guard let scalar = char.unicodeScalars.first else { return false }
            return set.contains(scalar)
        }
        return newString
    }
}
