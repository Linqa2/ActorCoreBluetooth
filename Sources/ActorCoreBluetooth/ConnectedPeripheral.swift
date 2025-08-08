//  ConnectedPeripheral.swift
//  ActorCoreBluetooth
//
//  Created by Konstantin Polin on 8/1/25.
//  Licensed under the MIT License. See LICENSE file in the project root.
//

import Foundation
import CoreBluetooth

@MainActor
public final class ConnectedPeripheral {
    public let identifier: UUID
    public let name: String?
    public private(set) var state: PeripheralState
    
    // Internal CB object
    internal let cbPeripheral: CBPeripheral
    private var delegateProxy: ConnectedPeripheralDelegateProxy?
    
    // Dependency injection
    private let logger: BluetoothLogger
    
    // Response operations for peripheral operations
    private var serviceDiscoveryOperations: [String: TimedOperation<[BluetoothService]>] = [:]
    private var characteristicDiscoveryOperations: [String: TimedOperation<[BluetoothCharacteristic]>] = [:]
    private var characteristicReadOperations: [String: TimedOperation<Data?>] = [:]
    private var characteristicWriteOperations: [String: TimedOperation<Void>] = [:]
    private var notificationStateOperations: [String: TimedOperation<Void>] = [:]
    
    // Stream management for peripheral-level events
    private var serviceDiscoveryStreams: [UUID: AsyncStream<[BluetoothService]>.Continuation] = [:]
    private var characteristicValueStreams: [UUID: AsyncStream<(BluetoothCharacteristic, Data?)>.Continuation] = [:]
    private var notificationStreams: [UUID: AsyncStream<(BluetoothCharacteristic, Data?)>.Continuation] = [:]
    
    internal init(cbPeripheral: CBPeripheral, logger: BluetoothLogger) {
        self.identifier = cbPeripheral.identifier
        self.name = cbPeripheral.name
        self.state = PeripheralState(cbState: cbPeripheral.state)
        self.cbPeripheral = cbPeripheral
        self.logger = logger
        
        let proxy = ConnectedPeripheralDelegateProxy(peripheral: self, logger: logger)
        self.delegateProxy = proxy
        
        // Set proxy as delegate
        cbPeripheral.delegate = proxy
        
        logger.peripheralInfo("ConnectedPeripheral initialized", context: [
            "peripheralName": self.name ?? "Unknown",
            "peripheralID": self.identifier.uuidString
        ])
    }
    
    // MARK: - Service Discovery
    
    /// Discover services on this peripheral
    public func discoverServices(serviceUUIDs: [String]? = nil, timeout: TimeInterval? = nil) async throws -> [BluetoothService] {
        guard cbPeripheral.state == .connected else {
            logger.errorError("Cannot discover services: peripheral not connected", context: [
                "peripheralID": identifier.uuidString
            ])
            throw BluetoothError.peripheralNotConnected
        }
        
        let serviceInfo = serviceUUIDs?.joined(separator: ", ") ?? "all services"
        logger.serviceInfo("Discovering services", context: [
            "services": serviceInfo,
            "peripheralID": identifier.uuidString,
            "timeout": timeout as Any
        ])
        
        return try await withCheckedThrowingContinuation { continuation in
            let discovery = TimedOperation<[BluetoothService]>(
                operationName: "Service discovery",
                logger: logger
            )
            discovery.setup(continuation)
            
            serviceDiscoveryOperations["services"] = discovery
            
            // Setup timeout if provided
            if let timeout = timeout {
                logger.internalDebug("Setting service discovery timeout", context: ["timeout": timeout])
                discovery.setTimeoutTask(timeout: timeout) { [weak self] in
                    guard let self else { return }
                    self.logger.logTimeout(
                        operation: "Service discovery",
                        timeout: timeout,
                        context: ["peripheralID": self.identifier.uuidString]
                    )
                    self.serviceDiscoveryOperations.removeValue(forKey: "services")
                }
            }
            
            // Start service discovery
            let cbServiceUUIDs = serviceUUIDs?.compactMap { CBUUID(string: $0) }
            logger.internalDebug("Calling CBPeripheral.discoverServices")
            cbPeripheral.discoverServices(cbServiceUUIDs)
        }
    }
    
