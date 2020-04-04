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
    
    private let pinView = PinView()
    private var authentificator: BioMetricAuthenticator = DefaultBioMetricAuthenticator()
    
    func setupLayout() {
        view.addSubview(pinView, constraints: [
            constraint(\.leadingAnchor, constant: 47),
            constraint(\.trailingAnchor, constant: -47),
            constraint(\.topAnchor, constant: 152)
        ])
        pinView.outputHandler = handlePinViewEvent
        
        pinView.render(.init(title: pinTitle, filledDotsCount: pin.count, biometricType: .faceId))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.startPoint = .zero
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.colors = [UIColor(red:34.0/255.0, green:211/255.0, blue:198/255.0, alpha:1.0).cgColor,
                           UIColor(red:145/255.0, green:72.0/255.0, blue:203/255.0, alpha:1.0).cgColor]
            
        view.layer.insertSublayer(gradient, at: 0)
    }
    
    private var pin: [Int] = []
    private var pinTitle = "Enter a pin"
    func handlePinViewEvent(_ event: PinView.OutputEvent) {
        switch event {
        case .backspaceTapped:
            guard pin.count > 0 else { return }
            pin.remove(at: pin.count - 1)
            pinView.render(.init(title: pinTitle,
                                 filledDotsCount: pin.count,
                                 biometricType: .faceId))
        case .biometricTapped:
            let availableBiometricType = authentificator.availableBiometricType.rawValue
           
            authentificator.authenticateWithBioMetrics(reason: L10n.AuthViewController.reason(availableBiometricType, availableBiometricType),
                                                       fallbackTitle: nil,
                                                       cancelTitle: nil) { result in
                                                        print(result)
            }
            
        case .numberTapped(let number):
            guard pin.count < 4 else { return }
            pin.append(number)
            pinView.render(.init(title: pinTitle,
                                 filledDotsCount: pin.count,
                                 biometricType: .faceId))
            print(number)
        }
    }
}

class PinView: UIView {
    struct State {
        var title: String
        var filledDotsCount: Int
        var biometricType: BiometricType
        
        enum BiometricType {
            case none
            case faceId
            case touchId
        }
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
        }
    }
    
    func render(_ state: State) {
        titleLabel.text = state.title
        
        switch state.biometricType {
        case .faceId:
            biometricButton.render(state: .icon(PinView.biometricImageNames.faceId))
        case .none:
            biometricButton.render(state: .icon(""))
        case .touchId:
            biometricButton.render(state: .icon(PinView.biometricImageNames.touchId))
        }
        
        for dot in dots.enumerated() {
            dot.element.render(state: .init(isFilled: dot.offset < state.filledDotsCount))
        }
    }
}


class DotView: UIView {
    struct State {
        var isFilled: Bool
    }
    
    override func layoutSubviews() {
        layer.cornerRadius = bounds.width/2
    }
    
    func render(state: State) {
        backgroundColor = state.isFilled ? tintColor : nil
        layer.borderColor = tintColor.cgColor
        layer.borderWidth = 2
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 13, height: 13)
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
        addSubview(blur, constraints: .pin)
        self.backgroundColor = .clear
        switch state {
        case .icon(let imageName):
            let imageView = UIImageView(image: UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate))
            imageView.tintColor = .white
            imageView.contentMode = .scaleAspectFit
            self.addSubview(imageView, constraints: .pinWithOffset(25))
        case .numberAndLetters(let number, let letters):
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
        }
        
        currentState = state
    }
    
    private lazy var blur: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .light)
        return UIVisualEffectView(effect: blur)
    }()
}
