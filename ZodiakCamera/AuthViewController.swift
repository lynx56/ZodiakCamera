//
//  AuthViewController.swift
//  ZodiakCamera
//
//  Created by lynx on 31.03.2020.
//  Copyright © 2020 gulnaz. All rights reserved.
//

import UIKit
import KeychainSwift

class AuthViewController: UIViewController {
    
    enum State: Equatable {
        case signOut
        case reenterPin([Int])
        case signIn
        case wrongPasscode
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
    }
    
    private let pinView = PinView()
    
    func setupLayout() {
        view.addSubview(pinView, constraints: [
            constraint(\.leadingAnchor, constant: 47),
            constraint(\.trailingAnchor, constant: -47),
            constraint(\.topAnchor, constant: 152)
        ])
        pinView.outputHandler = handlePinViewEvent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.startPoint = .zero
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.colors = [UIColor(red:34.0/255.0, green:211/255.0, blue:198/255.0, alpha:1.0).cgColor,
                           UIColor(red:145/255.0, green:72.0/255.0, blue:203/255.0, alpha:1.0).cgColor]
        
        view.layer.insertSublayer(gradient, at: 0)
        
        model.outputHandler = { event in
            switch event {
            case .change(let title, let filledNumbers, let biometricType):
                self.pinView.render(.init(title: title,
                                          filledDotsCount: filledNumbers,
                                          biometricType: biometricType))
            case .passcodeSaved: self.showSuccessPopup(self, withTitle: L10n.AuthViewController.passcodeSaved)
            }
        }
        
        try! model.handle(event: .start)
    }
    
    private var model = Model(mode:.new)
    
    private func handlePinViewEvent(_ event: PinView.OutputEvent) {
        switch event {
        case .backspaceTapped:
            try! model.handle(event: .tapped(.delete))
        case .biometricTapped:
            try! model.authentificate()
        case .numberTapped(let number):
            try! model.handle(event: .tapped(.number(number)))
        }
    }
}

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
        titleLabel.text = state.title
        
        switch state.biometricType {
        case .faceId:
            biometricButton.render(state: .icon(PinView.biometricImageNames.faceId))
        case .none:
            biometricButton.render(state: .empty)
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


protocol PinStorage {
    var pin: String? { set get }
}

extension KeychainSwift: PinStorage {
    static let pinKey = "Auth.Passcode"
    var pin: String? {
        get {
            return get(KeychainSwift.pinKey)
        }
        set {
            guard let pin = newValue else { delete(KeychainSwift.pinKey); return }
            set(pin, forKey: KeychainSwift.pinKey)
        }
    }
}



extension AuthViewController {
    class Model {
        enum OutputEvents {
            case change(title: String, filledNumbers: Int, biometricType: BiometricType)
            case passcodeSaved
        }
        
        enum Mode {
            case new
            case auth
        }
        
        private var bioMetricauthentificator: BioMetricAuthenticator
        private var pinStorage: PinStorage
        private var mode: Mode
        private var pin: [Int] = []
        
        var outputHandler: (OutputEvents) -> Void = { _ in }
        
        init(bioMetricauthentificator: BioMetricAuthenticator = DefaultBioMetricAuthenticator(),
             pinStorage: PinStorage = KeychainSwift(),
             mode: Mode = .new) {
            self.bioMetricauthentificator = bioMetricauthentificator
            self.pinStorage = pinStorage
            self.mode = mode
        }
        
        
        enum State {
            case idle
            case inProccess(String)
            case confirm(pin: [Int])
            case finish
        }
        
        enum Event {
            enum TapEvent {
                case number(Int)
                case delete
            }
            case tapped(TapEvent)
            case delete
            case start
        }
        
        typealias Transition = () throws -> (State)
        
        var currentState: State = .idle
        
        private var biometricType: BiometricType {
            guard mode == .auth else { return .none }
            return self.bioMetricauthentificator.availableType
        }
    
        func transitions(forEvent event: Event) throws -> Transition {
            switch (currentState, event) {
            case (.idle, .start): return {
                    self.outputHandler.self(.change(title: L10n.AuthViewController.enterPasscode,
                                                    filledNumbers: 0,
                                                    biometricType: self.biometricType))
                    return .inProccess(L10n.AuthViewController.enterPasscode)
                }
            case (.inProccess(let title), .tapped(let tapEvent)): return {
                switch tapEvent {
                case .number(let number):
                    self.pin.append(number)
                case .delete:
                    if self.pin.count > 0 {
                        self.pin.removeLast()
                    }
                }
                
                self.outputHandler(.change(title: title,
                                                filledNumbers: self.pin.count,
                                                biometricType: self.biometricType))
                if self.pin.count < 4 {
                    return .inProccess(title)
                }
                
                let pin = self.pin
                self.pin.removeAll()
                
                self.outputHandler(.change(title: L10n.AuthViewController.confirmPasscode,
                                                filledNumbers: 0,
                                                biometricType: self.biometricType))
                
                return .confirm(pin: pin)
            }
            case (.confirm(let pin), .tapped(let tapEvent)): return {
                switch tapEvent {
                case .number(let number):
                    self.pin.append(number)
                case .delete:
                    if pin.count > 0 {
                        self.pin.removeLast()
                    }
                }
                
                self.outputHandler.self(.change(title: L10n.AuthViewController.confirmPasscode,
                                                filledNumbers: self.pin.count,
                                                biometricType: self.biometricType))
                if self.pin.count < 4 {
                    return .confirm(pin: pin)
                }
                
                if pin == self.pin {
                    self.pinStorage.pin = pin.map { String($0) }.joined()
                    self.outputHandler(.passcodeSaved)
                    return .finish
                }
                
                self.pin = []
                self.outputHandler.self(.change(title: L10n.AuthViewController.wrongPasscode,
                                                filledNumbers: self.pin.count,
                                                biometricType: self.biometricType))
                return .inProccess(L10n.AuthViewController.wrongPasscode)
            }
            default: throw MyErrors.transitionNotFound
            }
        }
        
        func handle(event: Event) throws {
            let transition = try transitions(forEvent: event)
            currentState = try transition()
        }
        
        enum MyErrors: Error {
            case transitionNotFound
        }
        
        func authentificate() {
            guard mode == .new else { assertionFailure("Model in \(mode) mode can't authentificate"); return }
            
            let availableBiometricType = bioMetricauthentificator.availableType.rawValue
            
            bioMetricauthentificator.authenticate(reason: L10n.AuthViewController.reason(availableBiometricType, availableBiometricType),
                                                  fallbackTitle: nil,
                                                  cancelTitle: nil) { result in
                                                    print(result)
            }
        }
    }
}
