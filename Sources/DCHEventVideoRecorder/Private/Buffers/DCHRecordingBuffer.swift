//
//  DCHRecordingBuffer.swift
//  bp-video-event-recorder
//
//  Created by Dominik Chmelík on 18.03.2022.
//

import CoreMedia

protocol DCHRecordingBuffer: AnyObject {
    
    func insert(_ buffer: DCHPixelBuffer)
    
    func capture() -> [String]
    
    func isEmpty() -> Bool
    
    func isReady() -> Bool
    
    func directory() -> String
    
    func release() throws
    
    var actualSize: Int { get }
    
    var size: Int { get }
}
