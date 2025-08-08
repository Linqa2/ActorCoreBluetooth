//
//  PeripheralState.swift
//  ActorCoreBluetooth
//
//  Created by Konstantin Polin on 8/1/25.
//  Licensed under the MIT License. See LICENSE file in the project root.
//

import Foundation
import CoreBluetooth

public enum PeripheralState: Sendable {
    case disconnected
    case connecting
    case connected
    case disconnecting
    
    init(cbState: CBPeripheralState) {
        switch cbState {
        case .disconnected:
            self = .disconnected
        case .connecting:
            self = .connecting
        case .connected:
            self = .connected
        case .disconnecting:
            self = .disconnecting
        @unknown default:
            self = .disconnected
        }
    }
}

// MARK: - CustomDebugStringConvertible

extension PeripheralState: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .disconnected: return "disconnected"
        case .connecting: return "connecting"
        case .connected: return "connected"
        case .disconnecting: return "disconnecting"
        }
    }
}
