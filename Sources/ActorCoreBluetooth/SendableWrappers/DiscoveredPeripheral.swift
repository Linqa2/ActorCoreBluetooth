//
//  DiscoveredPeripheral.swift
//  ActorCoreBluetooth
//
//  Created by Konstantin Polin on 8/1/25.
//  Licensed under the MIT License. See LICENSE file in the project root.
//

import Foundation
import CoreBluetooth

/// Represents a discovered peripheral that can be connected to
public struct DiscoveredPeripheral: Sendable {
    public let identifier: UUID
    public let name: String?
    public let rssi: Int
    public let advertisementData: AdvertisementData
    
    internal let cbPeripheral: CBPeripheral
    
    init(cbPeripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
        self.identifier = cbPeripheral.identifier
        self.name = cbPeripheral.name
        self.rssi = rssi.intValue
        self.advertisementData = AdvertisementData(cbAdvertisementData: advertisementData)
        self.cbPeripheral = cbPeripheral
    }
}
