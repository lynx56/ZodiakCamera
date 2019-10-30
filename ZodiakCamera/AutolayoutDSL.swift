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

func constraint<Anchor>(_ keyPath: KeyPath<UIView, Anchor>,
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
        addSubview(child)
        child.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(constraints.map { $0(child, pairingView ?? self) })
    }
    
    func constrainToView(_ pairingView: UIView, constraints: [PairedConstraint]) {
        NSLayoutConstraint.activate(constraints.map { $0(self, pairingView) })
    }
    
    func constrain(to constraints: [UnpairedConstraint]) {
        NSLayoutConstraint.activate(constraints.map { $0(self) })
    }
}

extension Array where Element == PairedConstraint {
    static var pin: [PairedConstraint] {
        return [constraint(\.topAnchor, \.topAnchor),
                constraint(\.bottomAnchor, \.bottomAnchor),
                constraint(\.leadingAnchor, \.leadingAnchor),
                constraint(\.trailingAnchor, \.trailingAnchor)]
    }
}
