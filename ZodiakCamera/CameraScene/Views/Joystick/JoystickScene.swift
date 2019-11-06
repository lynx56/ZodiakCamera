//
//  JoystickScene.swift
//  ZodiakCamera
//
//  Created by lynx on 16/10/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//
import Foundation
import SpriteKit

class JoystickScene: SKScene {
    private var joystick: TLAnalogJoystick?
    private var joystickHiddenArea = TLAnalogJoystickHiddenArea(rect: .zero)
    
    enum Event {
        case begin
        case move(CGFloat)
        case end
    }
    
    var handler: (Event) -> Void = { _ in }
    
    override func didChangeSize(_ oldSize: CGSize) {
        guard size != oldSize else {
            return
        }
        joystickHiddenArea.removeFromParent()
        joystickHiddenArea = TLAnalogJoystickHiddenArea(rect: frame)
        joystickHiddenArea.joystick = joystick
        addChild(joystickHiddenArea)
    }
    
    override func didMove(to view: SKView) {
        joystick = TLAnalogJoystick(withDiameter: 100)
        
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        backgroundColor = .clear
        joystick?.handleImage = UIImage(named: "stick")!
        joystick?.baseImage = UIImage(named: "substrate")!
        
        joystickHiddenArea.joystick = joystick
        addChild(joystickHiddenArea)

        joystick?.on(.begin) { [weak self] _ in
            self?.handler(.begin)
         }
        
        joystick!.on(.move) { [weak self] joystick in
            self?.handler(.move(joystick.angular))
        }
        
        joystick?.on(.end){ [weak self] _ in
            self?.handler(.end)
        }
    }
}
