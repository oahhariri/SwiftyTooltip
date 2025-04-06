//
//  Task+Ext.swift
//  SwiftyTooltip
//
//  Created by Abdulrahman Ameen Hariri on 06/04/2025.
//

import SwiftUI
import Foundation

internal extension Task where Success == Never, Failure == Never {
    
    static func sleep(seconds: Double) async throws {
        if #available(iOS 16.0, *) {
            try await Task.sleep(for: .seconds(seconds))
        } else {
            let duration = UInt64(seconds * 1_000_000_000)
            try await Task.sleep(nanoseconds: duration)
        }
    }
    
    static func sleep(milliseconds: Double) async throws {
        if #available(iOS 16.0, *) {
            try await Task.sleep(for: .microseconds(milliseconds))
        } else {
            let duration = UInt64(milliseconds * 1_000_000)
            try await Task.sleep(nanoseconds: duration)
        }
    }
}
