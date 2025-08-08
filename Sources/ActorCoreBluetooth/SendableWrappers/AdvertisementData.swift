//
//  AdvertisementData.swift
//  ActorCoreBluetooth
//
//  Created by Konstantin Polin on 8/1/25.
//  Licensed under the MIT License. See LICENSE file in the project root.
//

import Foundation
import CoreBluetooth

/// Sendable wrapper for advertisement data
public struct AdvertisementData: Sendable {
    public let localName: String?
    public let manufacturerData: Data?
    public let serviceUUIDs: [String]?
    public let serviceData: [String: Data]?
    public let txPowerLevel: Int?
    public let isConnectable: Bool?
    
    init(cbAdvertisementData: [String: Any]) {
        self.localName = cbAdvertisementData[CBAdvertisementDataLocalNameKey] as? String
        self.manufacturerData = cbAdvertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        self.serviceUUIDs = (cbAdvertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?.map { $0.uuidString }
        self.serviceData = (cbAdvertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data])?.reduce(into: [:]) { result, pair in
            result[pair.key.uuidString] = pair.value
        }
        self.txPowerLevel = cbAdvertisementData[CBAdvertisementDataTxPowerLevelKey] as? Int
        self.isConnectable = cbAdvertisementData[CBAdvertisementDataIsConnectable] as? Bool
    }
}
