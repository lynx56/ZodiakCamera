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

public class JoystickView: SKView {
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
        case start
    }
    
    private let joystickScene = JoystickScene()
    var moveHandler: (Event) -> Void = { _ in }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        backgroundColor = .white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        joystickScene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        joystickScene.handler = handleJoystickSceneEvent
        self.presentScene(joystickScene)
    }
    
    override public func layoutSubviews() {
        joystickScene.size = self.bounds.size
    }
    
    private func handleJoystickSceneEvent(_ event: JoystickScene.Event) {
        switch event {
        case .begin:
            moveHandler(.start)
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
