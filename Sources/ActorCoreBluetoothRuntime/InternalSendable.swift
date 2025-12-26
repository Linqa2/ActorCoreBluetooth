//
//  InternalSendable.swift
//  ActorCoreBluetoothRuntime
//
//  Created by Konstantin Polin on 8/1/25.
//  Licensed under the MIT License. See LICENSE file in the project root.
//

import CoreBluetooth

// MARK: - Sendable Extensions
// These conformances are isolated to the ActorCoreBluetoothRuntime module
// and do not leak to client code that imports ActorCoreBluetooth.
extension CBPeripheral: @unchecked @retroactive Sendable {}
extension CBCentralManager: @unchecked @retroactive Sendable {}
extension CBUUID: @unchecked @retroactive Sendable {}
extension CBCharacteristic: @unchecked @retroactive Sendable {}
extension CBService: @unchecked @retroactive Sendable {}
