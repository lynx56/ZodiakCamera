//
//  Exs.swift
//  ZodiakCamera
//
//  Created by lynx on 06/11/2019.
//  Copyright © 2019 gulnaz. All rights reserved.
//

import Accelerate
import UIKit

extension UIImage {
    func resizeWithScaleAspectFitMode(to newSize: CGSize) -> UIImage? {
        let size = self.size
        let widthRatio  = newSize.width  / size.width
        let heightRatio = newSize.height / size.height
        let newSize = widthRatio > heightRatio ?  CGSize(width: size.width * heightRatio, height: size.height * heightRatio) : CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
    
        return resizeWithAccelerate(to: newSize)
    }
    
    private func resizeWithAccelerate(to newSize: CGSize) -> UIImage? {
        var resultImage = self
        
        guard let cgImage = cgImage, let colorSpace = cgImage.colorSpace else { return nil }
        
        // create a source buffer
        var format = vImage_CGImageFormat(bitsPerComponent: numericCast(cgImage.bitsPerComponent),
                                          bitsPerPixel: numericCast(cgImage.bitsPerPixel),
                                          colorSpace: Unmanaged.passUnretained(colorSpace),
                                          bitmapInfo: cgImage.bitmapInfo,
                                          version: 0,
                                          decode: nil,
                                          renderingIntent: .absoluteColorimetric)
        var sourceBuffer = vImage_Buffer()
        defer {
            sourceBuffer.data.deallocate()
        }
        
        var error = vImageBuffer_InitWithCGImage(&sourceBuffer, &format, nil, cgImage, numericCast(kvImageNoFlags))
        guard error == kvImageNoError else { return resultImage }
        
        // create a destination buffer
        let destWidth = Int(newSize.width)
        let destHeight = Int(newSize.height)
        let bytesPerPixel = cgImage.bitsPerPixel
        let destBytesPerRow = destWidth * bytesPerPixel
        let destData = UnsafeMutablePointer<UInt8>.allocate(capacity: destHeight * destBytesPerRow)
        defer {
            destData.deallocate()
        }
        var destBuffer = vImage_Buffer(data: destData, height: vImagePixelCount(destHeight), width: vImagePixelCount(destWidth), rowBytes: destBytesPerRow)
        
        // scale the image
        error = vImageScale_ARGB8888(&sourceBuffer, &destBuffer, nil, numericCast(kvImageHighQualityResampling))
        guard error == kvImageNoError else { return resultImage }
        
        // create a CGImage from vImage_Buffer
        let destCGImage = vImageCreateCGImageFromBuffer(&destBuffer, &format, nil, nil, numericCast(kvImageNoFlags), &error)?.takeRetainedValue()
        guard error == kvImageNoError else { return resultImage }
        
        // create a UIImage
        if let scaledImage = destCGImage.flatMap({ UIImage(cgImage: $0) }) {
            resultImage = scaledImage
        }
        
        return resultImage
    }
}

