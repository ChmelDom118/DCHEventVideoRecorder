//
//  DCHVideoRecorder.swift
//  bp-video-event-recorder
//
//  Created by Dominik Chmelík on 10.03.2022.
//

public protocol DCHVideoRecorder: AnyObject {
    
    var currentConfiguration: DCHRecorderConfiguration { get }
    
    var stateDelegate: DCHVideoRecorderDelegate? { get set }
    
    var currentState: DCHVideoRecorderState { get }
    
    func startRecording() throws
    
    func stopRecording()
    
    func pauseRecording()
    
    func resumeRecording()
    
    func resetRecorder()
    
    func captureSegment() throws
    
    func changeConfiguration(_ configuration: DCHRecorderConfiguration) throws
    
    func provideCapturedSegments(
        completion: @escaping (Result<[DCHCapturedVideoSegment], Error>) -> Void
    )
    
    func setupPreview(for view: DCHCameraPreviewView)
}
