//
//  DCHDefaultSegmentBuffer.swift
//  bp-video-event-recorder
//
//  Created by Dominik Chmelík on 14.06.2022.
//

import CoreMedia

final class DCHDefaultSegmentBuffer {
    
    private let fileManager: FileManager
    
    public var index: Int
    public var frameFilePaths: [String]
    public var dateOfCreation: Date
    
    init(index: Int, buffer: DCHRecordingBuffer) {
        
        self.index = index
        self.fileManager = FileManager.default
        self.frameFilePaths = buffer.capture()
        self.dateOfCreation = Date()
    }
}

// MARK: - Public interface

extension DCHDefaultSegmentBuffer: DCHSegmentBuffer {
    
    func items() -> [CVPixelBuffer] {
        
        var pixelBuffers = [CVPixelBuffer]()
        
        for path in frameFilePaths {
        
            guard
                let data = fileManager.contents(atPath: path),
                let pixelBuffer = data.toPixelBuffer()
            else {
                continue
            }
            
            pixelBuffers.append(pixelBuffer)
        }
        
        return pixelBuffers
    }
    
    func item(at index: Int) -> CVPixelBuffer? {
        
        guard index < frameFilePaths.count  else {
            return nil
        }
        
        let path = frameFilePaths[index]
        
        guard
            let data = fileManager.contents(atPath: path)
        else {
            return nil
        }
        
        return data.toPixelBuffer()
    }
    
    func isEmpty() -> Bool {
        
        return frameFilePaths.isEmpty
    }
    
    func isReady() -> Bool {
    
        for path in frameFilePaths {
            
            if fileManager.contents(atPath: path) == nil {
                
                return false
            }
        }
        
        return true
    }
    
    func getIndex() -> Int {
        
        return index
    }
    
    func getFrameFilePaths() -> [String] {
        
        return frameFilePaths
    }
    
    func getDateOfCreation() -> Date {
        
        return dateOfCreation
    }
    
    var size: Int {
    
        return frameFilePaths.count
    }
}

