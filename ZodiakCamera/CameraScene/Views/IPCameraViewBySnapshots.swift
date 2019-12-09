//
//  File.swift
//  ZodiakCamera
//
//  Created by lynx on 02/12/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import UIKit

class IPCameraViewBySnapshots: UIView {
    private let imageView: UIImageView
    private let imageProvider: ()->Data?
    private var displaylink: CADisplayLink?
    
    override func didMoveToSuperview() {
        createDisplayLink()
    }
    
    override func removeFromSuperview() {
        displaylink?.remove(from: .current, forMode: .default)
    }
    
    init(frame: CGRect, imageProvider: @escaping ()->Data?) {
        self.imageProvider = imageProvider
        self.imageView = UIImageView(frame: frame)
        super.init(frame: frame)
        addSubview(imageView, constraints: .pin)
        imageView.contentMode = .redraw
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createDisplayLink() {
        guard displaylink == nil else { return }
        
        displaylink = CADisplayLink(target: self,
                                    selector: #selector(update))
        
        displaylink?.add(to: .current,
                         forMode: .default)
    }
    
    @objc private func update(displaylink: CADisplayLink) {
        guard let data = imageProvider() else { return }
        imageView.image = UIImage(data: data)?.resizeWithScaleAspectFitMode(to: UIScreen.main.bounds.size)
    }
}
