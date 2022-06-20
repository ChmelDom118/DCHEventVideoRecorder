//
//  DCHCaptureSessionDelegate.swift
//  bp-video-event-recorder
//
//  Created by Dominik Chmelík on 18.03.2022.
//

import CoreMedia

protocol DCHCaptureSessionDelegate: AnyObject {
    
    func captureSessionDidCaptureOutput(capturedBuffer: DCHPixelBuffer)
}
