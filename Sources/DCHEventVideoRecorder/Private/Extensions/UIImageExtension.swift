//
//  UIImageExtension.swift
//  bp-video-event-recorder
//
//  Created by Dominik Chmelík on 09.04.2022.
//

import Foundation

import UIKit

extension UIImage {
    
    func pixelBuffer() -> CVPixelBuffer? {
        
        return pixelBuffer(
            width: Int(size.width), height: Int(size.height),
            pixelFormatType: kCVPixelFormatType_32ARGB,
            colorSpace: CGColorSpaceCreateDeviceRGB(),
            alphaInfo: .noneSkipFirst
        )
    }
    
    func pixelBuffer(
        width: Int, height: Int,
        pixelFormatType: OSType,
        colorSpace: CGColorSpace,
        alphaInfo: CGImageAlphaInfo
    ) -> CVPixelBuffer? {
        
        var maybePixelBuffer: CVPixelBuffer?
        
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ]
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            pixelFormatType,
            attributes as CFDictionary,
            &maybePixelBuffer
        )
        
        guard status == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer else {
            return nil
        }
        
        let flags = CVPixelBufferLockFlags(rawValue: 0)
        
        guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(pixelBuffer, flags) else {
            return nil
        }
        
        defer {
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, flags)
        }
        
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: colorSpace,
            bitmapInfo: alphaInfo.rawValue
        )
        else {
            return nil
        }
        
        UIGraphicsPushContext(context)
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        
        return pixelBuffer
    }
}
