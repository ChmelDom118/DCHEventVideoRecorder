//
//  DCHCaptureSessionError.swift
//  bp-video-event-recorder
//
//  Created by Dominik Chmelík on 25.03.2022.
//

import Foundation

public enum DCHCaptureSessionError: Error {
    
    case videoDeviceNotFound
    case cannotAddVideoInput
    case cannotAddVideoOutput
}
