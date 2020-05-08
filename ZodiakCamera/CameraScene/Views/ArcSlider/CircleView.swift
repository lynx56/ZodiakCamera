//
//  ArcSlider.swift
//  ZodiakCamera
//
//  Created by lynx on 18/10/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import UIKit

class RoundedView: UIView {
    var color: UIColor = .white {
        didSet {
            label.textColor = color
        }
    }
    
    var text: String = "" {
        didSet {
            label.text = text
            label.sizeToFit()
        }
    }
    
    var font: UIFont = .systemFont(ofSize: 12) {
        didSet {
            label.font = font
            setNeedsDisplay()
        }
    }
    
    var cornerRadius: CGFloat = 0 {
          didSet {
              layer.cornerRadius = cornerRadius
              setNeedsDisplay()
          }
      }
    
    private lazy var label: UILabel = {
        let label = UILabel()
        label.textColor = color
        label.font = font
        addSubview(label)
        return label
    }()
    
    override func layoutSubviews() {
        clipsToBounds = true
        layer.cornerRadius = cornerRadius
        label.center = .init(x: bounds.midX, y: bounds.midY)
        label.sizeToFit()
    }
    
    override var intrinsicContentSize: CGSize {
        return label.intrinsicContentSize.applying(.init(scaleX: 1.2, y: 1.2))
    }
}

class CircleView: RoundedView {
    struct Settings {
        let color: UIColor
        let font: UIFont
        
        static let initial = Settings(color: .white, font: .systemFont(ofSize: 12))
    }
    
    var settings: Settings = .initial {
        didSet {
            clipsToBounds = true
            color = settings.color
            font = settings.font
            setNeedsDisplay()
        }
    }
    
    override func layoutSubviews() {
        cornerRadius = bounds.width/2
        super.layoutSubviews()
    }
}
