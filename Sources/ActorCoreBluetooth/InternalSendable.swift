//
//  InternalSendable.swift
//  ActorCoreBluetooth
//
//  Created by Konstantin Polin on 8/1/25.
//  Licensed under the MIT License. See LICENSE file in the project root.
//

import CoreBluetooth

// MARK: - Sendable Extensions
extension CBPeripheral: @unchecked @retroactive Sendable {}
extension CBCentralManager: @unchecked @retroactive Sendable {}
extension CBUUID: @unchecked @retroactive Sendable {}
extension CBCharacteristic: @unchecked @retroactive Sendable {}
extension CBService: @unchecked @retroactive Sendable {}
