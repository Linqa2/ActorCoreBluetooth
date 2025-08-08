//
//  LogLevel.swift
//  ActorCoreBluetooth
//
//  Created by Konstantin Polin on 8/3/25.
//  Licensed under the MIT License. See LICENSE file in the project root.
//

import Foundation
import os.log

public enum LogLevel: String, Sendable, CaseIterable {
    case debug = "debug"
    case info = "info"
    case notice = "notice"
    case warning = "warning"
    case error = "error"
    case fault = "fault"
    
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .notice: return .default
        case .warning: return .error
        case .error: return .error
        case .fault: return .fault
        }
    }
}
