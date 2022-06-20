//
//  CVPixelBufferExtension.swift
//  bp-video-event-recorder
//
//  Created by Dominik Chmelík on 25.03.2022.
//

import CoreVideo
import CoreImage
import UIKit
import VideoToolbox

extension CVPixelBuffer {
    
    func makeCopy() -> CVPixelBuffer? {

        var pixelBufferCopy : CVPixelBuffer?
        
        CVPixelBufferCreate(
            nil,
            CVPixelBufferGetWidth(self),
            CVPixelBufferGetHeight(self),
            CVPixelBufferGetPixelFormatType(self),
            nil,
            &pixelBufferCopy
        )

        guard let pixelBufferCopy = pixelBufferCopy else {
            return nil
        }
        
        CVBufferPropagateAttachments(self, pixelBufferCopy)
        CVPixelBufferLockBaseAddress(self, .readOnly)
        CVPixelBufferLockBaseAddress(pixelBufferCopy, .readOnly)

        for plane in 0..<CVPixelBufferGetPlaneCount(self) {
            
            let dest = CVPixelBufferGetBaseAddressOfPlane(pixelBufferCopy, plane)
            let source = CVPixelBufferGetBaseAddressOfPlane(self, plane)
            let height = CVPixelBufferGetHeightOfPlane(self, plane)
            let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(self, plane)

            memcpy(dest, source, height * bytesPerRow)
        }

        CVPixelBufferUnlockBaseAddress(pixelBufferCopy, .readOnly)
        CVPixelBufferUnlockBaseAddress(self, .readOnly)

        return pixelBufferCopy
    }
    
    func toImageData(quality: CGFloat = 1) -> Data? {
        
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(self, options: nil, imageOut: &cgImage)

        guard let cgImage = cgImage else {
            return nil
        }

        let generatedImage = UIImage(cgImage: cgImage)
        return generatedImage.jpegData(compressionQuality: quality)
    }
}

// MARK: - Data+CVPixelBuffer

extension Data {
    
    func toPixelBuffer() -> CVPixelBuffer? {
        
        let image = UIImage(data: self)
        
        return image?.pixelBuffer()
    }
}
