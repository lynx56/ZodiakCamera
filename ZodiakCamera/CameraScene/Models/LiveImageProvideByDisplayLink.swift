//
//  IPCameraView.swift
//  ZodiakCamera
//
//  Created by lynx on 02/12/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import UIKit

class LiveImageProvideByDisplayLink: LiveImageProvider {
    private let url: URL
    private var displaylink: CADisplayLink?
  
    init(url: URL) {
        self.url = url
    }
    
    func start() {
        createDisplayLink()
    }
    
    func stop() {
        displaylink?.remove(from: .current, forMode: .default)
    }
    
    private func createDisplayLink() {
        guard displaylink == nil else { return }
        
        displaylink = CADisplayLink(target: self,
                                    selector: #selector(update))
        
        displaylink?.add(to: .current,
                         forMode: .default)
    }
    
    var stateHandler: (LiveImageProviderState)->Void =  { _ in }
    
    @objc private func update(displaylink: CADisplayLink) {
        do {
            let data = try Data(contentsOf: url)
            let image = UIImage(data: data)?.resizeWithScaleAspectFitMode(to: UIScreen.main.bounds.size)
            stateHandler(.active(image))
        } catch {
            stateHandler(.error(.temprorary))
        }
    }
}
