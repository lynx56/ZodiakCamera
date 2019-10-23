//
//  JoystickScene.swift
//  ZodiakCamera
//
//  Created by lynx on 16/10/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//
import Foundation
import UIKit
import SpriteKit

class JoystickView: SKView {
    enum MoveDirection: Int {
        case up
        case upleft
        case left
        case downleft
        case down
        case right
        case downright
        case upright
    }
    
    enum Event {
        case move(MoveDirection)
        case stop
    }
    
    private let joystickScene = JoystickScene()
    var moveHandler: (Event) -> Void = { _ in }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        joystickScene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        joystickScene.handler = handleJoystickSceneEvent
        self.presentScene(joystickScene)
    }
    
    override func layoutSubviews() {
        joystickScene.size = self.bounds.size
    }
    
    private func handleJoystickSceneEvent(_ event: JoystickScene.Event) {
        switch event {
        case .begin: break
        case .end:
            moveHandler(.stop)
        case .move(let angle):
            let pi = CGFloat(Double.pi)
            let angles = [0, pi/4, pi/2, 3*pi/4, pi]
            let result = [MoveDirection.up, .upleft, .left, .downleft, .down]
            let mirrorResult = [MoveDirection.up, .upright, .right, .downright, .down]
            
            var min = 0
            for i in 1..<angles.count {
                if abs(angles[i]-abs(angle)) < abs(angles[min]-abs(angle)) {
                    min = i
                }
            }
            
            let moveDirection = angle < 0 ? mirrorResult[min] : result[min]
            moveHandler(.move(moveDirection))
        }
    }
}

class JoystickScene: SKScene {
    private var joystick: TLAnalogJoystick?
    
    override var size: CGSize {
        didSet {
            joystick?.diameter = min(size.width, size.height)/1.5
        }
    }
    
    enum Event {
        case begin
        case move(CGFloat)
        case end
    }
    
    var handler: (Event) -> Void = { _ in }
    
    override func didMove(to view: SKView) {
        joystick = TLAnalogJoystick(withDiameter: 50)
        
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        backgroundColor = .clear
        joystick?.handleImage = UIImage(named: "stick")!
        joystick?.baseImage = UIImage(named: "substrate")!
        
        addChild(joystick!)
 
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
