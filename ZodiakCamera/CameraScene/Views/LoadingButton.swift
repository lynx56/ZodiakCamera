//
//  LoadingButton.swift
//  Color Researcher
//
//  Created by lynx on 29/11/2019.
//  Copyright © 2019 Zerotech. All rights reserved.
//

import UIKit

class LoadingButton: UIButton {
    enum ViewModel {
        case normal(icon: UIImage?, title: String?)
        case loading
    }
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(frame: self.bounds)
        indicator.hidesWhenStopped = true
        indicator.color = UIColor.white
        return indicator
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        activityIndicator.frame = bounds
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(activityIndicator)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(model: ViewModel) {
        DispatchQueue.main.async { [unowned self] in
            switch model {
            case .normal(let icon, let title):
                self.activityIndicator.stopAnimating()
                self.isEnabled = true
                self.setImage(icon, for: .normal)
                self.setTitle(title, for: .normal)
            case .loading:
                self.isEnabled = false
                self.setImage(nil, for: .normal)
                self.setTitle(nil, for: .normal)
                self.activityIndicator.startAnimating()
            }
        }
    }
}