    /// Discover characteristics for a service
    public func discoverCharacteristics(for service: BluetoothService, characteristicUUIDs: [String]? = nil, timeout: TimeInterval? = nil) async throws -> [BluetoothCharacteristic] {
        guard cbPeripheral.state == .connected else {
            logger.errorError("Cannot discover characteristics: peripheral not connected", context: [
                "peripheralID": identifier.uuidString
            ])
            throw BluetoothError.peripheralNotConnected
        }
        
        let charInfo = characteristicUUIDs?.joined(separator: ", ") ?? "all characteristics"
        logger.characteristicInfo("Discovering characteristics", context: [
            "characteristics": charInfo,
            "serviceUUID": service.uuid,
            "peripheralID": identifier.uuidString,
            "timeout": timeout as Any
        ])
        
        return try await withCheckedThrowingContinuation { continuation in
            let discovery = TimedOperation<[BluetoothCharacteristic]>(
                operationName: "Characteristic discovery for \(service.uuid)",
                logger: logger
            )
            discovery.setup(continuation)
            
            let key = service.uuid
            characteristicDiscoveryOperations[key] = discovery
            
            // Setup timeout if provided
            if let timeout = timeout {
                logger.internalDebug("Setting characteristic discovery timeout", context: [
                    "timeout": timeout,
                    "serviceUUID": service.uuid
                ])
                discovery.setTimeoutTask(timeout: timeout) {[weak self] in
                    guard let self else { return }
                    self.logger.logTimeout(
                        operation: "Characteristic discovery",
                        timeout: timeout,
                        context: ["serviceUUID": service.uuid]
                    )
                    self.characteristicDiscoveryOperations.removeValue(forKey: key)
                }
            }
            
            // Start characteristic discovery
            let cbCharacteristicUUIDs = characteristicUUIDs?.compactMap { CBUUID(string: $0) }
            logger.internalDebug("Calling CBPeripheral.discoverCharacteristics", context: [
                "serviceUUID": service.uuid
            ])
            cbPeripheral.discoverCharacteristics(cbCharacteristicUUIDs, for: service.cbService)
        }
    }
    
    // MARK: - Characteristic Operations
    
    /// Read value from a characteristic
    public func readValue(for characteristic: BluetoothCharacteristic, timeout: TimeInterval? = nil) async throws -> Data? {
        guard cbPeripheral.state == .connected else {
            logger.errorError("Cannot read characteristic: peripheral not connected", context: [
                "peripheralID": identifier.uuidString
            ])
            throw BluetoothError.peripheralNotConnected
        }
        
        guard characteristic.properties.contains(.read) else {
            logger.errorError("Characteristic does not support read operations", context: [
                "characteristicUUID": characteristic.uuid
            ])
            throw BluetoothError.operationNotSupported
        }
        
        logger.logCharacteristic(
            operation: "Reading",
            uuid: characteristic.uuid,
            peripheralID: identifier,
            context: timeout.map { ["timeout": $0] }
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let read = TimedOperation<Data?>(
                operationName: "Read \(characteristic.uuid)",
                logger: logger
            )
            read.setup(continuation)
            
            let key = characteristic.uuid
            characteristicReadOperations[key] = read
            
            // Setup timeout if provided
            if let timeout = timeout {
                logger.internalDebug("Setting read timeout", context: [
                    "timeout": timeout,
                    "characteristicUUID": characteristic.uuid
                ])
                read.setTimeoutTask(timeout: timeout) { [weak self] in
                    guard let self else { return }
                    self.logger.logTimeout(
                        operation: "Read",
                        timeout: timeout,
                        context: ["characteristicUUID": characteristic.uuid]
                    )
                    self.characteristicReadOperations.removeValue(forKey: key)
                }
            }
            
            // Start read operation
            logger.internalDebug("Calling CBPeripheral.readValue", context: [
                "characteristicUUID": characteristic.uuid
            ])
            cbPeripheral.readValue(for: characteristic.cbCharacteristic)
        }
    }
    
