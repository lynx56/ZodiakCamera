//
//  NumberView.swift
//  ZodiakCamera
//
//  Created by Holyberry on 18.04.2020.
//  Copyright © 2020 gulnaz. All rights reserved.
//

import UIKit

class NumberView: UIControl {
    enum State {
        case numberAndLetters(Int, [String])
        case icon(String)
        case empty
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        layer.cornerRadius = bounds.height/2
        underlineLayer.frame = self.bounds
    }
    
    override var intrinsicContentSize: CGSize {
        return .init(width: 75, height: 75)
    }
    
    convenience init(state: State) {
        self.init(frame: .zero)
        render(state: state)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        underlineLayer.backgroundColor = UIColor.white.withAlphaComponent(0.3).cgColor
        underlineLayer.opacity = 0
        layer.addSublayer(underlineLayer)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.bounds.contains(point) {
            return self
        }
        
        return nil
    }
    
    private let underlineLayer = CALayer()
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        sendActions(for: .touchDown)
        underlineLayer.opacity = 1
        return true
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let touchPoint = touch.location(in: self)
        
        guard self.bounds.contains(touchPoint) else {
            sendActions(for: .touchDragOutside)
            underlineLayer.opacity = 0
            return true
        }
        
        underlineLayer.opacity = 1
        sendActions(for: .touchDragInside)
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        underlineLayer.opacity = 0
        guard let touchPoint = touch?.location(in: self), self.bounds.contains(touchPoint) else {
            sendActions(for: .touchUpOutside)
            return
        }
        
        sendActions(for: .touchDragInside)
    }
    
    override func cancelTracking(with event: UIEvent?) {
        sendActions(for: .touchCancel)
        underlineLayer.isHidden = true
    }
    
    private(set) var currentState: State?
    func render(state: State) {
        self.subviews.forEach { $0.removeFromSuperview() }
        self.backgroundColor = .clear
        switch state {
        case .empty:
            addSubview(UIImageView(), constraints: .pinWithOffset(25))
            isUserInteractionEnabled = false
        case .icon(let imageName):
            addSubview(blur, constraints: .pin)
            let imageView = UIImageView(image: UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate))
            imageView.tintColor = .white
            imageView.contentMode = .scaleAspectFit
            self.addSubview(imageView, constraints: .pinWithOffset(25))
            self.isUserInteractionEnabled = true
        case .numberAndLetters(let number, let letters):
            addSubview(blur, constraints: .pin)
            let numberLabel = UILabel()
            numberLabel.font = UIFont.systemFont(ofSize: 36)
            numberLabel.textAlignment = .center
            numberLabel.text = "\(number)"
            numberLabel.textColor = .white
            numberLabel.textAlignment = .center
            
            let lettersLabel = UILabel()
            lettersLabel.font = UIFont.systemFont(ofSize: 10)
            lettersLabel.text = letters.joined(separator: " ").uppercased()
            lettersLabel.textColor = .white
            lettersLabel.textAlignment = .center
            
            let stack = UIStackView(arrangedSubviews: [numberLabel, lettersLabel])
            stack.alignment = .center
            stack.axis = .vertical
            addSubview(stack, constraints: .pinWithOffsets(top: 10, bottom: 14, left: 0, right: 0))
            isUserInteractionEnabled = true
        }
        
        currentState = state
    }
    
    private lazy var blur: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .light)
        return UIVisualEffectView(effect: blur)
    }()
}
