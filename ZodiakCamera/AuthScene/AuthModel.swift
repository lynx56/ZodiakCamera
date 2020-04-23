//
//  Model.swift
//  ZodiakCamera
//
//  Created by Holyberry on 18.04.2020.
//  Copyright © 2020 gulnaz. All rights reserved.
//

import UIKit
import KeychainSwift

extension AuthViewController {
    struct ViewState {
        var title: String
        var filledNumbers: Int
        var biometricType: BiometricType
    }
    
    enum MyErrors: Error {
        case transitionNotFound
    }
    
    class AuthModel {
        private var bioMetricauthentificator: BioMetricAuthenticator
        private var pinStorage: PinStorage
        
        enum State {
            case idle
            case inProccess(title: String, pin: [Int])
            case finish
        }
        
        enum Event {
            case tapped(TapEvent)
            case start
            case authentificate
        }
        
        typealias Transition = () throws -> (State)
        
        init(bioMetricauthentificator: BioMetricAuthenticator = DefaultBioMetricAuthenticator(),
             pinStorage: PinStorage = KeychainSwift()) {
            self.bioMetricauthentificator = bioMetricauthentificator
            self.pinStorage = pinStorage
        }
        
        private var authTransition: Transition {
            return {
                var result: Result<Bool, BiometricAuthenticationError>?
                let semaphore = DispatchSemaphore(value: 0)
                DispatchQueue.global(qos: .userInitiated).sync {
                    let availableBiometricType = self.bioMetricauthentificator.availableType.rawValue
                    
                    self.bioMetricauthentificator.authenticate(reason: L10n.AuthViewController.reason(availableBiometricType, availableBiometricType),
                                                               fallbackTitle: nil,
                                                               cancelTitle: nil) {authResult in
                                                                result = authResult
                                                                semaphore.signal()
                    }
                }
                
                semaphore.wait()
                switch result {
                case .failure, .none:
                    return .inProccess(title: L10n.AuthViewController.enterPasscode, pin: [])
                case .success(let isAuthentificated):
                    if isAuthentificated {
                        return .finish
                    }
                    return .inProccess(title: L10n.AuthViewController.enterPasscode, pin: [])
                }
            }
        }
        
        func transitions(from state: AuthModel.State, forEvent event: Event) throws -> Transition {
            switch (state, event) {
            case (.idle, .start): return authTransition
            case (_, .authentificate): return authTransition
            case (.inProccess(let title, let pin), .tapped(let tapEvent)):
                return {
                    let changedPin = tapEvent.changePin(pin: pin)
                    
                    if changedPin.count < 4 {
                        return .inProccess(title: title, pin: changedPin)
                    }
                    
                    if changedPin.map({ String($0) }).joined() == self.pinStorage.pin {
                        return .finish
                    }
                    
                    return .inProccess(title: L10n.AuthViewController.wrongPasscode, pin: [])
                }
            default: throw MyErrors.transitionNotFound
            }
        }
        
        func transitionViewState(from oldState: State, to newState: State) -> ViewState? {
            switch (oldState, newState) {
            case (.inProccess(let title, let pin), .finish):
                return .init(title: title, filledNumbers: pin.count + 1, biometricType: bioMetricauthentificator.availableType)
            case (.inProccess(let title, let pin), .inProccess(_, let newpin)):
                return newpin.isEmpty ?
                 .init(title: title, filledNumbers: pin.count + 1, biometricType: bioMetricauthentificator.availableType) :
                 .init(title: title, filledNumbers: newpin.count, biometricType: bioMetricauthentificator.availableType)
            default: return nil
            }
        }
        
        func viewState(for state: State) -> ViewState? {
            switch state {
            case .finish: return nil
            case .idle: return .init(title: L10n.AuthViewController.enterPasscode, filledNumbers: 0, biometricType: bioMetricauthentificator.availableType)
            case .inProccess(let title, let pin): return .init(title: title, filledNumbers: pin.count, biometricType: bioMetricauthentificator.availableType)
            }
        }
    }
    
    class RegisterModel {
        enum State {
            case idle
            case inProccess(title: String, pin: [Int])
            case confirm(confirmPin: [Int], proccessPin: [Int])
            case finish
        }
        
        enum Event {
            case tapped(TapEvent)
            case start
        }
        
        private var pinStorage: PinStorage

        init(pinStorage: PinStorage = KeychainSwift()) {
            self.pinStorage = pinStorage
        }
        
        typealias Transition = () throws -> (State)
        