    /// Write value to a characteristic (with response)
    public func writeValue(_ data: Data, for characteristic: BluetoothCharacteristic, timeout: TimeInterval? = nil) async throws {
        guard cbPeripheral.state == .connected else {
            logger.errorError("Cannot write characteristic: peripheral not connected", context: [
                "peripheralID": identifier.uuidString
            ])
            throw BluetoothError.peripheralNotConnected
        }
        
        guard characteristic.properties.contains(.write) else {
            logger.errorError("Characteristic does not support write operations", context: [
                "characteristicUUID": characteristic.uuid
            ])
            throw BluetoothError.operationNotSupported
        }
        
        logger.logCharacteristic(
            operation: "Writing",
            uuid: characteristic.uuid,
            peripheralID: identifier,
            dataLength: data.count,
            context: timeout.map { ["timeout": $0] }
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let write = TimedOperation<Void>(
                operationName: "Write \(characteristic.uuid)",
                logger: logger
            )
            write.setup(continuation)
            
            let key = characteristic.uuid
            characteristicWriteOperations[key] = write
            
            // Setup timeout if provided
            if let timeout = timeout {
                logger.internalDebug("Setting write timeout", context: [
                    "timeout": timeout,
                    "characteristicUUID": characteristic.uuid
                ])
                write.setTimeoutTask(timeout: timeout) { [weak self] in
                    guard let self else { return }
                    self.logger.logTimeout(
                        operation: "Write",
                        timeout: timeout,
                        context: ["characteristicUUID": characteristic.uuid]
                    )
                    self.characteristicWriteOperations.removeValue(forKey: key)
                }
            }
            
            // Start write operation
            logger.internalDebug("Calling CBPeripheral.writeValue", context: [
                "characteristicUUID": characteristic.uuid,
                "dataLength": data.count
            ])
            cbPeripheral.writeValue(data, for: characteristic.cbCharacteristic, type: .withResponse)
        }
    }
    
    /// Write value without response (fire and forget)
    public func writeValueWithoutResponse(_ data: Data, for characteristic: BluetoothCharacteristic) throws {
        guard cbPeripheral.state == .connected else {
            logger.errorError("Cannot write without response: peripheral not connected", context: [
                "peripheralID": identifier.uuidString
            ])
            throw BluetoothError.peripheralNotConnected
        }
        
        guard characteristic.properties.contains(.writeWithoutResponse) else {
            logger.errorError("Characteristic does not support write without response", context: [
                "characteristicUUID": characteristic.uuid
            ])
            throw BluetoothError.operationNotSupported
        }
        
        logger.logCharacteristic(
            operation: "Writing (no response)",
            uuid: characteristic.uuid,
            peripheralID: identifier,
            dataLength: data.count
        )
        
        // Write without response doesn't need continuation - fire and forget
        cbPeripheral.writeValue(data, for: characteristic.cbCharacteristic, type: .withoutResponse)
        logger.characteristicDebug("Write without response completed", context: [
            "characteristicUUID": characteristic.uuid
        ])
    }
    
    /// Set notification state for a characteristic
    public func setNotificationState(_ enabled: Bool, for characteristic: BluetoothCharacteristic, timeout: TimeInterval? = nil) async throws {
        guard cbPeripheral.state == .connected else {
            logger.errorError("Cannot set notification state: peripheral not connected", context: [
                "peripheralID": identifier.uuidString
            ])
            throw BluetoothError.peripheralNotConnected
        }
        
        guard characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) else {
            logger.errorError("Characteristic does not support notifications/indications", context: [
                "characteristicUUID": characteristic.uuid
            ])
            throw BluetoothError.operationNotSupported
        }
        
        let operation = enabled ? "Enabling" : "Disabling"
        logger.characteristicInfo("\(operation) notifications", context: [
            "characteristicUUID": characteristic.uuid,
            "peripheralID": identifier.uuidString,
            "timeout": timeout as Any
        ])
        
