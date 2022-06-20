//
//  DCHCapturedVideoSegment.swift
//  bp-video-event-recorder
//
//  Created by Dominik Chmelík on 18.03.2022.
//

import AVFoundation

public final class DCHCapturedVideoSegment {
    
    public let path: URL
    
    public var asset: AVAsset {
        
        return AVAsset(url: path)
    }
    
    public var duration: Double {
        
        return asset.duration.seconds
    }
    
    init(path: URL) {
        
        self.path = path
    }
}
