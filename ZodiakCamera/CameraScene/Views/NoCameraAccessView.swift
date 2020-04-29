//
//  NoConnectionView.swift
//  ZodiakCamera
//
//  Created by lynx on 31/01/2020.
//  Copyright © 2020 gulnaz. All rights reserved.
//

import UIKit

class NoCameraAccessView: UIView {
    private let reloadButton = LoadingButton()
    private let cameraImage = UIImageView()
    private let title = UILabel()
    private let warning = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    enum OutputEvent {
        case update
    }
    
    struct State {
        var title: String
        var description: String
        var iconName: String
    }
    
    var handler: (OutputEvent) -> Void = { _ in }
      
    func setup(parallaxOffset: CGFloat = 50,
               font: UIFont = .systemFont(ofSize: 27, weight: .thin)) {
        title.font = UIFont(name: "SFProRounded-Semibold", size: 18)
        title.setContentCompressionResistancePriority(.required, for: .vertical)
        title.numberOfLines = 0
        title.setContentHuggingPriority(.defaultLow, for: .vertical)
        title.textAlignment = .center
        title.textColor = UIColor(red: 0.454, green: 0.454, blue: 0.465, alpha: 1)
      
        warning.setContentCompressionResistancePriority(.required, for: .vertical)
        warning.numberOfLines = 0
        warning.textAlignment = .center
        warning.setContentCompressionResistancePriority(.required, for: .vertical)
        warning.textColor = UIColor(red: 0.557, green: 0.557, blue: 0.576, alpha: 1)
        warning.font = UIFont(name: "SFCompactRounded-Regular", size: 14)
        
        cameraImage.contentMode = .scaleAspectFit
        cameraImage.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        cameraImage.setContentHuggingPriority(.required, for: .vertical)
        
        let stack = UIStackView(arrangedSubviews: [cameraImage, title, warning, reloadButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 7
        addSubview(stack, constraints: [
            constraint(\.leadingAnchor, constant: 68),
            constraint(\.trailingAnchor, constant: -68),
            constraint(\.centerYAnchor)
        ])
        
        stack.constrain(to: uconstraint(\.heightAnchor, constant: 238))
   
        reloadButton.render(model: .normal(icon: nil, title: ""))
        reloadButton.addTarget(self, action: #selector(update), for: .touchUpInside)
        reloadButton.tintColor = .white
        
    }
    
    @objc private func update(_ sender: UIButton?) {
        handler(.update)
        reloadButton.render(model: .loading)
    }
    
    func render(state: State) {
        title.text = state.title
        warning.text = state.description
        cameraImage.image = UIImage(named: state.iconName)
    }
}
