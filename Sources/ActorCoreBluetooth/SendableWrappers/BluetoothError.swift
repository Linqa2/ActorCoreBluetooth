//
//  BluetoothError.swift
//  ActorCoreBluetooth
//
//  Created by Konstantin Polin on 8/1/25.
//  Licensed under the MIT License. See LICENSE file in the project root.
//

import Foundation

public enum BluetoothError: Error, Sendable {
    case centralManagerNotInitialized
    case connectionTimeout
    case connectionFailed
    case peripheralNotFound
    case invalidState
    case peripheralNotConnected
    case operationNotSupported
    case serviceNotFound
    case characteristicNotFound
    case scanTimeout
    case operationCancelled
    case operationInProgress
    
    case bluetoothPoweredOff
    case bluetoothUnauthorized
    case bluetoothUnsupported
}
