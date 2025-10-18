//
//  BluetoothLogger+Helpers.swift
//  ActorCoreBluetooth
//
//  Created by Konstantin Polin on 10/18/25.
//  Licensed under the MIT License. See LICENSE file in the project root.
//

import Foundation

// MARK: - Convenience Logging Methods
extension BluetoothLogger {
    
    // MARK: - Central Operations
    
    func logCentral(_ level: LogLevel, _ message: String, context: [String: Any]? = nil) {
        log(level: level, category: .central, message: message, context: context)
    }
    
    func centralInfo(_ message: String, context: [String: Any]? = nil) {
        logCentral(.info, message, context: context)
    }
    
    func centralDebug(_ message: String, context: [String: Any]? = nil) {
        logCentral(.debug, message, context: context)
    }
    
    func centralNotice(_ message: String, context: [String: Any]? = nil) {
        logCentral(.notice, message, context: context)
    }
    
    func centralWarning(_ message: String, context: [String: Any]? = nil) {
        logCentral(.warning, message, context: context)
    }
    
    // MARK: - Connection Events
    
    func logConnection(event: String, peripheral: String, peripheralID: UUID, context: [String: Any]? = nil) {
        var fullContext = context ?? [:]
        fullContext["peripheralName"] = peripheral
        fullContext["peripheralID"] = peripheralID.uuidString
        log(level: .info, category: .connection, message: event, context: fullContext)
    }
    
    func connectionInfo(_ message: String, context: [String: Any]? = nil) {
        log(level: .info, category: .connection, message: message, context: context)
    }
    
    func connectionDebug(_ message: String, context: [String: Any]? = nil) {
        log(level: .debug, category: .connection, message: message, context: context)
    }
    
    func connectionNotice(_ message: String, context: [String: Any]? = nil) {
        log(level: .notice, category: .connection, message: message, context: context)
    }
    
    func connectionWarning(_ message: String, context: [String: Any]? = nil) {
        log(level: .warning, category: .connection, message: message, context: context)
    }
    
    // MARK: - Characteristic Operations
    
    func logCharacteristic(operation: String, uuid: String, peripheralID: UUID, dataLength: Int? = nil, context: [String: Any]? = nil) {
        var fullContext = context ?? [:]
        fullContext["characteristicUUID"] = uuid
        fullContext["peripheralID"] = peripheralID.uuidString
        if let dataLength = dataLength {
            fullContext["dataLength"] = dataLength
        }
        log(level: .info, category: .characteristic, message: operation, context: fullContext)
    }
    
    func characteristicInfo(_ message: String, context: [String: Any]? = nil) {
        log(level: .info, category: .characteristic, message: message, context: context)
    }
    
    func characteristicDebug(_ message: String, context: [String: Any]? = nil) {
        log(level: .debug, category: .characteristic, message: message, context: context)
    }
    
    func characteristicWarning(_ message: String, context: [String: Any]? = nil) {
        log(level: .warning, category: .characteristic, message: message, context: context)
    }
    
    // MARK: - Service Discovery
    
    func logServiceDiscovery(count: Int, peripheralID: UUID, context: [String: Any]? = nil) {
        var fullContext = context ?? [:]
        fullContext["serviceCount"] = count
        fullContext["peripheralID"] = peripheralID.uuidString
        log(level: .info, category: .service, message: "Discovered services", context: fullContext)
    }
    
    func serviceInfo(_ message: String, context: [String: Any]? = nil) {
        log(level: .info, category: .service, message: message, context: context)
    }
    
    func serviceDebug(_ message: String, context: [String: Any]? = nil) {
        log(level: .debug, category: .service, message: message, context: context)
    }
    
    func serviceWarning(_ message: String, context: [String: Any]? = nil) {
        log(level: .warning, category: .service, message: message, context: context)
    }
    
    // MARK: - Error Logging
    
    func logTimeout(operation: String, timeout: TimeInterval, context: [String: Any]? = nil) {
        var fullContext = context ?? [:]
        fullContext["operation"] = operation
        fullContext["timeout"] = timeout
        log(level: .warning, category: .error, message: "Operation timeout", context: fullContext)
    }
    
    func errorWarning(_ message: String, context: [String: Any]? = nil) {
        log(level: .warning, category: .error, message: message, context: context)
    }
    
    func errorError(_ message: String, context: [String: Any]? = nil) {
        log(level: .error, category: .error, message: message, context: context)
    }
    
    // MARK: - Internal Operations (Internal)
    
    func internalDebug(_ message: String, context: [String: Any]? = nil) {
        log(level: .debug, category: .internal, message: message, context: context)
    }
    
    func internalInfo(_ message: String, context: [String: Any]? = nil) {
        log(level: .info, category: .internal, message: message, context: context)
    }
    
    func internalWarning(_ message: String, context: [String: Any]? = nil) {
        log(level: .warning, category: .internal, message: message, context: context)
    }
    
    // MARK: - Stream Operations
    
    func streamInfo(_ message: String, context: [String: Any]? = nil) {
        log(level: .info, category: .stream, message: message, context: context)
    }
    
    func streamDebug(_ message: String, context: [String: Any]? = nil) {
        log(level: .debug, category: .stream, message: message, context: context)
    }
    
    // MARK: - Peripheral Operations
    
    func peripheralInfo(_ message: String, context: [String: Any]? = nil) {
        log(level: .info, category: .peripheral, message: message, context: context)
    }
    
    func peripheralDebug(_ message: String, context: [String: Any]? = nil) {
        log(level: .debug, category: .peripheral, message: message, context: context)
    }
    
    func peripheralNotice(_ message: String, context: [String: Any]? = nil) {
        log(level: .notice, category: .peripheral, message: message, context: context)
    }
}
