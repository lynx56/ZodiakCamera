//
//  Model.swift
//  ZodiakCamera
//
//  Created by lynx on 01/11/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import Photos

class Model: ZodiakProvider {
    var liveStreamUrl: URL { return URL(string: getUrl(with: "videostream.cgi"))! }
    var snapshotUrl: URL { return URL(string: getUrl(with: "snapshot.cgi"))! }
    
    private let cameraSettingsProvider: CameraSettingsProvider
    
    init(cameraSettingsProvider: CameraSettingsProvider) {
        self.cameraSettingsProvider = cameraSettingsProvider
    }
    
    private func getUrl(with cgi: String) -> String {
        let cameraSettings = cameraSettingsProvider.settings
        return "http://\(cameraSettings.host.absoluteString):\(cameraSettings.port)/\(cgi)?loginuse=\(cameraSettings.login)&amp;loginpas=\(cameraSettings.password)"
    }
    
    func readsettings(handler: @escaping (Result<Settings, Error>) -> Void) {
        let url = getUrl(with: "get_camera_params.cgi")
        let task = URLSession.shared.downloadTask(with: URL(string: url)!) { (file, response, error) in
            if let file = file {
                do {
                    let settings = try Settings(json: String(contentsOf: file))!
                    handler(.success(settings))
                } catch {
                    handler(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    func chageSettings(_ changes: Settings.Change, handler: @escaping (Result<Settings, Error>) -> Void) {
        let (param, value) = changes.urlParameters
        var cgi =  getUrl(with: "camera_control.cgi")
        cgi += "&param=\(param)&value=\(value)"
        cgi += "&\(Date().stamp()!)"
        print(cgi)
        let url = URL(string: cgi)!
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                handler(.failure(error))
                return
            }
            self.readsettings(handler: handler)
        }
        
        task.resume()
    }
    
    func userManipulate(_ command: UserManipulation, handler: @escaping (Result<Void, Error>) -> Void) {
        let convertedCommand: Int?
        var cancellOthersCommands = false
        switch command {
        case .stop:
            convertedCommand = 1
            cancellOthersCommands = true
        case .start: convertedCommand = nil
        case .move(let direction):
            switch direction {
            case .down: convertedCommand = 2
            case .downleft: convertedCommand = 92
            case .downright: convertedCommand = 93
            case .left: convertedCommand = 4
            case .right: convertedCommand = 6
            case .up: convertedCommand = 0
            case .upleft: convertedCommand = 90
            case .upright: convertedCommand = 91
            }
        }
        
        guard let cameraManipulate = convertedCommand else { return }
        
        userControl("\(cameraManipulate)", cancelPrevious: cancellOthersCommands, handler: handler)
    }

    private var userCancellableTasks: [URL: URLSessionDataTask] = [:]
    private func userControl(_ command: String, cancelPrevious: Bool = false, handler: @escaping (Result<Void, Error>) -> Void) {
        var cgi = getUrl(with: "decoder_control.cgi");
        cgi += "&command=\(command)"
        cgi += "&onestep=0"
        cgi += "&\(Date().stamp())"
        
        let url = URL(string: cgi)!

        if cancelPrevious {
            userCancellableTasks.values.forEach { if $0.state == .running { $0.cancel() }}
            userCancellableTasks.removeAll()
        }
        
        let task = URLSession.shared.dataTask(with: url) { [url] (data, response, error) in
            self.userCancellableTasks.removeValue(forKey: url)
            guard let error = error else { return }
            handler(.failure(error))
        }
        
        task.resume()
        if !cancelPrevious {
            userCancellableTasks[url] = task
        }
    }
}

protocol ZodiakProvider {
    func chageSettings(_ change: Settings.Change, handler: @escaping (Result<Settings, Error>) -> Void)
    func userManipulate(_ command: UserManipulation, handler: @escaping (Result<Void, Error>) -> Void)
    var liveStreamUrl: URL { get }
    var snapshotUrl: URL { get }
}

enum UserManipulation {
    enum Move {
        case up
        case upleft
        case left
        case downleft
        case down
        case right
        case downright
        case upright
    }
    case move(Move)
    case stop
    case start
}

extension Settings.Change {
    var urlParameters: (String, String) {
        switch self {
        case .brightness(let value):
            return ("1", String(value))
        case .contrast(let value):
            return ("2", String(value))
        case .saturation(let value):
            return ("8", String(value))
        case .ir(let value):
            return ("14", value == true ? "1" : "0")
        }
    }
}

//
//
//func writeImagesAsMovie(allImages: [UIImage], videoPath: String, videoSize: CGSize, videoFPS: Int32) {
//    // Create AVAssetWriter to write video
//    guard let assetWriter = createAssetWriter(path: videoPath, size: videoSize) else {
//        print("Error converting images to video: AVAssetWriter not created")
//        return
//    }
//
//    // If here, AVAssetWriter exists so create AVAssetWriterInputPixelBufferAdaptor
//    let writerInput = assetWriter.inputs.filter{ $0.mediaType == AVMediaType.video }.first!
//    let sourceBufferAttributes : [String : AnyObject] = [
//        kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32ARGB),
//        kCVPixelBufferWidthKey as String : videoSize.width,
//        kCVPixelBufferHeightKey as String : videoSize.height,
//        ]
//    let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: sourceBufferAttributes)
//
//    // Start writing session
//    assetWriter.startWriting()
//    assetWriter.startSession(atSourceTime: CMTime.zero)
//    if (pixelBufferAdaptor.pixelBufferPool == nil) {
//        print("Error converting images to video: pixelBufferPool nil after starting session")
//        return
//    }
//
//    // -- Create queue for <requestMediaDataWhenReadyOnQueue>
//    let mediaQueue = DispatchQueue(__label: "mediaInputQueue", attr: nil)
//
//    // -- Set video parameters
//    let frameDuration = CMTimeMake(value: 1, timescale: videoFPS)
//    var frameCount = 0
//
//    // -- Add images to video
//    let numImages = allImages.count
//    writerInput.requestMediaDataWhenReady(on: mediaQueue, using: { () -> Void in
//        // Append unadded images to video but only while input ready
//        while (writerInput.isReadyForMoreMediaData && frameCount < numImages) {
//            let lastFrameTime = CMTimeMake(value: Int64(frameCount), timescale: videoFPS)
//            let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
//
//            if !self.appendPixelBufferForImageAtURL(allImages[frameCount], pixelBufferAdaptor: pixelBufferAdaptor, presentationTime: presentationTime) {
//                print("Error converting images to video: AVAssetWriterInputPixelBufferAdapter failed to append pixel buffer")
//                return
//            }
//
//            frameCount += 1
//        }
//
//        // No more images to add? End video.
//        if (frameCount >= numImages) {
//            writerInput.markAsFinished()
//            assetWriter.finishWritingWithCompletionHandler {
//                if (assetWriter.error != nil) {
//                    print("Error converting images to video: \(assetWriter.error)")
//                } else {
//                    self.saveVideoToLibrary(NSURL(fileURLWithPath: videoPath))
//                    print("Converted images to movie @ \(videoPath)")
//                }
//            }
//        }
//    })
//}
//
//
//func createAssetWriter(path: String, size: CGSize) -> AVAssetWriter? {
//    // Convert <path> to NSURL object
//    let pathURL = NSURL(fileURLWithPath: path)
//
//    // Return new asset writer or nil
//    do {
//        // Create asset writer
//        let newWriter = try AVAssetWriter(URL: pathURL as URL, fileType: AVFileType.mp4)
//
//        // Define settings for video input
//        let videoSettings: [String : AnyObject] = [
//            AVVideoCodecKey  : AVVideoCodecH264,
//            AVVideoWidthKey  : size.width,
//            AVVideoHeightKey : size.height,
//            ]
//
//        // Add video input to writer
//        let assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
//        newWriter.add(assetWriterVideoInput)
//
//        // Return writer
//        print("Created asset writer for \(size.width)x\(size.height) video")
//        return newWriter
//    } catch {
//        print("Error creating asset writer: \(error)")
//        return nil
//    }
//}
//
//
//func appendPixelBufferForImageAtURL(image: UIImage, pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor, presentationTime: CMTime) -> Bool {
//    var appendSucceeded = false
//
//    autoreleasepool {
//        if  let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool {
//            let pixelBufferPointer = UnsafeMutablePointer<CVPixelBuffer?>.alloc(1)
//            let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(
//                kCFAllocatorDefault,
//                pixelBufferPool,
//                pixelBufferPointer
//            )
//
//            if let pixelBuffer = pixelBufferPointer.memory where status == 0 {
//                fillPixelBufferFromImage(image, pixelBuffer: pixelBuffer)
//                appendSucceeded = pixelBufferAdaptor.appendPixelBuffer(pixelBuffer, withPresentationTime: presentationTime)
//                pixelBufferPointer.destroy()
//            } else {
//                NSLog("Error: Failed to allocate pixel buffer from pool")
//            }
//
//            pixelBufferPointer.dealloc(1)
//        }
//    }
//
//    return appendSucceeded
//}
//
//
//func fillPixelBufferFromImage(image: UIImage, pixelBuffer: CVPixelBuffer) {
//    CVPixelBufferLockBaseAddress(pixelBuffer, 0)
//
//    let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
//    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
//
//    // Create CGBitmapContext
//    let context = CGContext(
//        data: pixelData,
//        width: Int(image.size.width),
//        height: Int(image.size.height),
//        bitsPerComponent: 8,
//        bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
//        space: rgbColorSpace,
//        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
//    )
//
//    // Draw image into context
//    //CGContextDrawImage(context, CGRectMake(0, 0, image.size.width, image.size.height), image.cgImage)
//    context?.draw(image.cgImage!, in: CGRect.init(origin: .zero, size: image.size))
//
//
//    CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
//}
//
//
//func saveVideoToLibrary(videoURL: NSURL) {
//    PHPhotoLibrary.requestAuthorization { status in
//        // Return if unauthorized
//        guard status == .authorized else {
//            print("Error saving video: unauthorized access")
//            return
//        }
//
//        // If here, save video to library
//        PHPhotoLibrary.sharedPhotoLibrary().performChanges({
//            PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(videoURL as URL)
//        }) { success, error in
//            if !success {
//                print("Error saving video: \(error)")
//            }
//        }
//    }
//}
