//
//  LogCategory.swift
//  ActorCoreBluetooth
//
//  Created by Konstantin Polin on 8/3/25.
//  Licensed under the MIT License. See LICENSE file in the project root.
//

import Foundation

public enum LogCategory: String, Sendable, CaseIterable {
    case central = "central"
    case peripheral = "peripheral"
    case connection = "connection"
    case characteristic = "characteristic"
    case service = "service"
    case stream = "stream"
    case error = "error"
    case `internal` = "internal"
    
    var description: String {
        switch self {
        case .central: return "Central manager operations (scanning, connecting, state changes)"
        case .peripheral: return "Connected peripheral operations (services, characteristics, reads/writes)"
        case .connection: return "Connection lifecycle events (connect, disconnect, state changes)"
        case .characteristic: return "Characteristic operations (read, write, notify, discover)"
        case .service: return "Service discovery operations"
        case .stream: return "Stream management and monitoring"
        case .error: return "Errors and failure conditions"
        case .internal: return "Internal implementation details and debugging"
        }
    }
    
    /// Categories that are relevant for end users (excludes internal implementation details)
    public static var userFacing: Set<LogCategory> {
        return [.central, .peripheral, .connection, .characteristic, .service, .stream, .error]
    }
}
