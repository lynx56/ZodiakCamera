//
//  IPCameraView.swift
//  ZodiakCamera
//
//  Created by lynx on 02/12/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import UIKit
import Combine

class IPCameraView: UIView, URLSessionDataDelegate, Observable {
    private var imageView: UIImageView
    private var endMarkerData: Data
    private var receivedData: Data
    private var dataTask: URLSessionDataTask
    private let urlProvider: ()->URL
      
    init(frame: CGRect,
         urlProvider: @escaping ()->URL) {
        self.endMarkerData = Data(bytes: [0xFF, 0xD9] as [UInt8], count: 2)
        self.receivedData = Data()
        self.imageView = UIImageView()
        self.dataTask = URLSessionDataTask()
        self.urlProvider = urlProvider
        super.init(frame: frame)
        self.addSubview(self.imageView)
        self.imageView.contentMode = .scaleAspectFill
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit{
        self.dataTask.cancel()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
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
    
    var stateHandler: (State)->Void =  { _ in }
    
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
                self.stateHandler(.active)
                self.imageView.image = receivedImage
            }
            
            self.receivedData = self.receivedData.subdata(in: endLocation..<self.receivedData.count)
            
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let nsError = error as NSError?, let urlError = NSURLError(rawValue: nsError.code) else { return }
        stateHandler(.error(urlError))
    }
    
    enum State {
        case active
        case error(Error)
    }
    
    enum NSURLError: Int, Error {
        case unknown = -1
        case cancelled = -999
        case badURL = -1000
        case timedOut = -1001
        case unsupportedURL = -1002
        case cannotFindHost = -1003
        case cannotConnectToHost = -1004
        case connectionLost = -1005
        case lookupFailed = -1006
        case HTTPTooManyRedirects = -1007
        case resourceUnavailable = -1008
        case notConnectedToInternet = -1009
        case redirectToNonExistentLocation = -1010
        case badServerResponse = -1011
        case userCancelledAuthentication = -1012
        case userAuthenticationRequired = -1013
        
        case zeroByteResource = -1014
        case cannotDecodeRawData = -1015
        case cannotDecodeContentData = -1016
        case cannotParseResponse = -1017
        // SSL errors
        case secureConnectionFailed = -1200
        case serverCertificateHasBadDate = -1201
        case serverCertificateUntrusted = -1202
        case serverCertificateHasUnknownRoot = -1203
        case serverCertificateNotYetValid = -1204
        case clientCertificateRejected = -1205
        case clientCertificateRequired = -1206
        case cannotLoadFromNetwork = -2000
    }
}

class IPCameraViewController: UIViewController, URLSessionDataDelegate {
    private var imageView = UIImageView()
    private var endMarkerData = Data(bytes: [0xFF, 0xD9] as [UInt8], count: 2)
    private var receivedData = Data()
    private var dataTask = URLSessionDataTask()
    private let urlProvider: ()->URL
    
    init(nibName nibNameOrNil: String?,
         bundle nibBundleOrNil: Bundle?,
         urlProvider: @escaping ()->URL) {
        self.urlProvider = urlProvider
        self.endMarkerData = Data(bytes: [0xFF, 0xD9] as [UInt8], count: 2)
        self.imageView.contentMode = .scaleAspectFill
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit{
        self.dataTask.cancel()
    }
    
    override func viewDidLoad() {
        view.addSubview(imageView, constraints: .pin)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startWithURL(url: urlProvider())
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stop()
    }
   
    private func startWithURL(url: URL) {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let request = URLRequest(url: url)
        self.dataTask = session.dataTask(with: request as URLRequest)
        self.dataTask.resume()
    }
    
    private func pause() {
        self.dataTask.cancel()
    }
    
    private func stop(){
        self.pause()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let nsError = error as NSError?, let urlError = NSURLError(rawValue: nsError.code) else { return }
        render(state: .error(urlError))
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
            
            render(state: .active(receivedImage))
            
            self.receivedData = self.receivedData.subdata(in: endLocation..<self.receivedData.count)
        }
    }
    
    func render(state: State) {
        switch state {
        case .active(let receivedImage):
            DispatchQueue.main.async {
                self.imageView.image = receivedImage
            }
        case .error(let error):
            imageView.isHidden = true
            switch error {
            case .badServerResponse,
                 .badURL,
                 .cannotConnectToHost,
                 .cannotFindHost,
                 .serverCertificateHasBadDate,
                 .unsupportedURL,
                 .userAuthenticationRequired,
                 .userCancelledAuthentication:
                    self.view.addSubview(NoConnectionView(), constraints: .pin)
            default:
                print(error)
            }
        }
    }
    
