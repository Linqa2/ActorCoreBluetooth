//
//  CharacteristicProperties.swift
//  ActorCoreBluetooth
//
//  Created by Konstantin Polin on 8/1/25.
//  Licensed under the MIT License. See LICENSE file in the project root.
//

import Foundation
import CoreBluetooth

/// Sendable characteristic properties
public struct CharacteristicProperties: Sendable, OptionSet {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    
    public static let broadcast = CharacteristicProperties(rawValue: 1 << 0)
    public static let read = CharacteristicProperties(rawValue: 1 << 1)
    public static let writeWithoutResponse = CharacteristicProperties(rawValue: 1 << 2)
    public static let write = CharacteristicProperties(rawValue: 1 << 3)
    public static let notify = CharacteristicProperties(rawValue: 1 << 4)
    public static let indicate = CharacteristicProperties(rawValue: 1 << 5)
    public static let authenticatedSignedWrites = CharacteristicProperties(rawValue: 1 << 6)
    public static let extendedProperties = CharacteristicProperties(rawValue: 1 << 7)
    
    init(cbProperties: CBCharacteristicProperties) {
        var properties: UInt8 = 0
        if cbProperties.contains(.broadcast) { properties |= 1 << 0 }
        if cbProperties.contains(.read) { properties |= 1 << 1 }
        if cbProperties.contains(.writeWithoutResponse) { properties |= 1 << 2 }
        if cbProperties.contains(.write) { properties |= 1 << 3 }
        if cbProperties.contains(.notify) { properties |= 1 << 4 }
        if cbProperties.contains(.indicate) { properties |= 1 << 5 }
        if cbProperties.contains(.authenticatedSignedWrites) { properties |= 1 << 6 }
        if cbProperties.contains(.extendedProperties) { properties |= 1 << 7 }
        self.rawValue = properties
    }
}
