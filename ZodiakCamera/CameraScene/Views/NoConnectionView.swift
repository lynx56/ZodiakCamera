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
    
    func setup(parallaxOffset: CGFloat = 350,
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
        //todo: REMOVE
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 4) {
            self.reset()
        }
    }
    
    func reset() {
        reloadButton.render(model: .normal(icon: Images.restart.image))
    }
}
