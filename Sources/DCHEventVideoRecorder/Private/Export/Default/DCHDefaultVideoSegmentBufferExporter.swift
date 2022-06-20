//
//  DCHDefaultVideoSegmentBufferExporter.swift
//  bp-video-event-recorder
//
//  Created by Dominik Chmelík on 03.06.2022.
//

import AVFoundation

final class DCHDefaultVideoSegmentBufferExporter {
    
    private let fileManager: FileManager
    private let dispatchQeueue: DispatchQueue
    
    private var exportConfiguration: DCHExportSettings
    private var duration: Double
    
    init(
        exportConfiguration: DCHExportSettings,
        duration: Double
    ) {
        
        self.fileManager = FileManager.default
        self.dispatchQeueue = DispatchQueue.global()
        self.exportConfiguration = exportConfiguration
        self.duration = duration
        
        try? release()
    }
    
    func updateConfiguration(
        with configuration: DCHExportSettings,
        and duration: Double
    ) {
        
        self.exportConfiguration = configuration
        self.duration = duration
    }
}

// MARK: - Public interface

extension DCHDefaultVideoSegmentBufferExporter: DCHVideoSegmentBufferExporter {
    
    func export(
        segmentBuffer: DCHSegmentBuffer,
        completion: @escaping (Result<DCHCapturedVideoSegment, Error>) -> Void
    ) {
        
        guard segmentBuffer.isReady() else {

            waitForBufferReady(segmentBuffer, completion: completion)
            return
        }
        
        guard !segmentBuffer.isEmpty() else {
            
            completion(.failure(Errors.segmentIsEmpty))
            return
        }
        
        try? makeDirectoryIfNeeded()
        let segmentPath = makeVideoSegmentFilePath(with: segmentBuffer.index)
        let url = URL(fileURLWithPath: segmentPath)
        
        guard let assetWriter = try? makeAssetWriter(with: url) else {
            
            completion(.failure(Errors.cannotPrepareExporter))
            return
        }
        
        let assetWriterInput = makeAssetWriterInput()
        let assetWriterPixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: assetWriterInput
        )
        
        guard assetWriter.canAdd(assetWriterInput) else {
            
            completion(.failure(Errors.cannotPrepareExporter))
            return
        }
        
        assetWriter.add(assetWriterInput)
        assetWriter.start()
        
        var currentIndex = 0
        
        let onFinishWritting: () -> Void = {
            
            assetWriterInput.markAsFinished()
            
            assetWriter.finishWriting {
             
                if let error = assetWriter.error {
                    
                    completion(.failure(error))
                    return
                }
                
                let videoSegment = DCHCapturedVideoSegment(
                    path: assetWriter.outputURL
                )
                
                completion(.success(videoSegment))
            }
        }
        
        assetWriterInput.requestMediaDataWhenReady(on: dispatchQeueue) { [weak self] in
            
            guard let self = self else {
                return
            }
            
            while assetWriterInput.isReadyForMoreMediaData {
                
                guard let pixelBuffer = segmentBuffer.item(at: currentIndex) else {
                    
                    onFinishWritting()
                    break
                }
             
                let timescale = Double(segmentBuffer.size) / self.duration
                
                let presentationTime = CMTime(
                    value: Int64(currentIndex),
                    timescale: Int32(timescale)
                )
                
                assetWriterPixelBufferAdaptor.append(
                    pixelBuffer,
                    withPresentationTime: presentationTime
                )
                
                currentIndex += 1
            }
        }
    }
        
    func release() throws {
        
        let directory = makeDirectoryPath()
        
        guard fileManager.fileExists(atPath: directory) else {
            return
        }
        
       try fileManager.removeItem(atPath: directory)
    }
}

// MARK: - Export components

private extension DCHDefaultVideoSegmentBufferExporter {
    
    func makeAssetWriter(with url: URL) throws -> DCHAssetWriter {
        
        switch exportConfiguration.format {
        case .mp4:
            
            return try DCHAssetWriter(
                outputURL: url,
                fileType: .mp4
            )
        case .mov:
            
            return try DCHAssetWriter(
                outputURL: url,
                fileType: .mov
            )
        }
    }
    
    func makeAssetWriterInput() -> AVAssetWriterInput {
        
        let preset: AVOutputSettingsPreset
        
        switch exportConfiguration.quality {
        case .ultra:
            
            preset = .preset3840x2160
        case .high:
            
            preset = .preset1920x1080
        case .medium:
            
            preset = .preset1280x720
        case .low:
            
            preset = .preset640x480
        }

        let outputSettings = AVOutputSettingsAssistant(
            preset: preset
        )?.videoSettings
        
        let writerInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: outputSettings
        )
        
        writerInput.transform = CGAffineTransform(
            rotationAngle: .pi * 0.5
        )
        
        return writerInput
    }
}

// MARK: - Segment check helpers

private extension DCHDefaultVideoSegmentBufferExporter {
    
    func waitForBufferReady(
        _ buffer: DCHSegmentBuffer,
        completion: @escaping (Result<DCHCapturedVideoSegment, Error>) -> Void
    ) {
        
        let delay: TimeInterval = 0.1
        
        DispatchQueue.global(
            qos: .background
        ).asyncAfter(deadline: .now() + delay) { [weak self] in
            
            guard let self = self else {
                return
            }
            
            switch buffer.isReady() {
            case true:
                
                DispatchQueue.main.async {
                    
                    self.export(segmentBuffer: buffer, completion: completion)
                }
            case false:
                
                self.waitForBufferReady(buffer, completion: completion)
            }
        }
    }
}

// MARK: - File helpers

private extension DCHDefaultVideoSegmentBufferExporter {
    
    func makeDirectoryPath() -> String {
        
        return "\(NSTemporaryDirectory())DCHExportedSegments"
    }
    
    func makeDirectoryIfNeeded() throws {
        
        let directoryPath = makeDirectoryPath()
        
        guard !fileManager.fileExists(atPath: directoryPath) else {
            return
        }
        
        try fileManager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)
    }
    
    func makeVideoSegmentFilePath(with index: Int) -> String {
        
        let directory = makeDirectoryPath()
        return "\(directory)/video_segment_\(index).mp4"
    }
}

// MARK: - Errors

private extension DCHDefaultVideoSegmentBufferExporter {
    
    enum Errors: Error {
        
        case segmentIsEmpty
        case cannotPrepareExporter
    }
}

// MARK: - DCHAssetWriter

private final class DCHAssetWriter: AVAssetWriter {
    
    override init(
        outputURL: URL,
        fileType outputFileType: AVFileType
    ) throws {
        
        try super.init(
            outputURL: outputURL,
            fileType: outputFileType
        )
        
        configure()
    }
    
    func configure() {
        
        shouldOptimizeForNetworkUse = false
    }
    
    func start() {
        
        startWriting()
        startSession(atSourceTime: .zero)
    }
}
