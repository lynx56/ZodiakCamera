//
//  DotView.swift
//  ZodiakCamera
//
//  Created by Holyberry on 18.04.2020.
//  Copyright © 2020 gulnaz. All rights reserved.
//

import UIKit

class DotView: UIView {
    struct State: Equatable {
        var isFilled: Bool
    }
    
    override func layoutSubviews() {
        layer.cornerRadius = bounds.width/2
    }
    
    private var currentState: State  = .init(isFilled: false)
    func render(state: State) {
        if state != currentState {
            UIView.animate(withDuration: 0.2) {
                self.backgroundColor = state.isFilled ? self.tintColor : nil
            }
        }
        layer.borderColor = tintColor.cgColor
        layer.borderWidth = 2
        currentState = state
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 13, height: 13)
    }
}
