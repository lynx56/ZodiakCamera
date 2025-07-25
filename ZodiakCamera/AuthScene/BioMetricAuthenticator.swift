//
//  BioMetricAuthenticator.swift
//  ZodiakCamera
//
//  Created by Holyberry on 04.04.2020.
//  Copyright © 2020 gulnaz. All rights reserved.
//

import Foundation
import LocalAuthentication

class DefaultBioMetricAuthenticator: BioMetricAuthenticator {
    var cacheLifeTime: TimeInterval? {
        didSet {
            allowableReuseDuration = cacheLifeTime
        }
    }
    
    private var context = LAContext()
    
    var availableType: BiometricType {
        var error: NSError?
        
        let canEvaluate = context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        guard canEvaluate else {
            return .none
        }
        
        switch context.biometryType {
        case .faceID:
            return .faceId
        case .touchID:
            return .touchId
        case .none:
            return .none
        @unknown default:
            assertionFailure("available new auth")
            return .none
        }
    }
    
    public var allowableReuseDuration: TimeInterval? = nil {
        didSet {
            guard let reuseDuration = allowableReuseDuration else { return }
            context.touchIDAuthenticationAllowableReuseDuration = reuseDuration
        }
    }
    
    func authenticate(reason: String,
                      fallbackTitle: String? = "",
                      cancelTitle: String? = "",
                      completion: @escaping (Result<Bool, BiometricAuthenticationError>) -> Void) {
        
        if allowableReuseDuration == nil {
            context = LAContext()
        }
        
        context.localizedFallbackTitle = fallbackTitle
        context.localizedCancelTitle = cancelTitle
       
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { (success, err) in
                if success {
                    completion(.success(true))
                }else {
                    let errorType = (err as! LAError).authenticationError
                    completion(.failure(errorType))
                }
        }
    }
}

extension LAError {
    var authenticationError: BiometricAuthenticationError {
        switch Int32(self.errorCode) {
        case kLAErrorAuthenticationFailed:
            return .failed
        case kLAErrorUserCancel:
            return .canceledByUser
        case kLAErrorUserFallback:
            return .fallback
        case kLAErrorSystemCancel:
            return .canceledBySystem
        case kLAErrorPasscodeNotSet:
            return .passcodeNotSet
        case kLAErrorBiometryNotAvailable:
            return .biometryNotAvailable
        case kLAErrorBiometryNotEnrolled:
            return .biometryNotEnrolled
        case kLAErrorBiometryLockout:
            return .biometryLockedout
        default:
            return .other
        }
    }
}

enum BiometricType: String {
    case faceId = "Face ID"
    case touchId = "Touch ID"
    case none = ""
}

public enum BiometricAuthenticationError: Error {
    case failed
    case canceledByUser
    case fallback
    case canceledBySystem
    case passcodeNotSet
    case biometryNotAvailable
    case biometryNotEnrolled
    case biometryLockedout
    case other
}

protocol BioMetricAuthenticator {
    var availableType: BiometricType { get }
    var cacheLifeTime: TimeInterval? { set get }
    func authenticate(reason: String,
                      fallbackTitle: String?,
                      cancelTitle: String?,
                      completion: @escaping (Result<Bool, BiometricAuthenticationError>) -> Void)
}
