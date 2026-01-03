//
//  BluetoothCharacteristic.swift
//  ActorCoreBluetooth
//
//  Created by Konstantin Polin on 8/1/25.
//  Licensed under the MIT License. See LICENSE file in the project root.
//

import Foundation
import CoreBluetooth

/// Sendable wrapper for Bluetooth characteristics
public struct BluetoothCharacteristic: Sendable {
    public let uuid: String
    public let properties: CharacteristicProperties
    public let value: Data?
    
    internal let cbCharacteristic: Unchecked<CBCharacteristic>
    
    init(cbCharacteristic: CBCharacteristic) {
        self.uuid = cbCharacteristic.uuid.uuidString
        self.properties = CharacteristicProperties(cbProperties: cbCharacteristic.properties)
        self.value = cbCharacteristic.value
        self.cbCharacteristic = Unchecked(cbCharacteristic)
    }
    
    // MARK: - Escape Hatch: CoreBluetooth Object Access
    
    /// Access the underlying CBCharacteristic for advanced use cases.
    /// - Warning: Bypasses actor-based safety.
    public func underlyingCharacteristic() -> CBCharacteristic {
        return cbCharacteristic.value
    }
}