        func transitions(from state: State, forEvent event: Event) throws -> Transition {
            switch (state, event) {
            case (.idle, .start): return { return .inProccess(title: L10n.AuthViewController.enterPasscode, pin: []) }
            case (.inProccess(let title, let pin), .tapped(let tapEvent)):
                return {
                    let changedPin = tapEvent.changePin(pin: pin)
                    
                    if changedPin.count < 4 {
                        return .inProccess(title: title, pin: changedPin)
                    }
                    
                    return .confirm(confirmPin: changedPin, proccessPin: [])
                }
            case (.confirm(let confirmPin, let proccessPin), .tapped(let tapEvent)): return { [unowned self] in
                let changedPin = tapEvent.changePin(pin: proccessPin)
                
                if changedPin.count < 4 {
                    return .confirm(confirmPin: confirmPin, proccessPin: changedPin)
                }
                
                if changedPin == confirmPin {
                    self.pinStorage.pin = changedPin.map { String($0) }.joined()
                    return .finish
                }
                return .inProccess(title: L10n.AuthViewController.wrongPasscode, pin: [])
                }
            default: throw MyErrors.transitionNotFound
            }
        }
        
        func transitionViewState(from oldState: State, to newState: State) -> ViewState? {
            switch (oldState, newState) {
            case (.inProccess, .confirm(let confirmPin, _)):
                return .init(title: L10n.AuthViewController.confirmPasscode, filledNumbers: confirmPin.count, biometricType: .none)
            case (.confirm(_, let proccessPin), .inProccess(let title, _)):
                return .init(title: title, filledNumbers: proccessPin.count + 1, biometricType: .none)
            case (.confirm(let confirmedPin, _), .finish):
                return .init(title: L10n.AuthViewController.confirmPasscode, filledNumbers: confirmedPin.count, biometricType: .none)
            default: return nil
            }
        }
        
        func viewState(for state: State) -> ViewState? {
            switch state {
            case .confirm(_, let proccessPin):
                return .init(title: L10n.AuthViewController.confirmPasscode, filledNumbers: proccessPin.count, biometricType: .none)
            case .finish: return nil
            case .idle: return .init(title: L10n.AuthViewController.enterPasscode, filledNumbers: 0, biometricType: .none)
            case .inProccess(let title, let pin): return .init(title: title, filledNumbers: pin.count, biometricType: .none)
            }
        }
    }
    
    enum TapEvent {
        case number(Int)
        case delete
        
        func changePin(pin: [Int]) -> [Int] {
            var changingPin = pin
            switch self {
            case .number(let number):
                changingPin.append(number)
            case .delete:
                if changingPin.count > 0 {
                    changingPin.removeLast()
                }
            }
            
            return changingPin
        }
    }
    
    class Model: AuthViewControllerModel {
        enum Mode {
            case auth(AuthModel, AuthModel.State)
            case register(RegisterModel, RegisterModel.State)
        }
        
        var outputHandler: (OutputEvents) -> Void = { _ in } {
            didSet {
                var viewState: ViewState?
                switch mode {
                    case .auth(let model, let currentState): viewState = model.viewState(for: currentState)
                    case .register(let model, let currentState): viewState = model.viewState(for: currentState)
                }
                
                if let viewState = viewState {
                    outputHandler(.change(viewState))
                }
            }
        }
        
        init(mode: Mode) {
            self.mode = mode
        }
        
        private var mode: Mode
        
        static var authEventConverter: (Event) -> AuthModel.Event {
            return {
                switch $0 {
                case .authentificate:
                    return .authentificate
                case .start:
                    return .start
                case .tapped(let event):
                    return .tapped(event)
                }
            }
        }
        
        static var registerEventConverter: (Event) -> RegisterModel.Event? {
            return {
                switch  $0 {
                case .authentificate: return nil
                case .start: return .start
                case .tapped(let event): return .tapped(event)
                }
            }
        }
        
        func handle(_ event: Event) {
            switch mode {
            case .auth(let model, let currentState):
                let transition = try! model.transitions(from: currentState, forEvent: Model.authEventConverter(event))
                let newState = try! transition()
              
                if let transitionViewState = model.transitionViewState(from: currentState, to: newState) {
                    outputHandler(.change(transitionViewState))
                }
                
                if let newViewState = model.viewState(for: newState) {
                    outputHandler(.change(newViewState))
                }
                              
                mode = .auth(model, newState)
                if case .finish = newState {
                    outputHandler(.success)
                }
            case .register(let model, let currentState):
                guard let convertedEvent = Model.registerEventConverter(event) else { return }
                let transition = try! model.transitions(from: currentState, forEvent: convertedEvent)
                    
                let newState = try! transition()
            
                if let transitionViewState = model.transitionViewState(from: currentState, to: newState) {
                     outputHandler(.change(transitionViewState))
                }
                
                if let newViewState = model.viewState(for: newState) {
                    outputHandler(.change(newViewState))
                }
    
                mode = .register(model, newState)
                if case .finish = newState {
                    outputHandler(.success)
                }
            }
        }
    }
}

protocol AuthViewControllerModel {
    func handle(_ event: AuthViewController.Event)
    var outputHandler: (AuthViewController.OutputEvents) -> Void { get set }
}

extension AuthViewController {
    enum OutputEvents {
        case change(ViewState)
        case success
    }
    
    enum Event {
        case tapped(TapEvent)
        case start
        case authentificate
    }
}
