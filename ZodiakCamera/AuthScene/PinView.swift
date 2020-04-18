//
//  PinView.swift
//  ZodiakCamera
//
//  Created by Holyberry on 18.04.2020.
//  Copyright © 2020 gulnaz. All rights reserved.
//

import UIKit

class PinView: UIView {
    struct State {
        var title: String
        var filledDotsCount: Int
        var biometricType: BiometricType
    }
    
    enum OutputEvent {
        case numberTapped(Int)
        case backspaceTapped
        case biometricTapped
    }
    
    var outputHandler: (OutputEvent)->Void = { _ in }
    private static let backspaceImageName = Images.backspace.name
    private static let biometricImageNames = (touchId: Images.touchId.name, faceId: Images.faceId.name)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let titleLabel = UILabel()
    private let dots = [DotView(), DotView(), DotView(), DotView()]
    private let biometricButton = NumberView(state: .icon(biometricImageNames.touchId))
    func setupLayout() {
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textAlignment = .center
        
        dots.forEach {
            $0.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            $0.constrainToView($0, constraints: .aspectRatio(1))
            $0.tintColor = .white
        }
        
        let dotsStack = UIStackView(arrangedSubviews: dots)
        dotsStack.spacing = 10
        let five = NumberView(state: .numberAndLetters(5, ["J", "K", "L"]))
        let numbers: [[NumberView]] =
            [[.init(state: .numberAndLetters(1, [" "])),
             .init(state: .numberAndLetters(2, ["A", "B", "C"])),
             .init(state: .numberAndLetters(3, ["D", "E", "F"]))],
             [.init(state: .numberAndLetters(4, ["G", "H", "I"])),
              five,
             .init(state: .numberAndLetters(6, ["M", "N", "O"]))],
             [.init(state: .numberAndLetters(7, ["P", "Q", "R", "S"])),
             .init(state: .numberAndLetters(8, ["T", "U", "V"])),
             .init(state: .numberAndLetters(9, ["W", "X", "Y", "Z"]))],
             [biometricButton,
             .init(state: .numberAndLetters(0, [" "])),
             .init(state: .icon(PinView.backspaceImageName))]]
        
        let numbersPad = UIStackView()
        numbersPad.axis = .vertical
        numbersPad.spacing = 15
        numbersPad.distribution = .fillEqually
        for number in numbers {
            let stack = UIStackView(arrangedSubviews: number)
            stack.axis = .horizontal
            stack.distribution = .fillEqually
            stack.spacing = 28
       
            numbersPad.addArrangedSubview(stack)
        }
        
        addSubview(titleLabel, constraints: [
            constraint(\.topAnchor),
            constraint(\.leadingAnchor),
            constraint(\.trailingAnchor)
        ])

        addSubview(dotsStack, constraints:  [
            constraint(\.centerXAnchor)
        ])
        
        dotsStack.constrainToView(titleLabel, constraints: [
            constraint(\.topAnchor, \.bottomAnchor, constant: 18)
        ])
               
        addSubview(numbersPad, constraints: [
            constraint(\.leadingAnchor),
            constraint(\.trailingAnchor),
            constraint(\.bottomAnchor)
        ])
        
        numbersPad.constrainToView(dotsStack, constraints: [
            constraint(\.topAnchor, \.bottomAnchor, constant: 47)
        ])
        
        numbersPad.constrainToView(numbersPad, constraints: .aspectRatio(281/345))
        
        numbers.flatMap { $0 }.forEach {
            $0.addTarget(self, action: #selector(numberTapped), for: .touchUpInside)
            $0.isUserInteractionEnabled = true
            $0.setContentHuggingPriority(.required, for: .horizontal)
            $0.setContentHuggingPriority(.required, for: .vertical)
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
            $0.setContentCompressionResistancePriority(.required, for: .vertical)
        }
    }
    
    @objc
    func numberTapped(_ sender: NumberView) {
        guard let controlState = sender.currentState else { return }
        switch controlState {
        case .numberAndLetters(let number, _):
            outputHandler(.numberTapped(number))
        case .icon(let imageName):
            if imageName == PinView.backspaceImageName {
                outputHandler(.backspaceTapped)
            } else if imageName == PinView.biometricImageNames.faceId || imageName == PinView.biometricImageNames.touchId {
                outputHandler(.biometricTapped)
            }
        case .empty:
            break
        }
    }
    
    func render(_ state: State) {
        DispatchQueue.main.async {
            self.titleLabel.text = state.title
            
            switch state.biometricType {
            case .faceId:
                self.biometricButton.render(state: .icon(PinView.biometricImageNames.faceId))
            case .none:
                self.biometricButton.render(state: .empty)
            case .touchId:
                self.biometricButton.render(state: .icon(PinView.biometricImageNames.touchId))
            }
            
            for dot in self.dots.enumerated() {
                dot.element.render(state: .init(isFilled: dot.offset < state.filledDotsCount))
            }
        }
    }
}
