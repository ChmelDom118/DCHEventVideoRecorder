//
//  DCHCameraPreviewView.swift
//  bp-video-event-recorder
//
//  Created by Dominik Chmelík on 18.03.2022.
//

import UIKit
import AVFoundation

public class DCHCameraPreviewView: UIView {
    
    public override class var layerClass: AnyClass {
        
        return AVCaptureVideoPreviewLayer.self
    }
    
    public var previewLayer: AVCaptureVideoPreviewLayer {
        
        return layer as! AVCaptureVideoPreviewLayer
    }
}
