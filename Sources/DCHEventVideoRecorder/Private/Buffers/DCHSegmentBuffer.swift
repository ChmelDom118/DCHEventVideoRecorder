//
//  DCHSegmentBuffer.swift
//  bp-video-event-recorder
//
//  Created by Dominik Chmelík on 18.03.2022.
//

import CoreMedia

protocol DCHSegmentBuffer: AnyObject {
    
    func items() -> [CVPixelBuffer]
    
    func item(at index: Int) -> CVPixelBuffer?
    
    func isEmpty() -> Bool
    
    func isReady() -> Bool
    
    var index: Int { get }
    
    var frameFilePaths: [String] { get }
    
    var dateOfCreation: Date { get }
    
    var size: Int { get }
}
