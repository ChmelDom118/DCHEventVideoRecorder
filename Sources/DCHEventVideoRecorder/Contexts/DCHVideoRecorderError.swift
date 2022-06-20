//
//  DCHVideoRecorderError.swift
//  bp-video-event-recorder
//
//  Created by Dominik Chmelík on 10.03.2022.
//

import Foundation

public enum DCHVideoRecorderError: Error {
    
    case alreadyRunning
    case notRunning
    case runtimeConfigChange
    case corruptedBuffer
}
