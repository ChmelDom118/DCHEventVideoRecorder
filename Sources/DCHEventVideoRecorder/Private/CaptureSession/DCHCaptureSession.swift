//
//  DCHCaptureSession.swift
//  bp-video-event-recorder
//
//  Created by Dominik Chmelík on 18.03.2022.
//

protocol DCHCaptureSession: AnyObject {
    
    var delegate: DCHCaptureSessionDelegate? { get set }
    
    func configure(with configuration: DCHRecorderConfiguration) throws
    
    func setupPreview(for view: DCHCameraPreviewView)
    
    func start()
    
    func stop()
}
