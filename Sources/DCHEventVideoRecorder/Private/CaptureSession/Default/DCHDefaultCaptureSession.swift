//
//  DCHDefaultCaptureSession.swift
//  bp-video-event-recorder
//
//  Created by Dominik Chmelík on 14.06.2022.
//

import AVFoundation

final class DCHDefaultCaptureSession {
    
    private let captureSession: AVCaptureSession
    private let bufferDelegate: DCHSessionDataBufferDelegate
    
    private let videoOutput: AVCaptureVideoDataOutput
    private let cameraDevice: AVCaptureDevice
    
    weak public var delegate: DCHCaptureSessionDelegate?
    
    init(delegate: DCHCaptureSessionDelegate) throws {
        
        self.captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        
        self.bufferDelegate = DCHSessionDataBufferDelegate()
        self.delegate = delegate
        
        guard let cameraDevice = AVCaptureDevice.default(for: .video) else {
            throw DCHCaptureSessionError.videoDeviceNotFound
        }
        
        self.cameraDevice = cameraDevice
        
        let cameraDeviceInput = try AVCaptureDeviceInput(device: cameraDevice)
        
        guard captureSession.canAddInput(cameraDeviceInput) else {
            throw DCHCaptureSessionError.cannotAddVideoInput
        }
        
        captureSession.addInput(cameraDeviceInput)
        
        self.videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = false
        
        guard captureSession.canAddOutput(videoOutput) else {
            throw DCHCaptureSessionError.cannotAddVideoOutput
        }
        
        captureSession.addOutput(videoOutput)
        captureSession.commitConfiguration()
    }
}

// MARK: - Public interface

extension DCHDefaultCaptureSession: DCHCaptureSession {
    
    func configure(with configuration: DCHRecorderConfiguration) throws {
        
        captureSession.beginConfiguration()

        switch configuration.recordQuality {
        case .low:
            
            captureSession.sessionPreset = .vga640x480
        case .medium:
            
            captureSession.sessionPreset = .hd1280x720
        case .high:
            
            captureSession.sessionPreset = .hd1920x1080
        case .ultra:
            
            captureSession.sessionPreset = .hd4K3840x2160
        }
        
        captureSession.commitConfiguration()
        
        let videoSettings: [String: Any]?
        
        switch configuration.exportSettings.format {
        case .mp4:
            
            videoSettings = videoOutput.recommendedVideoSettingsForAssetWriter(writingTo: .mp4)
        case .mov:
            
            videoSettings = videoOutput.recommendedVideoSettingsForAssetWriter(writingTo: .mov)
        }
        
        let frameRate = Double(configuration.framerate.rawValue)
        try cameraDevice.configureFrameRate(with: frameRate)
        
        videoOutput.videoSettings = videoSettings
    }
    
    func setupPreview(for view: DCHCameraPreviewView) {
        
        view.previewLayer.session = captureSession
    }
    
    func start() {
        
        let dataOutputQueue = DispatchQueue(
            label: "DCHCaptureSession.output.queue",
            qos: .userInitiated,
            attributes: [],
            autoreleaseFrequency: .workItem
        )
        
        bufferDelegate.onCaptureBuffer = { [weak self] buffer in
            
            self?.delegate?.captureSessionDidCaptureOutput(
                capturedBuffer: buffer
            )
        }
        
        videoOutput.setSampleBufferDelegate(
            bufferDelegate,
            queue: dataOutputQueue
        )
        
        captureSession.startRunning()
    }
    
    func stop() {
        
        captureSession.stopRunning()
    }
}

// MARK: - DCHSessionDataBufferDelegate

private class DCHSessionDataBufferDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var onCaptureBuffer: ((DCHPixelBuffer) -> Void)?
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        
        autoreleasepool {
        
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                return
            }
            
            guard let pixelBufferCopy = pixelBuffer.makeCopy() else {
                return
            }
            
            let buffer = DCHPixelBuffer(
                date: Date(),
                pixelBuffer: pixelBufferCopy
            )

            onCaptureBuffer?(buffer)
        }
    }
}