    enum State {
        case active(UIImage?)
        case error(NSURLError)
    }
    
    enum NSURLError: Int, Error {
        case unknown = -1
        case cancelled = -999
        case badURL = -1000
        case timedOut = -1001
        case unsupportedURL = -1002
        case cannotFindHost = -1003
        case cannotConnectToHost = -1004
        case connectionLost = -1005
        case lookupFailed = -1006
        case HTTPTooManyRedirects = -1007
        case resourceUnavailable = -1008
        case notConnectedToInternet = -1009
        case redirectToNonExistentLocation = -1010
        case badServerResponse = -1011
        case userCancelledAuthentication = -1012
        case userAuthenticationRequired = -1013
        
        case zeroByteResource = -1014
        case cannotDecodeRawData = -1015
        case cannotDecodeContentData = -1016
        case cannotParseResponse = -1017
        // SSL errors
        case secureConnectionFailed = -1200
        case serverCertificateHasBadDate = -1201
        case serverCertificateUntrusted = -1202
        case serverCertificateHasUnknownRoot = -1203
        case serverCertificateNotYetValid = -1204
        case clientCertificateRejected = -1205
        case clientCertificateRequired = -1206
        case cannotLoadFromNetwork = -2000
    }
}


protocol LiveImageProvider {
    var stateHandler: (LiveImageProviderState)->Void { get set }
    func start(with url: URL)
    func stop()
    func configure(for: UIImageView)
}

enum LiveImageProviderState {
    case active(UIImage?)
    case error(Error)
}
  
class DisplayLinkImageUpdater: LiveImageProvider {
    private var url: URL!
    private var displaylink: CADisplayLink?
  
    func configure(for imageView: UIImageView) {
        imageView.contentMode = .redraw
    }
    
    func start(with url: URL) {
        self.url = url
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
            stateHandler(.error(error))
        }
    }
}


class OnlineImageProvider: NSObject, URLSessionDataDelegate, LiveImageProvider {
    private var url: URL!
    var stateHandler: (LiveImageProviderState)->Void =  { _ in }
    private var endMarkerData = Data(bytes: [0xFF, 0xD9] as [UInt8], count: 2)
    private var receivedData = Data()
    private var dataTask: URLSessionDataTask!
    
    func configure(for imageView: UIImageView) {
        imageView.contentMode = UIView.ContentMode.scaleAspectFill
    }
    
    func start(with url: URL) {
        stop()
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let request = URLRequest(url: url)
        self.dataTask = session.dataTask(with: request)
        self.dataTask.resume()
    }
    
    func stop() {
        self.dataTask?.cancel()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let nsError = error as NSError?, let urlError = NSURLError(rawValue: nsError.code) else { return }
        stateHandler(.error(urlError))
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
            
            stateHandler(.active(receivedImage))
            
            self.receivedData = self.receivedData.subdata(in: endLocation..<self.receivedData.count)
        }
    }
    
    enum NSURLError: Int, Error {
        case unknown = -1
        case cancelled = -999
        case badURL = -1000
        case timedOut = -1001
        case unsupportedURL = -1002
        case cannotFindHost = -1003
        case cannotConnectToHost = -1004
        case connectionLost = -1005
        case lookupFailed = -1006
        case HTTPTooManyRedirects = -1007
        case resourceUnavailable = -1008
        case notConnectedToInternet = -1009
        case redirectToNonExistentLocation = -1010
        case badServerResponse = -1011
        case userCancelledAuthentication = -1012
        case userAuthenticationRequired = -1013
        
        case zeroByteResource = -1014
        case cannotDecodeRawData = -1015
        case cannotDecodeContentData = -1016
        case cannotParseResponse = -1017
        // SSL errors
        case secureConnectionFailed = -1200
        case serverCertificateHasBadDate = -1201
        case serverCertificateUntrusted = -1202
        case serverCertificateHasUnknownRoot = -1203
        case serverCertificateNotYetValid = -1204
        case clientCertificateRejected = -1205
        case clientCertificateRequired = -1206
        case cannotLoadFromNetwork = -2000
    }
}
