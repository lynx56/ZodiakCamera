//
//  PopupContainer.swift
//  ZodiakCamera
//
//  Created by lynx on 15/01/2020.
//  Copyright © 2020 gulnaz. All rights reserved.
//

import UIKit

class PopupContainer: UIViewController {
    private let rootViewController: UIViewController
    init(root: UIViewController) {
        rootViewController = root
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(rootViewController)
        rootViewController.view.frame = view.bounds
        view.addSubview(rootViewController.view, constraints: .pin)
        rootViewController.didMove(toParent: self)
    }
    
    private var animationCompleted: ()->Void = { }
    
    private func createPopup(withAnimations animations: CAAnimation...) -> UIView {
        let popup = PopupView()
        view.addSubview(popup, constraints: [
            constraint(\.widthAnchor, multiplier: 0.6),
            constraint(\.heightAnchor, multiplier: 0.28),
            constraint(\.centerXAnchor),
            constraint(\.centerYAnchor)
        ])
        popup.transform = CGAffineTransform(scaleX: 0, y: 0)
        let duration: CFTimeInterval = 0.8
        let fadeInOut = CABasicAnimation.fadeInOut(for: duration)
        let boundsAnimation = CABasicAnimation.transformToIdentity(for: duration/3)
        
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [fadeInOut, boundsAnimation] + animations
        animationGroup.duration = duration
        animationGroup.delegate = self
        popup.layer.add(animationGroup, forKey: nil)
        popup.transform = .identity
        return popup
    }
    
    private func showSuccessView(withTitle title: String) {
        let checkmarkView = CheckmarkView()
        
        let checkmarkAnimation = CABasicAnimation.strokeEnd
        checkmarkView.add(animation: checkmarkAnimation, forKey: nil)
        let popup = createPopup(withAnimations: checkmarkAnimation)
        
        let titleLabel = UILabel()
        titleLabel.textColor = .gray
        titleLabel.font = .systemFont(ofSize: 26, weight: .medium)
        titleLabel.text = title
        titleLabel.textAlignment = .center
        
        popup.addSubview(checkmarkView, constraints: [
            constraint(\.widthAnchor, multiplier: 0.5),
            constraint(\.centerXAnchor, constant: -8),
            constraint(\.centerYAnchor, constant: -11)])
        checkmarkView.constrain(to: constraint(\.heightAnchor, \.widthAnchor, multiplier: 0.45))
        
        popup.addSubview(titleLabel, constraints: [
            constraint(\.centerXAnchor),
            constraint(\.bottomAnchor, constant: -28)
        ])
        
        animationCompleted = { popup.removeFromSuperview() }
    }
    
    override func showSuccessPopup(_ sender: UIViewController, withTitle title: String) {
        let runPopupShow = { [unowned self] in self.showSuccessView(withTitle: title) }
        
        let senderWasPresented = sender.isBeingPresented || sender.presentingViewController != nil
        
        senderWasPresented ? sender.dismiss(animated: true, completion: runPopupShow) : runPopupShow()
    }
}


// MARK: - CAAnimationDelegate
extension PopupContainer: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            animationCompleted()
        }
    }
}

// MARK: - showSuccessPopup
extension UIViewController {
    @objc func showSuccessPopup(_ sender: UIViewController, withTitle title: String) {
        let action = #selector(PopupContainer.showSuccessPopup(_:withTitle:))
        let target = searchTargetInHierarchy(forAction: action,
                                             sender: self)
        target?.perform(action, with: sender, with: title)
    }
    
    func searchTargetInHierarchy(forAction action:Selector,
                                 sender: Any?) -> UIViewController? {
        var target: UIViewController? = self
        
        while (target != nil) {
            if let unwrappedTarget = target, unwrappedTarget.canPerformAction(action, withSender: sender)
                && unwrappedTarget.method(for: action) != UIViewController.instanceMethod(for: action) {
                return unwrappedTarget
            }
            
            target = target?.parent ?? target?.presentingViewController
        }
        return target
    }
}

// MARK: - Views
extension PopupContainer {
    class CheckmarkView: UIView {
        let shapelayer = CAShapeLayer()
        
        private var path: CGPath {
            let bezier = UIBezierPath()
            bezier.move(to: CGPoint(x: bounds.minX + bounds.width/4, y: bounds.midY))
            bezier.addLine(to: CGPoint(x: bounds.midX, y: bounds.maxY))
            bezier.addLine(to: CGPoint(x: bounds.maxX, y: bounds.minY))
            return bezier.cgPath
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            configure()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            configure()
        }
        
        override func layoutSubviews() {
            shapelayer.path = path
        }
        
        func configure(lineWidth: CGFloat = 11, color: UIColor = .gray) {
            shapelayer.path = path
            shapelayer.strokeColor = color.cgColor
            shapelayer.fillColor = nil
            shapelayer.lineWidth = lineWidth
            shapelayer.lineJoin = .round
            shapelayer.lineCap = .round
            layer.addSublayer(shapelayer)
        }
        
        func add(animation: CAAnimation, forKey key: String?) {
            shapelayer.add(animation, forKey: key)
        }
    }
    
    class PopupView: UIView {
        override init(frame: CGRect) {
            super.init(frame: frame)
            configure()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            configure()
        }
        
        func configure(color: UIColor = .darkGray, cornerRadius: CGFloat = 11) {
            backgroundColor = color
            let blur = UIBlurEffect(style: .extraLight)
            let effectView = UIVisualEffectView(effect: blur)
            addSubview(effectView, constraints: .pin)
            layer.cornerRadius = cornerRadius
            clipsToBounds = true
        }
    }
}

// MARK: - Animations
extension CAAnimation {
    static var strokeEnd: CABasicAnimation {
        let pathAnimation = CABasicAnimation(keyPath: "strokeEnd")
        pathAnimation.fromValue = NSNumber(floatLiteral: 0)
        pathAnimation.toValue = NSNumber(floatLiteral: 1)
        return pathAnimation
    }
    
    static func fadeInOut(for duration: CFTimeInterval) -> CABasicAnimation {
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = NSNumber(0)
        fade.toValue = NSNumber(1)
        fade.duration = duration/2
        fade.autoreverses = true
        return fade
    }
    
    static func transformToIdentity(for duration: CFTimeInterval) -> CABasicAnimation {
        let boundsAnimation = CABasicAnimation(keyPath: "transform")
        boundsAnimation.toValue = NSValue(cgAffineTransform: .identity)
        boundsAnimation.duration = duration
        return boundsAnimation
    }
}
