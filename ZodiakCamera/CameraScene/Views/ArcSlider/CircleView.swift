//
//  ArcSlider.swift
//  ZodiakCamera
//
//  Created by lynx on 18/10/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import UIKit

class CircleView: UIView {
    struct Settings {
        let color: UIColor
        let font: UIFont
        
        static let initial = Settings(color: .white, font: .systemFont(ofSize: 12))
    }
    
    private lazy var label: UILabel = {
        let label = UILabel()
        addSubview(label)
        return label
    }()
    
    var text: String = "" {
        didSet {
            label.text = text
            label.sizeToFit()
        }
    }
    
    var settings: Settings = .initial {
        didSet {
            clipsToBounds = true
            label.textColor = settings.color
            label.font = settings.font
            setNeedsDisplay()
        }
    }
    
    override func layoutSubviews() {
        layer.cornerRadius = bounds.width/2
        label.center = .init(x: bounds.midX, y: bounds.midY)
        label.sizeToFit()
    }
}
