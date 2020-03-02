//
//  IPCameraView.swift
//  ZodiakCamera
//
//  Created by lynx on 02/12/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import UIKit

class LiveImageProvideByStream: NSObject, URLSessionDataDelegate, LiveImageProvider {
    private let url: URL
    var stateHandler: (LiveImageProviderState)->Void =  { _ in }
    private var endMarkerData = Data(bytes: [0xFF, 0xD9] as [UInt8], count: 2)
    private var receivedData = Data()
    private var dataTask: URLSessionDataTask!
    
    init(url: URL) {
        self.url = url
    }
    
    func configure(for imageView: UIImageView) {
        imageView.contentMode = UIView.ContentMode.scaleAspectFill
    }
    
    func start() {
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
        guard let error = error else { return }
        stateHandler(.error(error))
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
