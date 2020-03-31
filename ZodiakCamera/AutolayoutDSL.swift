//
//  AutolayoutDSL.swift
//  Color Researcher
//
//  Created by lynx on 24/08/2019.
//  Copyright © 2019 Zerotech. All rights reserved.
//

import UIKit

typealias PairedConstraint = (_ view: UIView, _ otherView: UIView) -> NSLayoutConstraint
typealias UnpairedConstraint = (_ view: UIView) -> NSLayoutConstraint

enum ConstraintRelation {
    case equal, greaterThanOrEqual, lessThanOrEqual
}

func constraint<Anchor, AnchorType>(_ keyPath: KeyPath<UIView, Anchor>,
                                    _ otherKeyPath: KeyPath<UIView, Anchor>? = nil,
                                    constraintRelation: ConstraintRelation = .equal,
                                    multiplier: CGFloat? = nil,
                                    constant: CGFloat = 0,
                                    priority: UILayoutPriority = .required) -> PairedConstraint where Anchor: NSLayoutAnchor<AnchorType> {
    return { view, otherView in
        var partialConstraint: NSLayoutConstraint
        let otherKeyPath: KeyPath<UIView, Anchor> = otherKeyPath ?? keyPath
        
        switch constraintRelation {
        case .equal:
            partialConstraint = view[keyPath: keyPath].constraint(equalTo: otherView[keyPath: otherKeyPath], constant: constant)
        case .greaterThanOrEqual:
            partialConstraint = view[keyPath: keyPath].constraint(greaterThanOrEqualTo: otherView[keyPath: otherKeyPath], constant: constant)
        case .lessThanOrEqual:
            partialConstraint = view[keyPath: keyPath].constraint(lessThanOrEqualTo: otherView[keyPath: otherKeyPath], constant: constant)
        }
        
        return constraint(from: partialConstraint,
                          withMultiplier:multiplier,
                          priority: priority)
    }
}

func uconstraint<Anchor>(_ keyPath: KeyPath<UIView, Anchor>,
                         _ otherKeyPath: KeyPath<UIView, Anchor>,
                         constraintRelation: ConstraintRelation = .equal,
                         multiplier: CGFloat? = nil,
                         constant: CGFloat = 0,
                         priority: UILayoutPriority = .required) -> UnpairedConstraint where Anchor: NSLayoutDimension {
    guard keyPath != otherKeyPath else {
        return uconstraint(keyPath, constraintRelation: constraintRelation, multiplier: multiplier, constant: constant, priority: priority)
    }
    
    return { view in
        var partialConstraint: NSLayoutConstraint
        switch constraintRelation {
        case .equal:
            partialConstraint = view[keyPath: keyPath].constraint(equalTo: view[keyPath: otherKeyPath], multiplier: multiplier ?? 1, constant: constant)
        case .greaterThanOrEqual:
            partialConstraint = view[keyPath: keyPath].constraint(greaterThanOrEqualTo: view[keyPath: otherKeyPath], multiplier: multiplier ?? 1, constant: constant)
        case .lessThanOrEqual:
            partialConstraint = view[keyPath: keyPath].constraint(lessThanOrEqualTo: view[keyPath: otherKeyPath], multiplier: multiplier ?? 1, constant: constant)
        }
        
        return constraint(from: partialConstraint,
                          withMultiplier:multiplier,
                          priority: priority)
    }
}

func uconstraint<Anchor>(_ keyPath: KeyPath<UIView, Anchor>,
                         constraintRelation: ConstraintRelation = .equal,
                         multiplier: CGFloat? = nil,
                         constant: CGFloat = 0,
                         priority: UILayoutPriority = .required) -> UnpairedConstraint where Anchor: NSLayoutDimension {
    return { view in
        var partialConstraint: NSLayoutConstraint
        
        switch constraintRelation {
        case .equal:
            partialConstraint = view[keyPath: keyPath].constraint(equalToConstant: constant)
        case .greaterThanOrEqual:
            partialConstraint = view[keyPath: keyPath].constraint(greaterThanOrEqualToConstant: constant)
        case .lessThanOrEqual:
            partialConstraint = view[keyPath: keyPath].constraint(lessThanOrEqualToConstant: constant)
        }
        
        return constraint(from: partialConstraint,
                          withMultiplier:multiplier,
                          priority: priority)
    }
}

func constraint(from constraint: NSLayoutConstraint,
                withMultiplier multiplier: CGFloat? = nil,
                priority: UILayoutPriority) -> NSLayoutConstraint {
    var constraint = constraint
    if let multiplier = multiplier {
        constraint = NSLayoutConstraint(item: constraint.firstItem as Any,
                                        attribute: constraint.firstAttribute,
                                        relatedBy: constraint.relation,
                                        toItem: constraint.secondItem,
                                        attribute: constraint.secondAttribute,
                                        multiplier: multiplier,
                                        constant: constraint.constant)
    }
    constraint.priority = priority
    
    return constraint
}

extension UIView {
    func addSubview(_ child: UIView, pairingTo pairingView: UIView? = nil, constraints: [PairedConstraint]) {
        print(self.bounds)
            self.addSubview(child)
            child.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate(constraints.map { $0(child, pairingView ?? self) })
    }
    
    func insertSubview(_ child: UIView, pairingTo pairingView: UIView? = nil, at position: Int, constraints: [PairedConstraint]) {
        DispatchQueue.main.async {
            self.insertSubview(child, at: position)
           child.translatesAutoresizingMaskIntoConstraints = false
           NSLayoutConstraint.activate(constraints.map { $0(child, pairingView ?? self) })
        }
       }
    
    func insertSubview(_ view: UIView, aboveSubview siblingSubview: UIView, constraints: [PairedConstraint]) {
            self.insertSubview(view, aboveSubview: siblingSubview)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(constraints.map { $0(view, siblingSubview) })
    }
    
    func constrainToView(_ pairingView: UIView, constraints: [PairedConstraint]) {
            self.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate(constraints.map { $0(self, pairingView) })
    }
    
    func constrain(to constraints: UnpairedConstraint...) {
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(constraints.map { $0(self) })
    }
}

extension Array where Element == PairedConstraint {
    static var pin: [PairedConstraint] {
        return [constraint(\.topAnchor),
                constraint(\.bottomAnchor),
                constraint(\.leadingAnchor),
                constraint(\.trailingAnchor)]
    }
    
    static var pinWithoutPaddings: [PairedConstraint] {
        return [constraint(\.topAnchor, constant: -1),
                constraint(\.bottomAnchor, constant: 1),
                constraint(\.leadingAnchor, constant: -1),
                constraint(\.trailingAnchor, constant: 1)]
    }
    
    static func pinWithOffset(_ space: CGFloat) -> [PairedConstraint] {
        return [constraint(\.topAnchor, constant: -space),
                constraint(\.bottomAnchor, constant: space),
                constraint(\.leadingAnchor, constant: -space),
                constraint(\.trailingAnchor, constant: space)]
    }
    
    static func pinWithOffsets(top: CGFloat, bottom: CGFloat, left: CGFloat, right: CGFloat) -> [PairedConstraint] {
        return [constraint(\.topAnchor, constant: -top),
                constraint(\.bottomAnchor, constant: bottom),
                constraint(\.leadingAnchor, constant: -left),
                constraint(\.trailingAnchor, constant: right)]
    }
}
