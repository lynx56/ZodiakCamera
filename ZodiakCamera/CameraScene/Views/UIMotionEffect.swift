//
//  NoConnectionView.swift
//  ZodiakCamera
//
//  Created by lynx on 31/01/2020.
//  Copyright © 2020 gulnaz. All rights reserved.
//

import UIKit

extension UIMotionEffect {
    static func parallax(withMinDistance min: CGFloat = -50, andMaxDistance max: CGFloat = 50) -> UIMotionEffect {
        let xMotion = UIInterpolatingMotionEffect(keyPath: "layer.transform.translation.x",
                                                  type: .tiltAlongHorizontalAxis)
        xMotion.minimumRelativeValue = min
        xMotion.maximumRelativeValue = max
        
        let yMotion = UIInterpolatingMotionEffect(keyPath: "layer.transform.translation.y",
                                                  type: .tiltAlongVerticalAxis)
        yMotion.minimumRelativeValue = min
        yMotion.maximumRelativeValue = max
        
        let motionEffectsGroup = UIMotionEffectGroup()
        motionEffectsGroup.motionEffects = [xMotion, yMotion]
        return motionEffectsGroup
    }
    
    static func verticalRotation(minAngle min: CGFloat = 315, maxAngle max: CGFloat = 45) -> UIMotionEffect {
        var identity = CATransform3DIdentity
        identity.m34 = -1/500
        
        let minimum = CATransform3DRotate(identity, min * .pi / 180, 1, 0, 0)
        let maximum = CATransform3DRotate(identity, max * .pi / 180, 1, 0, 0)
        
        let effect = UIInterpolatingMotionEffect(keyPath: "layer.transform", type: .tiltAlongVerticalAxis)
        effect.minimumRelativeValue = minimum
        effect.maximumRelativeValue = maximum
        
        return effect
    }
}
