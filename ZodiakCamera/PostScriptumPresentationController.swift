//
//  WindowContainerViewController.swift
//  ZodiakCamera
//
//  Created by lynx on 15/01/2020.
//  Copyright © 2020 gulnaz. All rights reserved.
//

import UIKit

class PostScriptimContainer: UIViewController {
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
    
    private func createPopup() -> UIView {
        let popup = UIView()
        popup.backgroundColor = .blue
        let blur = UIBlurEffect(style: .extraLight)
        let effectView = UIVisualEffectView(effect: blur)
        popup.addSubview(effectView, constraints: .pin)
        let size = CGSize(width: self.view.bounds.width*0.6, height: self.view.bounds.height*0.28)
        popup.frame = .init(x: self.view.bounds.midX - size.width/2, y: self.view.bounds.midY - size.height/2,
                            width: size.width, height: size.height)
        popup.layer.cornerRadius = 11
        popup.clipsToBounds = true
        return popup
    }
    
    private var popup = UIView()
    
    private func setupPopup(withAnimations animations: CAAnimation...) {
        let popupSize = popup.bounds.size
        popup.transform = CGAffineTransform(scaleX: 1/popupSize.width, y: 1/popupSize.height)
        
        self.view.addSubview(popup)
        popup.center = self.view.center
        
        let duration: CFTimeInterval = 1.2
        let fadeInOut = CABasicAnimation.fadeInOut(for: duration)
        let boundsAnimation = CABasicAnimation.transformToIdentity(for: duration/3)
        
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [fadeInOut, boundsAnimation] + animations
        animationGroup.duration = duration
        animationGroup.delegate = self
        popup.layer.add(animationGroup, forKey: "f")
        popup.transform = .identity
        popup.alpha = 0
    }
    
    private func setupSuccessSubview(withTitle title: String) {
        let checkmarkView = CheckmarkView()
        let titleLabel = UILabel()
        titleLabel.textColor = .gray
        titleLabel.font =  .systemFont(ofSize: 26, weight: .medium)
        titleLabel.text = title
        titleLabel.textAlignment = .center
        
        popup = createPopup()
        popup.addSubview(checkmarkView, constraints: [
            constraint(\.widthAnchor, multiplier: 0.5),
            constraint(\.centerXAnchor, constant: -8),
            constraint(\.centerYAnchor, constant: -11)])
        checkmarkView.constrain(to: constraint(\.heightAnchor, \.widthAnchor, multiplier: 0.45))
        
        popup.addSubview(titleLabel, constraints: [
            constraint(\.centerXAnchor),
            constraint(\.bottomAnchor, constant: -28)
        ])
        
        let checkmarkAnimation = CABasicAnimation.strokeEnd
        checkmarkView.shapelayer.add(checkmarkAnimation, forKey: nil)
        setupPopup(withAnimations: checkmarkAnimation)
    }
    
    override func showSuccessPopup(_ sender: UIViewController, withTitle title: String) {
        let runPopupShow = { [unowned self] in self.setupSuccessSubview(withTitle: title) }
        
        let senderWasPresented = sender.isBeingPresented || sender.presentingViewController != nil
        
        senderWasPresented ? sender.dismiss(animated: true, completion: runPopupShow) : runPopupShow()
    }
}

extension PostScriptimContainer: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        print("ended: \(anim.description)")
        if flag {
            popup.removeFromSuperview()
        }
    }
}

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


extension UIViewController {
    @objc func showSuccessPopup(_ sender: UIViewController, withTitle title: String) {
        let action = #selector(PostScriptimContainer.showSuccessPopup(_:withTitle:))
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
            
            let presenting = target?.presentingViewController
            target = target?.parent
            if target == nil {
                target = presenting
            }
        }
        return target
    }
}


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
}
