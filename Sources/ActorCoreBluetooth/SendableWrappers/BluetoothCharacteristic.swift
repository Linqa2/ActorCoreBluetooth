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
    
    // Internal reference to CB object
    internal let cbCharacteristic: CBCharacteristic
    
    init(cbCharacteristic: CBCharacteristic) {
        self.uuid = cbCharacteristic.uuid.uuidString
        self.properties = CharacteristicProperties(cbProperties: cbCharacteristic.properties)
        self.value = cbCharacteristic.value
        self.cbCharacteristic = cbCharacteristic
    }
}