        return try await withCheckedThrowingContinuation { continuation in
            let notification = TimedOperation<Void>(
                operationName: "Notification state \(characteristic.uuid)",
                logger: logger
            )
            notification.setup(continuation)
            
            let key = characteristic.uuid
            notificationStateOperations[key] = notification
            
            // Setup timeout if provided
            if let timeout = timeout {
                logger.internalDebug("Setting notification state timeout", context: [
                    "timeout": timeout
                ])
                notification.setTimeoutTask(timeout: timeout) { [weak self] in
                    guard let self else { return }
                    self.logger.logTimeout(
                        operation: "Notification state change",
                        timeout: timeout,
                        context: ["characteristicUUID": characteristic.uuid]
                    )
                    self.notificationStateOperations.removeValue(forKey: key)
                }
            }
            
            // Set notification state
            logger.internalDebug("Calling CBPeripheral.setNotifyValue", context: [
                "enabled": enabled,
                "characteristicUUID": characteristic.uuid
            ])
            cbPeripheral.setNotifyValue(enabled, for: characteristic.cbCharacteristic)
        }
    }
    
    // MARK: - Stream Management
    
    /// Create monitor for service discovery events
    public func createServiceDiscoveryMonitor() -> (stream: AsyncStream<[BluetoothService]>, monitorID: UUID) {
        let monitorID = UUID()
        
        logger.streamInfo("Creating service discovery monitor", context: [
            "peripheralID": identifier.uuidString,
            "monitorID": monitorID.uuidString
        ])
        
        let stream = AsyncStream<[BluetoothService]> { continuation in
            serviceDiscoveryStreams[monitorID] = continuation
        }
        
        return (stream, monitorID)
    }
    
    /// Stop monitoring service discovery
    public func stopServiceDiscoveryMonitoring(_ monitorID: UUID) {
        logger.streamInfo("Stopping service discovery monitor", context: [
            "monitorID": monitorID.uuidString
        ])
        serviceDiscoveryStreams[monitorID]?.finish()
        serviceDiscoveryStreams.removeValue(forKey: monitorID)
    }
    
    /// Create monitor for characteristic value updates
    public func createCharacteristicValueMonitor() -> (stream: AsyncStream<(BluetoothCharacteristic, Data?)>, monitorID: UUID) {
        let monitorID = UUID()

        logger.streamInfo("Creating characteristic value monitor", context: [
            "peripheralID": identifier.uuidString,
            "monitorID": monitorID.uuidString
        ])
        
        let stream = AsyncStream<(BluetoothCharacteristic, Data?)> { continuation in
            characteristicValueStreams[monitorID] = continuation
        }
        
        return (stream, monitorID)
    }
    
    /// Stop monitoring characteristic values
    public func stopCharacteristicValueMonitoring(_ monitorID: UUID) {
        logger.streamInfo("Stopping characteristic value monitor", context: [
            "monitorID": monitorID.uuidString
        ])
        characteristicValueStreams[monitorID]?.finish()
        characteristicValueStreams.removeValue(forKey: monitorID)
    }
    
    /// Create monitor specifically for notifications
    public func createNotificationMonitor() -> (stream: AsyncStream<(BluetoothCharacteristic, Data?)>, monitorID: UUID) {
        let monitorID = UUID()
        
        logger.streamInfo("Creating notification monitor", context: [
            "peripheralID": identifier.uuidString,
            "monitorID": monitorID.uuidString
        ])
        
        let stream = AsyncStream<(BluetoothCharacteristic, Data?)> { continuation in
            notificationStreams[monitorID] = continuation
        }
        
        return (stream, monitorID)
    }
    
    /// Stop monitoring notifications
    public func stopNotificationMonitoring(_ monitorID: UUID) {
        logger.streamInfo("Stopping notification monitor", context: [
            "monitorID": monitorID.uuidString
        ])
        notificationStreams[monitorID]?.finish()
        notificationStreams.removeValue(forKey: monitorID)
    }
    
    // MARK: - Convenience Methods
    
    /// Full service and characteristic discovery
    public func discoverAllServicesAndCharacteristics(timeout: TimeInterval? = 10.0) async throws -> [BluetoothService] {
        logger.peripheralInfo("Starting complete discovery", context: [
            "peripheralID": identifier.uuidString
        ])
        
        let services = try await discoverServices(timeout: timeout)
        logger.logServiceDiscovery(count: services.count, peripheralID: identifier)
        
        var servicesWithCharacteristics: [BluetoothService] = []
        
        for service in services {
            logger.serviceDebug("Discovering characteristics for service", context: [
                "serviceUUID": service.uuid
            ])
            let characteristics = try await discoverCharacteristics(for: service, timeout: timeout)
            logger.characteristicDebug("Found characteristics for service", context: [
                "serviceUUID": service.uuid,
                "characteristicCount": characteristics.count
            ])
            
            let serviceWithCharacteristics = BluetoothService(
                cbService: service.cbService,
                characteristics: characteristics
            )
            servicesWithCharacteristics.append(serviceWithCharacteristics)
        }
        
        logger.peripheralNotice("Complete discovery finished", context: [
            "peripheralID": identifier.uuidString,
            "serviceCount": services.count
        ])
        return servicesWithCharacteristics
    }
    
    // MARK: - Internal Delegate Handling Methods
    
    // Called by delegate proxy when services are discovered
    internal func handleServiceDiscovery(services: [CBService]?, error: Error?) {
        logger.internalDebug("Processing service discovery response")
        
        if let discovery = serviceDiscoveryOperations["services"] {
            serviceDiscoveryOperations.removeValue(forKey: "services")
            
            if let error = error {
                logger.errorError("Service discovery failed", context: [
                    "error": error.localizedDescription
                ])
                discovery.resumeOnce(with: .failure(error))
            } else if let services = services {
                let bluetoothServices = services.map { BluetoothService(cbService: $0) }
                logger.logServiceDiscovery(count: bluetoothServices.count, peripheralID: identifier)
                discovery.resumeOnce(with: .success(bluetoothServices))
                
                // Also notify streams
                for continuation in serviceDiscoveryStreams.values {
                    continuation.yield(bluetoothServices)
                }
            } else {
                logger.serviceInfo("No services discovered")
                discovery.resumeOnce(with: .success([]))
                
                // Notify streams of empty result
                for continuation in serviceDiscoveryStreams.values {
                    continuation.yield([])
                }
            }
        }
    }
    
    // Called by delegate proxy when characteristics are discovered
    internal func handleCharacteristicDiscovery(for service: CBService, characteristics: [CBCharacteristic]?, error: Error?) {
        let key = service.uuid.uuidString
        
        logger.internalDebug("Processing characteristic discovery response", context: [
            "serviceUUID": service.uuid.uuidString
        ])
        
        if let discovery = characteristicDiscoveryOperations[key] {
            characteristicDiscoveryOperations.removeValue(forKey: key)
            
            if let error = error {
                logger.errorError("Characteristic discovery failed", context: [
                    "serviceUUID": service.uuid.uuidString,
                    "error": error.localizedDescription
                ])
                discovery.resumeOnce(with: .failure(error))
            } else if let characteristics = characteristics {
                let bluetoothCharacteristics = characteristics.map { BluetoothCharacteristic(cbCharacteristic: $0) }
                logger.characteristicInfo("Discovered characteristics", context: [
                    "serviceUUID": service.uuid.uuidString,
                    "count": bluetoothCharacteristics.count
                ])
                discovery.resumeOnce(with: .success(bluetoothCharacteristics))
            } else {
                logger.characteristicInfo("No characteristics discovered", context: [
                    "serviceUUID": service.uuid.uuidString
                ])
                discovery.resumeOnce(with: .success([]))
            }
        }
    }
    
    // Called by delegate proxy when characteristic value is updated
    internal func handleCharacteristicValueUpdate(for characteristic: CBCharacteristic, error: Error?) {
        let key = characteristic.uuid.uuidString
        let bluetoothCharacteristic = BluetoothCharacteristic(cbCharacteristic: characteristic)
        
        if let error = error {
            logger.errorError("Characteristic value update failed", context: [
                "characteristicUUID": characteristic.uuid.uuidString,
                "error": error.localizedDescription
            ])
        } else {
            logger.logCharacteristic(
                operation: "Value updated",
                uuid: characteristic.uuid.uuidString,
                peripheralID: identifier,
                dataLength: characteristic.value?.count
            )
        }
        
        // Handle read response continuations
        if let read = characteristicReadOperations[key] {
            characteristicReadOperations.removeValue(forKey: key)
            
            if let error = error {
                read.resumeOnce(with: .failure(error))
            } else {
                read.resumeOnce(with: .success(characteristic.value))
            }
        }
        
        // Always notify value streams (for both reads and notifications)
        for continuation in characteristicValueStreams.values {
            continuation.yield((bluetoothCharacteristic, characteristic.value))
        }
        
        // If this was a notification/indication, also notify notification streams
        if characteristic.isNotifying {
            logger.internalDebug("Notification received", context: [
                "characteristicUUID": characteristic.uuid.uuidString
            ])
            for continuation in notificationStreams.values {
                continuation.yield((bluetoothCharacteristic, characteristic.value))
            }
        }
    }
    
    // Called by delegate proxy when characteristic write completes
    internal func handleCharacteristicWrite(for characteristic: CBCharacteristic, error: Error?) {
        let key = characteristic.uuid.uuidString
        
        if let error = error {
            logger.errorError("Characteristic write failed", context: [
                "characteristicUUID": characteristic.uuid.uuidString,
                "error": error.localizedDescription
            ])
        } else {
            logger.logCharacteristic(
                operation: "Write completed",
                uuid: characteristic.uuid.uuidString,
                peripheralID: identifier
            )
        }
        
        if let write = characteristicWriteOperations[key] {
            characteristicWriteOperations.removeValue(forKey: key)
            
            if let error = error {
                write.resumeOnce(with: .failure(error))
            } else {
                write.resumeOnce(with: .success(()))
            }
        }
    }
    
    // Called by delegate proxy when notification state changes
    internal func handleNotificationStateUpdate(for characteristic: CBCharacteristic, error: Error?) {
        let key = characteristic.uuid.uuidString
        
        if let error = error {
            logger.errorError("Notification state update failed", context: [
                "characteristicUUID": characteristic.uuid.uuidString,
                "error": error.localizedDescription
            ])
        } else {
            let state = characteristic.isNotifying ? "enabled" : "disabled"
            logger.characteristicInfo("Notifications \(state)", context: [
                "characteristicUUID": characteristic.uuid.uuidString
            ])
        }
        
        if let notification = notificationStateOperations[key] {
            notificationStateOperations.removeValue(forKey: key)
            
            if let error = error {
                notification.resumeOnce(with: .failure(error))
            } else {
                notification.resumeOnce(with: .success(()))
            }
        }
    }
    
    /// Cancel all pending operations - called during disconnection
    internal func cancelAllPendingOperations() {
        logger.peripheralInfo("Cancelling all pending operations due to disconnection", context: [
            "peripheralID": identifier.uuidString
        ])
        
        var cancelledCount = 0
        
        // Cancel service discovery operations
        for (_, operation) in serviceDiscoveryOperations {
            operation.cancel()
            cancelledCount += 1
        }
        serviceDiscoveryOperations.removeAll()
        
        // Cancel characteristic discovery operations
        for (_, operation) in characteristicDiscoveryOperations {
            operation.cancel()
            cancelledCount += 1
        }
        characteristicDiscoveryOperations.removeAll()
        
        // Cancel characteristic read operations
        for (_, operation) in characteristicReadOperations {
            operation.cancel()
            cancelledCount += 1
        }
        characteristicReadOperations.removeAll()
        
        // Cancel characteristic write operations
        for (_, operation) in characteristicWriteOperations {
            operation.cancel()
            cancelledCount += 1
        }
        characteristicWriteOperations.removeAll()
        
        // Cancel notification state operations
        for (_, operation) in notificationStateOperations {
            operation.cancel()
            cancelledCount += 1
        }
        notificationStateOperations.removeAll()
        
        logger.internalInfo("All pending operations cancelled", context: [
            "peripheralID": identifier.uuidString,
            "cancelledOperations": cancelledCount
        ])
    }
}

