//
//  DCHDefaultRecordingBuffer.swift
//  bp-video-event-recorder
//
//  Created by Dominik Chmelík on 14.06.2022.
//

import CoreMedia

final class DCHDefaultRecordingBuffer {
    
    private let fileManager: FileManager
    private let dispatchQueue: DispatchQueue
    
    private(set) var duration: Double
    private(set) var size: Int
    
    private var frameFiles: ThreadSafeArray<FrameFile>
    private var capturedFrameFiles: ThreadSafeArray<FrameFile>
    
    init(duration: Double, size: Int) {
        
        self.duration = duration
        self.size = size
        
        let dispatchQueue = DispatchQueue(
            label: String(describing: DCHRecordingBuffer.self),
            attributes: .concurrent
        )
        
        self.dispatchQueue = dispatchQueue
        self.frameFiles = ThreadSafeArray<FrameFile>(dispatchQueue: dispatchQueue)
        self.capturedFrameFiles = ThreadSafeArray<FrameFile>(dispatchQueue: dispatchQueue)
        self.fileManager = FileManager.default
    }
    
    static func makeBuffer(duration: Double, framerate: Int) -> DCHRecordingBuffer {
        
        let framerate = Double(framerate)
        let size = Int((duration * framerate).rounded(.up))
        
        return DCHDefaultRecordingBuffer(duration: duration, size: size)
    }
}

// MARK: - Public interface

extension DCHDefaultRecordingBuffer: DCHRecordingBuffer {
    
    var actualSize: Int {
        
        let directory = makeDirectoryPath()
        
        guard let files = try? fileManager.contentsOfDirectory(atPath: directory) else {
            return 0
        }
        
        return files.count
    }
    
    func insert(_ buffer: DCHPixelBuffer) {
        
        try? makeDirectoryIfNeeded()
        
        let filePath = makeFrameFilePath()

        let frameFile = FrameFile(
            creationDate: buffer.date,
            filePath: filePath
        )
        
        frameFiles.append(frameFile)
        
        guard let imageData = buffer.pixelBuffer.toImageData() else {
            
            assertionFailure("Cannot create image from pixel buffer!")
            return
        }
        
        dispatchQueue.async { [weak self] in
         
            self?.fileManager.createFile(
                atPath: filePath,
                contents: imageData,
                attributes: [.creationDate: buffer.date]
            )
        }
        
        removeUnusedFrames()
        validateBuffer()
    }
    
    func capture() -> [String] {
        
        let captureDate = Date().addingTimeInterval(-duration)
        
        var capture = [String]()
        let currentFrameFiles = frameFiles.all
        
        dispatchQueue.sync(flags: .barrier) {
            
            let sortedCurrentFrameFiles = currentFrameFiles.sorted { lhsFilePath, rhsFilePath in
                
                return lhsFilePath.creationDate < rhsFilePath.creationDate
            }
            
            for frameFile in sortedCurrentFrameFiles {

                guard frameFile.creationDate >= captureDate else {
                    continue
                }
                
                capture.append(frameFile.filePath)
                capturedFrameFiles.append(frameFile)
            }
        }
        
        validateBuffer()
        
        return capture
    }
    
    func isEmpty() -> Bool {
        
        return frameFiles.count() == 0
    }
    
    func isReady() -> Bool {
        
        return actualSize == frameFiles.count()
    }
    
    func directory() -> String {
        
        return makeDirectoryPath()
    }
    
    func release() throws {
        
        frameFiles.clear()
        capturedFrameFiles.clear()
        
        let directoryPath = makeDirectoryPath()
        
        guard fileManager.fileExists(atPath: directoryPath) else {
            return
        }
        
        try fileManager.removeItem(atPath: directoryPath)
    }
}

// MARK: - File helpers

private extension DCHDefaultRecordingBuffer {
    
    func validateBuffer() {
        
        let frameFiles = self.frameFiles
        let capturedFrameFiles = self.capturedFrameFiles.all

        for capturedFrameFile in capturedFrameFiles {

            guard !frameFiles.contains(capturedFrameFile) else {
                continue
            }

            print("\(Date()) 😡😡 CAPTURED FRAME DELETED!! 😡😡")
        }
    }
    
    func removeUnusedFrames() {
        
        let validDate = Date().addingTimeInterval(-duration)
        let currenttFrameFiles = frameFiles.all
        let shouldHandle = currenttFrameFiles.count > size
        
        guard shouldHandle else {
            return
        }
        
        for frameFile in currenttFrameFiles {
            
            guard
                !capturedFrameFiles.contains(frameFile),
                frameFile.creationDate < validDate
            else {
                continue
            }
            
            frameFiles.remove(frameFile)
            try? removeFrameFile(with: frameFile.filePath)
        }
    }
    
    func removeFrameFile(with filePath: String) throws {
        
        guard fileManager.fileExists(atPath: filePath) else {
            return
        }
        
        try fileManager.removeItem(atPath: filePath)
    }
    
    func makeFrameFilePath() -> String {
    
        let directory = makeDirectoryPath()
        let id = Int(Date().timeIntervalSince1970 * 1000)
        return "\(directory)/video_frame_\(id).jpg"
    }
}

// MARK: - Directory

private extension DCHDefaultRecordingBuffer {
    
    func makeDirectoryPath() -> String {
        
        return "\(NSTemporaryDirectory())DCHRecordingBuffer"
    }
    
    func makeDirectoryIfNeeded() throws {
        
        let directoryPath = makeDirectoryPath()
        
        guard !fileManager.fileExists(atPath: directoryPath) else {
            return
        }
        
        try fileManager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)
    }
}

// MARK: - Frame file

private class FrameFile: Equatable {
    
    let creationDate: Date
    let filePath: String
    
    init(
        creationDate: Date,
        filePath: String
    ) {
        
        self.creationDate = creationDate
        self.filePath = filePath
    }
    
    static func == (lhs: FrameFile, rhs: FrameFile) -> Bool {
        
        return lhs.filePath == rhs.filePath
    }
}


