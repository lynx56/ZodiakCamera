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
        private var pin: [Int] = []
        
        enum State {
            case idle
            case inProccess(String)
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
                DispatchQueue.global(qos: .userInitiated).sync {
                    let availableBiometricType = self.bioMetricauthentificator.availableType.rawValue
                    
                    self.bioMetricauthentificator.authenticate(reason: L10n.AuthViewController.reason(availableBiometricType, availableBiometricType),
                                                               fallbackTitle: nil,
                                                               cancelTitle: nil) {authResult in
                                                                result = authResult
                    }
                }
                
                switch result {
                case .failure, .none:
                    return .inProccess(L10n.AuthViewController.enterPasscode)
                case .success(let isAuthentificated):
                    return isAuthentificated ? .finish : .inProccess(L10n.AuthViewController.enterPasscode)
                }
            }
        }
        
        func transitions(from state: AuthModel.State, forEvent event: Event) throws -> Transition {
            switch (state, event) {
            case (.idle, .start): return authTransition
            case (_, .authentificate): return authTransition
            case (.inProccess(let title), .tapped(let tapEvent)):
                return {
                    self.pin = tapEvent.changePin(pin: self.pin)
                    
                    if self.pin.count < 4 {
                        return .inProccess(title)
                    }
                    
                    if self.pin.map({ String($0) }).joined() == self.pinStorage.pin {
                        return .finish
                    }
                    return .inProccess(L10n.AuthViewController.wrongPasscode)
                }
            default: throw MyErrors.transitionNotFound
            }
        }
        
        func viewState(for state: State) -> ViewState? {
            switch state {
            case .finish: return nil
            case .idle: return .init(title: L10n.AuthViewController.enterPasscode, filledNumbers: 0, biometricType: bioMetricauthentificator.availableType)
            case .inProccess(let title): return .init(title: title, filledNumbers: self.pin.count, biometricType: bioMetricauthentificator.availableType)
            }
        }
    }
    
    class RegisterModel {
        enum State {
            case idle
            case inProccess(String)
            case confirm(pin: [Int])
            case finish
        }
        
        enum Event {
            case tapped(TapEvent)
            case start
        }
        
        private var pinStorage: PinStorage
        private var pin: [Int] = []
        
        init(pinStorage: PinStorage = KeychainSwift()) {
            self.pinStorage = pinStorage
        }
        
        typealias Transition = () throws -> (State)
        typealias PostAction = ()->Void
        
        func prepare(oldState: State, newState: State) {
            switch (oldState, newState) {
                case (.inProccess, .confirm):  self.pin.removeAll()
                case (.confirm, .inProccess): self.pin.removeAll()
                default : return
            }
        }
        
        func transitions(from state: State, forEvent event: Event) throws -> Transition {
            switch (state, event) {
            case (.idle, .start): return { return .inProccess(L10n.AuthViewController.enterPasscode) }
            case (.inProccess(let title), .tapped(let tapEvent)):
                return {
                    self.pin = tapEvent.changePin(pin: self.pin)
                    
                    if self.pin.count < 4 {
                        return .inProccess(title)
                    }
                    let pin = self.pin
                    return .confirm(pin: pin)
                }
            case (.confirm(let pin), .tapped(let tapEvent)): return { [unowned self] in
                self.pin = tapEvent.changePin(pin: self.pin)
                
                if self.pin.count < 4 {
                    return .confirm(pin: pin)
                }
                
                if pin == self.pin {
                    self.pinStorage.pin = self.pin.map { String($0) }.joined()
                    return .finish
                }
                
                return .inProccess(L10n.AuthViewController.wrongPasscode)
                }
            default: throw MyErrors.transitionNotFound
            }
        }
        
        func viewState(from state: State) -> ViewState? {
            switch state {
            case .confirm: return .init(title: L10n.AuthViewController.confirmPasscode, filledNumbers: self.pin.count, biometricType: .none)
            case .finish: return nil
            case .idle: return .init(title: L10n.AuthViewController.enterPasscode, filledNumbers: self.pin.count, biometricType: .none)
            case .inProccess(let title): return .init(title: title, filledNumbers: self.pin.count, biometricType: .none)
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
    
    class Model {
        enum Mode {
            case auth(AuthModel, AuthModel.State)
            case register(RegisterModel, RegisterModel.State)
        }
        
        enum OutputEvents {
            case change(ViewState)
            case success
        }
        
        enum Event {
            case tapped(TapEvent)
            case start
            case authentificate
        }
        
        var outputHandler: (OutputEvents) -> Void = { _ in }
        
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
            
                if let newViewState = model.viewState(from: newState) {
                    outputHandler(.change(newViewState))
                }
                
                model.prepare(oldState: currentState, newState: newState)
                
                mode = .register(model, newState)
                if case .finish = newState {
                    outputHandler(.success)
                }
            }
        }
    }
}
