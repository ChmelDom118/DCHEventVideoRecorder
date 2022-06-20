//
//  DCHVideoSegmentBufferExporter.swift
//  bp-video-event-recorder
//
//  Created by Dominik Chmelík on 20.05.2022.
//

import AVFoundation

protocol DCHVideoSegmentBufferExporter: AnyObject {
    
    func export(
        segmentBuffer: DCHSegmentBuffer,
        completion: @escaping (Result<DCHCapturedVideoSegment, Error>) -> Void
    )
    
    func release() throws
}
