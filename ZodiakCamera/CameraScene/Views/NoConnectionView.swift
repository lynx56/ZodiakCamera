//
//  NoConnectionView.swift
//  ZodiakCamera
//
//  Created by lynx on 31/01/2020.
//  Copyright © 2020 gulnaz. All rights reserved.
//

import UIKit

class NoConnectionView: UIView {
    enum OutputEvent {
        case update
    }
    
    var handler: (OutputEvent) -> Void = { _ in }
    
    private let backgroundView = UIImageView(image: Images.sky.image)
    private let reloadButton = LoadingButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup(parallaxOffset: CGFloat = 50,
               font: UIFont = .systemFont(ofSize: 27, weight: .thin)) {
        backgroundView.contentMode = .scaleAspectFill
        addSubview(backgroundView, constraints: [
            constraint(\.leadingAnchor, constant: -parallaxOffset),
            constraint(\.trailingAnchor, constant: parallaxOffset),
            constraint(\.topAnchor, constant: -parallaxOffset),
            constraint(\.bottomAnchor, constant: parallaxOffset)
        ])
        
        let label = UILabel()
        label.font = font
        label.textColor = .yellow
        label.text = L10n.NoConnection.text
        
        reloadButton.render(model: .normal(icon: Images.restart.image))
        reloadButton.addTarget(self, action: #selector(update), for: .touchUpInside)
        reloadButton.tintColor = .white
        
        let contentSack = UIStackView(arrangedSubviews: [label, reloadButton])
        contentSack.axis = .vertical
        contentSack.spacing = 8
        
        let labelBackView = UIView()
        labelBackView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        addSubview(labelBackView, constraints: [
            constraint(\.centerYAnchor),
            constraint(\.leadingAnchor),
            constraint(\.trailingAnchor)
        ])
        
        labelBackView.addSubview(contentSack, constraints: [
            constraint(\.centerXAnchor),
            constraint(\.centerYAnchor)
        ])
        
        labelBackView.constrainToView(contentSack, constraints: [
            constraint(\.heightAnchor, multiplier: 1.5)
        ])
        
        backgroundView.addMotionEffect(UIMotionEffect.parallax(withMinDistance: -parallaxOffset,
                                                               andMaxDistance: parallaxOffset))
        
        label.addMotionEffect(UIMotionEffect.verticalRotation())
    }
    
    @objc private func update(_ sender: UIButton?) {
        handler(.update)
        reloadButton.render(model: .loading)
    }
    
    func reset() {
        reloadButton.render(model: .normal(icon: Images.restart.image))
    }
}

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
