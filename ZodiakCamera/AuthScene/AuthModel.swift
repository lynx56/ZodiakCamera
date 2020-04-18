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
        private var pin: [Int] = []
        private let mode: Mode
        var outputHandler: (OutputEvents) -> Void = { _ in }
        
        init(bioMetricauthentificator: BioMetricAuthenticator = DefaultBioMetricAuthenticator(),
             pinStorage: PinStorage = KeychainSwift(),
             mode: Mode) {
            self.bioMetricauthentificator = bioMetricauthentificator
            self.pinStorage = pinStorage
            self.mode = mode
            switch mode {
            case .auth:
                biometricType = bioMetricauthentificator.availableType
            case .new:
                biometricType = .none
            }
        }
    
        enum State {
            case idle
            case inProccess(String)
            case confirm(pin: [Int])
            case check(pin1: [Int], pin2: [Int])
            case finish
        }
        
        enum Event {
            enum TapEvent {
                case number(Int)
                case delete
            }
            case tapped(TapEvent)
            case start
            case authentificate
            case check
        }
        
        typealias Transition = () throws -> (State)
        typealias PreAction = () -> ()
        typealias PostAction = () -> ()
        
        private var biometricType: BiometricType = .none
        
        struct Context {
            var pin: [Int]
        }
        
        var currentState: State = .idle
        
        func preAction(old: State, new: State) {
            switch (old, new) {
            case (.inProccess, .confirm):
                self.pin.removeAll()
                self.outputHandler(.change(title: L10n.AuthViewController.confirmPasscode,
                                           filledNumbers: 0,
                                           biometricType: self.biometricType))
            case (.confirm, .inProccess):
                self.pin.removeAll()
                self.outputHandler(.change(title: L10n.AuthViewController.wrongPasscode,
                                           filledNumbers: self.pin.count,
                                           biometricType: self.biometricType))
            case (.confirm, .finish):
                self.outputHandler(.change(title: L10n.AuthViewController.confirmPasscode,
                                           filledNumbers: self.pin.count,
                                           biometricType: self.biometricType))
            default: return
            }
        }
        
        var authPostActions: (State) -> Void {
            return {   state in
                switch state {
                case .idle:
                    self.outputHandler(.change(title: L10n.AuthViewController.enterPasscode,
                                               filledNumbers: 0,
                                               biometricType: self.biometricType))
                case .inProccess(let title):
                    self.outputHandler(.change(title: title,
                                               filledNumbers: self.pin.count,
                                               biometricType: self.biometricType))
                case .confirm:
                    self.outputHandler(.change(title: L10n.AuthViewController.confirmPasscode,
                                               filledNumbers: self.pin.count,
                                               biometricType: self.biometricType))
                    
                default:
                    return
                }
            }
        }
        
        var authPreActions: (State) -> Void {
            return {   state in
                switch state {
                case .idle:
                    self.outputHandler(.change(title: L10n.AuthViewController.enterPasscode,
                                               filledNumbers: 0,
                                               biometricType: self.biometricType))
                case .inProccess(let title):
                    self.outputHandler(.change(title: title,
                                               filledNumbers: self.pin.count,
                                               biometricType: self.biometricType))
                case .confirm:
                    self.outputHandler(.change(title: L10n.AuthViewController.confirmPasscode,
                                               filledNumbers: self.pin.count,
                                               biometricType: self.biometricType))
                    
                default:
                    return
                }
            }
        }
        
        var preActions: (State) -> Void {
            return { state in
                switch state {
                case .finish:
                    self.pinStorage.pin = self.pin.map { String($0) }.joined()
                    self.outputHandler(.passcodeSaved)
                default:
                    return self.authPreActions(state)
                }
            }
        }
        
        func changePin(pin: [Int], by tapEvent: Event.TapEvent) -> [Int] {
            var changingPin = pin
            switch tapEvent {
            case .number(let number):
                changingPin.append(number)
            case .delete:
                if changingPin.count > 0 {
                    changingPin.removeLast()
                }
            }
            
            return changingPin
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
        
        private func inProcessTransitionLoop(title: String, tapEvent: Event.TapEvent, nextState: @escaping () -> State) -> Transition {
            return { [unowned self] in
                self.pin = self.changePin(pin: self.pin, by: tapEvent)
                
                if self.pin.count < 4 {
                    return .inProccess(title)
                }
                
                return nextState()
            }
        }
        
        private lazy var queue: OperationQueue = {
            let operationQueue = OperationQueue()
            operationQueue.qualityOfService = .userInitiated
            operationQueue.name = "AuthModelQueue"
            return operationQueue
        }()
       
        private func authTransitions(forEvent event: Event) throws -> Transition {
            switch (currentState, event) {
            case (.idle, .start): return authTransition
            case (_, .authentificate): return authTransition
            case (.inProccess(let title), .tapped(let tapEvent)):
                return inProcessTransitionLoop(title: title, tapEvent: tapEvent, nextState: {
                    if self.pin.map({ String($0) }).joined() == self.pinStorage.pin {
                        return .finish
                    }
                    return .inProccess(L10n.AuthViewController.wrongPasscode)
                })
            default: throw MyErrors.transitionNotFound
            }
        }
        
        private func transitions(forEvent event: Event) throws -> Transition {
            switch (currentState, event) {
            case (.idle, .start): return { return .inProccess(L10n.AuthViewController.enterPasscode) }
            case (.inProccess(let title), .tapped(let tapEvent)):
                return inProcessTransitionLoop(title: title, tapEvent: tapEvent, nextState: { .confirm(pin: self.pin) })
            case (.confirm(let pin), .tapped(let tapEvent)): return { [unowned self] in
                self.pin = self.changePin(pin: self.pin, by: tapEvent)
                
                if self.pin.count < 4 {
                    return .confirm(pin: pin)
                }
                
                if pin == self.pin {
                    return .finish
                }
                
                return .inProccess(L10n.AuthViewController.wrongPasscode)
            }
            default: throw MyErrors.transitionNotFound
         }
        }
        
        
        private var stateTransitions: (Event) throws -> Transition {
            switch mode {
            case .auth:
                return authTransitions
            case .new:
                return transitions
            }
        }
        
        var postPostActions: (State) -> Void {
            switch mode {
            case .auth:
                return authPreActions
            case .new:
                return preActions
            }
        }
        
        func handle(event: Event) throws {
                self.postPostActions(self.currentState)
                let transition = try! self.stateTransitions(event)
                self.currentState = try! transition()
        }
        
        enum MyErrors: Error {
            case transitionNotFound
        }
    }
}

