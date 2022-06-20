//
//  AVCaptureDeviceExtension.swift
//  bp-video-event-recorder
//
//  Created by Dominik Chmelík on 14.06.2022.
//

import AVFoundation

extension AVCaptureDevice {
    
    func configureFrameRate(with frameRate: Double) throws {
        
        guard
            let range = activeFormat.videoSupportedFrameRateRanges.first,
            range.minFrameRate...range.maxFrameRate ~= frameRate
        else {
            
            print("Requested FPS is not supported!")
            return
        }
        
        try lockForConfiguration()
        
        let frameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
        activeVideoMinFrameDuration = frameDuration
        activeVideoMaxFrameDuration = frameDuration
        
        unlockForConfiguration()
    }
}
