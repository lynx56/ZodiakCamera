//
//  File.swift
//  ZodiakCamera
//
//  Created by lynx on 02/12/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import UIKit

class IPCameraViewBySnapshots: UIView, Observable {
    private let imageView: UIImageView
    private let imageProvider: ()->URL
    private var displaylink: CADisplayLink?
    
    override func didMoveToSuperview() {
        createDisplayLink()
    }
    
    override func removeFromSuperview() {
        displaylink?.remove(from: .current, forMode: .default)
    }
    
    init(frame: CGRect, imageProvider: @escaping ()->URL) {
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
    
    var stateHandler: (State)->Void =  { _ in }
    
    enum State {
        case active
        case error
    }
    
    @objc private func update(displaylink: CADisplayLink) {
        guard let data = try? Data(contentsOf: imageProvider()) else { stateHandler(.error); return }
        imageView.image = UIImage(data: data)?.resizeWithScaleAspectFitMode(to: UIScreen.main.bounds.size)
        stateHandler(.active)
    }
}

protocol Observable {
    associatedtype State
    var stateHandler: (State)->Void { get set }
}

class IPCameraViewBySnapshotsController: UIViewController {
    private let imageView = UIImageView()
    private let imageProvider: ()->Data?
    private var displaylink: CADisplayLink?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        createDisplayLink()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        displaylink?.remove(from: .current, forMode: .default)
    }
    
    init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?, imageProvider: @escaping ()->Data?) {
        self.imageProvider = imageProvider
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(imageView, constraints: .pin)
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
        imageView.image = UIImage(data: data)?.resizeWithScaleAspectFitMode(to: view.bounds.size)
    }
}
