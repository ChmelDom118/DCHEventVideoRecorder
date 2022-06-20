//
//  DCHRecorderConfiguration.swift
//  bp-video-event-recorder
//
//  Created by Dominik Chmelík on 10.03.2022.
//

import Foundation

public struct DCHRecorderConfiguration {
    
    public let recordQuality: DCHVideoQuality
    public let exportSettings: DCHExportSettings
    public let framerate: DCHFramerate
    public let backwardOffset: TimeInterval
    
    public init(
        recordQuality: DCHVideoQuality,
        exportSettings: DCHExportSettings,
        framerate: DCHFramerate,
        backwardOffset: TimeInterval
    ) {
    
        self.recordQuality = recordQuality
        self.exportSettings = exportSettings
        self.framerate = framerate
        self.backwardOffset = backwardOffset
    }
    
    public static let `default` = DCHRecorderConfiguration(
        recordQuality: .medium,
        exportSettings: DCHExportSettings(quality: .medium, codec: .preffered, format: .mp4),
        framerate: ._30fps,
        backwardOffset: 3.0
    )
}

public struct DCHExportSettings {
    
    public let quality: DCHVideoQuality
    public let codec: DCHCodec
    public let format: DCHFormat
    
    public init(
        quality: DCHVideoQuality,
        codec: DCHCodec,
        format: DCHFormat
    ) {
        
        self.quality = quality
        self.codec = codec
        self.format = format
    }
}

public enum DCHVideoQuality {
    
    /** 640x480 */
    case low
    
    /** 1280x720 */
    case medium
    
    /** 1920x1080 */
    case high
    
    /** 3840x2160 */
    case ultra
}

public enum DCHFramerate: Int {
    
    case _24fps = 24
    case _30fps = 30
    case _60fps = 60
}

public enum DCHCodec {
    
    case preffered
}

public enum DCHFormat {
    
    case mp4
    case mov
}
