//
//  IPCameraView.swift
//  ZodiakCamera
//
//  Created by lynx on 02/12/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import UIKit

class IPCameraView: UIView, URLSessionDataDelegate {
    private var imageView: UIImageView
    private var endMarkerData: Data
    private var receivedData: Data
    private var dataTask: URLSessionDataTask
    private let urlProvider: ()->URL
    
    init(frame: CGRect, urlProvider: @escaping ()->URL) {
        self.endMarkerData = Data(bytes: [0xFF, 0xD9] as [UInt8], count: 2)
        self.receivedData = Data()
        self.imageView = UIImageView()
        self.dataTask = URLSessionDataTask()
        self.urlProvider = urlProvider
        super.init(frame: frame)
        self.addSubview(self.imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit{
        self.dataTask.cancel()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        print(urlProvider())
        startWithURL(url: urlProvider())
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        stop()
    }
    
    private func startWithURL(url: URL){
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let request = URLRequest(url: url)
        self.dataTask = session.dataTask(with: request as URLRequest)
        self.dataTask.resume()
        
        self.imageView.frame = self.bounds
        self.imageView.contentMode = UIView.ContentMode.scaleAspectFill
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.frame = self.bounds
    }
    
    private func pause() {
        self.dataTask.cancel()
    }
    
    private func stop(){
        self.pause()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.receivedData.append(data)
        
        guard let endRange = self.receivedData.range(of: self.endMarkerData,
                                                     options: [],
                                                     in: 0..<self.receivedData.count)
            else { return }
        let endLocation = endRange.startIndex + endRange.count
        
        if self.receivedData.count > endLocation {
            let imageData = self.receivedData.subdata(in: 0..<endLocation)
            let receivedImage = UIImage(data: imageData)
            
            DispatchQueue.main.async {
                self.imageView.image = receivedImage
            }
            
            self.receivedData = self.receivedData.subdata(in: endLocation..<self.receivedData.count)
            
        }
    }
}
