//
//  DCHDefaultVideoRecorder.swift
//  bp-video-event-recorder
//
//  Created by Dominik Chmelík on 10.03.2022.
//

import AVFoundation

public final class DCHDefaultVideoRecorder {
    
    private(set) public var currentConfiguration: DCHRecorderConfiguration
    
    private(set) public var currentState: DCHVideoRecorderState {
        
        didSet {
            
            didChangeState(oldValue: oldValue)
        }
    }
    
    private var videoSegmentBufferExporter: DCHVideoSegmentBufferExporter
    private var captureSession: DCHCaptureSession!
    private var recordingBuffer: DCHRecordingBuffer?
    private var segmentBuffers: [DCHSegmentBuffer]
    
    weak public var stateDelegate: DCHVideoRecorderDelegate?
    
    public init(configuration: DCHRecorderConfiguration = .default) throws {

        self.currentState = .none
        self.segmentBuffers = []
        self.currentConfiguration = configuration
        
        self.videoSegmentBufferExporter = DCHDefaultVideoSegmentBufferExporter(
            exportConfiguration: currentConfiguration.exportSettings,
            duration: configuration.backwardOffset
        )
        
        try self.changeConfiguration(configuration)
    }
}

// MARK: - Public interface

extension DCHDefaultVideoRecorder: DCHVideoRecorder {
    
    public func startRecording() throws {
        
        guard currentState != .recording else {
            
            throw DCHVideoRecorderError.alreadyRunning
        }
        
        stopRecording()
        resetRecorder()
        
        recordingBuffer = DCHDefaultRecordingBuffer.makeBuffer(
            duration: currentConfiguration.backwardOffset,
            framerate: currentConfiguration.framerate.rawValue
        )
        
        currentState = .recording
    }
    
    public func stopRecording() {
        
        currentState = .none
    }
    
    public func resetRecorder() {
        
        try? videoSegmentBufferExporter.release()
        try? recordingBuffer?.release()
        recordingBuffer = nil
        currentState = .none
        
        segmentBuffers.removeAll()
    }
    
    public func pauseRecording() {
        
        guard currentState == .recording else {
            return
        }
     
        currentState = .paused
    }
    
    public func resumeRecording() {
        
        guard currentState == .paused else {
            return
        }
        
        currentState = .recording
    }
    
    public func captureSegment() throws {
        
        guard currentState == .recording else {
            
            throw DCHVideoRecorderError.notRunning
        }
        
        guard let recordingBuffer = recordingBuffer, !recordingBuffer.isEmpty() else {
            
            throw DCHVideoRecorderError.corruptedBuffer
        }
        
        let segmentBuffer = DCHDefaultSegmentBuffer(
            index: segmentBuffers.count,
            buffer: recordingBuffer
        )
        
        segmentBuffers.append(segmentBuffer)
    }
    
    public func changeConfiguration(_ configuration: DCHRecorderConfiguration) throws {
        
        guard currentState != .recording else {
            
            throw DCHVideoRecorderError.runtimeConfigChange
        }
        
        self.currentConfiguration = configuration
        
        self.videoSegmentBufferExporter = DCHDefaultVideoSegmentBufferExporter(
            exportConfiguration: configuration.exportSettings,
            duration: configuration.backwardOffset
        )
        
        try? recordingBuffer?.release()
        
        self.recordingBuffer = DCHDefaultRecordingBuffer.makeBuffer(
            duration: configuration.backwardOffset,
            framerate: configuration.framerate.rawValue
        )
        
        if captureSession == nil {
            
            captureSession = try DCHDefaultCaptureSession(delegate: self)
            captureSession.start()
        }
        
        try captureSession.configure(with: configuration)
    }
    
    public func setupPreview(for view: DCHCameraPreviewView) {
        
        captureSession.setupPreview(for: view)
    }
    
    public func provideCapturedSegments(
        completion: @escaping (Result<[DCHCapturedVideoSegment], Error>) -> Void
    ) {
        
        let dispatchGroup = DispatchGroup()
        
        var segmentAssets: [DCHCapturedVideoSegment] = []
        var failure: Error?
        
        for segmentBuffer in segmentBuffers {
            
            dispatchGroup.wait()
            dispatchGroup.enter()
            
            videoSegmentBufferExporter.export(segmentBuffer: segmentBuffer) { result in
                
                switch result {
                case let .success(videoSegment):
                    
                    segmentAssets.append(videoSegment)
                case let .failure(error):
                    
                    failure = error
                }
                
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
         
            if let failureReason = failure {
            
                completion(.failure(failureReason))
                return
            }
            
            completion(.success(segmentAssets))
        }
    }
}

// MARK: - State helpers

private extension DCHDefaultVideoRecorder {
    
    func didChangeState(oldValue: DCHVideoRecorderState) {
        
        guard oldValue != currentState else {
            return
        }
        
        stateDelegate?.videoRecorderDidChangeState(oldValue, currentState)
    }
}

// MARK: - DCHCaptureSessionDelegate

extension DCHDefaultVideoRecorder: DCHCaptureSessionDelegate {
    
    func captureSessionDidCaptureOutput(capturedBuffer: DCHPixelBuffer) {
        
        guard currentState == .recording else {
            return
        }
        
        recordingBuffer?.insert(capturedBuffer)
    }
}