// MARK: - Peripheral Delegate Proxy

/// Thin proxy for handling CB peripheral delegate callbacks
@MainActor
private final class ConnectedPeripheralDelegateProxy: NSObject, @preconcurrency CBPeripheralDelegate {
    
    private weak var peripheral: ConnectedPeripheral?
    private let logger: BluetoothLogger
    
    init(peripheral: ConnectedPeripheral, logger: BluetoothLogger) {
        self.peripheral = peripheral
        self.logger = logger
        super.init()
        logger.internalDebug("ConnectedPeripheralDelegateProxy initialized", context: [
            "peripheralID": peripheral.identifier.uuidString
        ])
    }
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        logger.internalDebug("CBPeripheralDelegate.didDiscoverServices called")
        self.peripheral?.handleServiceDiscovery(services: peripheral.services, error: error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        logger.internalDebug("CBPeripheralDelegate.didDiscoverCharacteristicsFor called", context: [
            "serviceUUID": service.uuid.uuidString
        ])
        self.peripheral?.handleCharacteristicDiscovery(for: service, characteristics: service.characteristics, error: error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        logger.internalDebug("CBPeripheralDelegate.didUpdateValueFor called", context: [
            "characteristicUUID": characteristic.uuid.uuidString
        ])
        self.peripheral?.handleCharacteristicValueUpdate(for: characteristic, error: error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        logger.internalDebug("CBPeripheralDelegate.didWriteValueFor called", context: [
            "characteristicUUID": characteristic.uuid.uuidString
        ])
        self.peripheral?.handleCharacteristicWrite(for: characteristic, error: error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        logger.internalDebug("CBPeripheralDelegate.didUpdateNotificationStateFor called", context: [
            "characteristicUUID": characteristic.uuid.uuidString
        ])
        self.peripheral?.handleNotificationStateUpdate(for: characteristic, error: error)
    }
}
