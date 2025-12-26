//
//  BluetoothService.swift
//  ActorCoreBluetooth
//
//  Created by Konstantin Polin on 8/1/25.
//  Licensed under the MIT License. See LICENSE file in the project root.
//

import Foundation
import CoreBluetooth
internal import ActorCoreBluetoothRuntime

/// Sendable wrapper for Bluetooth services
public struct BluetoothService: Sendable {
    public let uuid: String
    public let isPrimary: Bool
    public let characteristics: [BluetoothCharacteristic]?
    
    internal let cbService: CBService
    
    init(cbService: CBService, characteristics: [BluetoothCharacteristic]? = nil) {
        self.uuid = cbService.uuid.uuidString
        self.isPrimary = cbService.isPrimary
        self.characteristics = characteristics
        self.cbService = cbService
    }
}
