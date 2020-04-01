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

class PinView: UIView {
    struct State {
        var title: String
        var icon: String
    }
    
    enum OutputEvent {
        case numberTapped(Int)
        case backspaceTapped
        case biometricTapped
    }
    
    var outputHandler: (OutputEvent)->Void = { _ in }
    private let backspaceImageName = Images.backspace.name
    private let biometricImageNames = (touchId: Images.touchId.name, faceId: Images.faceId.name)
    
    func layout() {
        let titleLabel = UILabel()
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textAlignment = .center
        
        let dots = [DotView(), DotView(), DotView(), DotView()]
        dots.forEach {
            $0.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            $0.constrainToView($0, constraints: .aspectRatio(1))
        }
        
        let dotsStack = UIStackView(arrangedSubviews: dots)
        var numbers: [[NumberView]] =
            [[.init(state: .numberAndLetters(1, [])),
             .init(state: .numberAndLetters(2, ["A", "B", "C"])),
             .init(state: .numberAndLetters(3, ["D", "E", "F"]))],
             [.init(state: .numberAndLetters(4, ["G", "H", "I"])),
             .init(state: .numberAndLetters(5, ["J", "K", "L"])),
             .init(state: .numberAndLetters(6, ["M", "N", "O"]))],
             [.init(state: .numberAndLetters(7, ["P", "Q", "R", "S"])),
             .init(state: .numberAndLetters(8, ["T", "U", "V"])),
             .init(state: .numberAndLetters(9, ["W", "X", "Y", "Z"]))],
             [.init(state: .icon(biometricImageNames.touchId)),
             .init(state: .numberAndLetters(0, [])),
             .init(state: .icon(backspaceImageName))]]
        
        let numbersPad = UIStackView()
        numbersPad.axis = .vertical
        numbersPad.spacing = 15
        for number in numbers {
            let stack = UIStackView(arrangedSubviews: number)
            stack.axis = .horizontal
            stack.distribution = .fillEqually
            stack.spacing = 18
       
            numbersPad.addArrangedSubview(stack)
        }
        
        numbers.flatMap { $0 }.forEach { $0.addTarget(self, action: #selector(numberTapped), for: .touchUpInside) }
        
        addSubview(numbersPad, constraints: [
            constraint(\.leadingAnchor, constraintRelation: .greaterThanOrEqual, constant: 47),
            constraint(\.trailingAnchor, constraintRelation: .lessThanOrEqual, constant: -47),
            constraint(\.centerXAnchor)
        ])
    }
    
    @objc
    func numberTapped(_ sender: NumberView) {
        guard let controlState = sender.currentState else { return }
        switch controlState {
        case .numberAndLetters(let number, _):
            outputHandler(.numberTapped(number))
        case .icon(let imageName):
            if imageName == backspaceImageName {
                outputHandler(.backspaceTapped)
            } else if imageName == biometricImageNames.faceId || imageName == biometricImageNames.touchId {
                outputHandler(.biometricTapped)
            } else {
                assertionFailure("Unknown image name in NumberControl")
            }
        }
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

class NumberView: UIControl {
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
    
    convenience init(state: State) {
        self.init(frame: .zero)
        render(state: state)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        sendActions(for: .touchDown)
        return true
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let touchPoint = touch.location(in: self)
        
        guard self.frame.contains(touchPoint) else {
            sendActions(for: .touchDragOutside)
            backgroundColor = backgroundColor?.withAlphaComponent(1)
            return true
        }
        backgroundColor = backgroundColor?.withAlphaComponent(0.5)
        sendActions(for: .touchDragInside)
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        backgroundColor = backgroundColor?.withAlphaComponent(1)
        
        guard let touchPoint = touch?.location(in: self), self.frame.contains(touchPoint) else {
            sendActions(for: .touchUpOutside)
            return
        }
        
        sendActions(for: .touchDragInside)
    }
    
    override func cancelTracking(with event: UIEvent?) {
        sendActions(for: .touchCancel)
    }
    
    private(set) var currentState: State?
    func render(state: State) {
        self.subviews.forEach { $0.removeFromSuperview() }
        addSubview(blur, constraints: .pin)
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
        
        currentState = state
    }
    
    private lazy var blur: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .extraLight)
        return UIVisualEffectView(effect: blur)
    }()
}
