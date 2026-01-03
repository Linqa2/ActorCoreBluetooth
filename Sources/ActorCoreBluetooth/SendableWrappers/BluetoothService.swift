//
//  BluetoothService.swift
//  ActorCoreBluetooth
//
//  Created by Konstantin Polin on 8/1/25.
//  Licensed under the MIT License. See LICENSE file in the project root.
//

import Foundation
import CoreBluetooth

/// Sendable wrapper for Bluetooth services
public struct BluetoothService: Sendable {
    public let uuid: String
    public let isPrimary: Bool
    public let characteristics: [BluetoothCharacteristic]?
    
    internal let cbService: Unchecked<CBService>
    
    init(cbService: CBService, characteristics: [BluetoothCharacteristic]? = nil) {
        self.uuid = cbService.uuid.uuidString
        self.isPrimary = cbService.isPrimary
        self.characteristics = characteristics
        self.cbService = Unchecked(cbService)
    }
    
    // MARK: - Escape Hatch: CoreBluetooth Object Access
    
    /// Access the underlying CBService for advanced use cases.
    /// - Warning: Bypasses actor-based safety.
    public func underlyingService() -> CBService {
        return cbService.value
    }
}
