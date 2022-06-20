//
//  DCHVideoRecorderDelegate.swift
//  bp-video-event-recorder
//
//  Created by Dominik Chmelík on 25.03.2022.
//

import Foundation

public protocol DCHVideoRecorderDelegate: AnyObject {
    
    func videoRecorderDidChangeState(
        _ oldState: DCHVideoRecorderState,
        _ newState: DCHVideoRecorderState
    )
}
