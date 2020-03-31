//
//  AuthViewController.swift
//  ZodiakCamera
//
//  Created by lynx on 31.03.2020.
//  Copyright © 2020 gulnaz. All rights reserved.
//

import UIKit

class AuthViewController: UIViewController {
    
    enum State {
        case signOut
        case signIn
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
    }
    
    func setupLayout() {
        
    }
}


class DotView: UIView {
    struct State {
        var isFilled: Bool
        var color: UIColor
    }
    
    override func layoutSubviews() {
        layer.cornerRadius = bounds.width/2
    }
    
    func render(state: State) {
        backgroundColor = state.isFilled ? state.color : nil
        layer.borderColor = state.color.cgColor
        layer.borderWidth = 1
    }
}

class NumberView: UIView {
    enum State {
        case numberAndLetters(Int, [String])
        case icon(String)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        layer.cornerRadius = bounds.width/2
    }
    
    func render(state: State) {
        self.subviews.forEach { $0.removeFromSuperview() }
        
        let blur = UIBlurEffect(style: .extraLight)
        let visualEffectView = UIVisualEffectView(effect: blur)
        addSubview(visualEffectView, constraints: .pin)
        
        switch state {
        case .icon(let imageName):
            let imageView = UIImageView(image: UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate))
            imageView.tintColor = .white
            self.addSubview(imageView, constraints: .pinWithOffset(11))
        case .numberAndLetters(let number, let letters):
            let numberLabel = UILabel()
            numberLabel.font = UIFont.systemFont(ofSize: 36)
            numberLabel.textAlignment = .center
            numberLabel.text = "\(number)"
            numberLabel.textColor = .white
            
            let lettersLabel = UILabel()
            lettersLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            lettersLabel.text = letters.joined(separator: " ").uppercased()
            lettersLabel.textColor = .white
            
            let stack = UIStackView(arrangedSubviews: [numberLabel, lettersLabel])
            stack.alignment = .center
            stack.axis = .vertical
            addSubview(stack, constraints: .pinWithOffsets(top: 11, bottom: 14, left: 25, right: 24))
        }
    }
}
