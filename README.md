# ActorCoreBluetooth

[![Swift](https://img.shields.io/badge/Swift-5.7+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2015.0%2B%20%7C%20macOS%2012.0%2B%20%7C%20tvOS%2015.0%2B%20%7C%20watchOS%208.0%2B-blue.svg)](https://developer.apple.com)
[![Swift 6](https://img.shields.io/badge/Swift%206-Ready-green.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)
[![CI](https://github.com/Linqa2/ActorCoreBluetooth/actions/workflows/ci.yml/badge.svg)](https://github.com/Linqa2/ActorCoreBluetooth/actions)

**⚠️ v0.1.0-alpha - APIs may change**

A modern Swift Bluetooth library providing async/await APIs for CoreBluetooth using MainActor isolation. Built for Swift 6 with strict concurrency compliance and comprehensive logging.

**Note: This library only supports Bluetooth Central mode** - for scanning, connecting to, and communicating with Bluetooth peripherals. It does not support Bluetooth Peripheral mode (advertising or acting as a peripheral).

## Features

### Core Features
- **Swift 6 Ready**: Strict concurrency compliance with async/await APIs
- **MainActor Isolation**: Thread-safe operations with MainActor enforcement
- **Comprehensive Timeouts**: All operations support configurable timeout handling
- **Stream-based Monitoring**: Real-time monitoring with AsyncStream
- **Built-in Logging**: Comprehensive logging system with multiple categories
- **Reconnection Support**: Robust reconnection handling for dropped connections

### Bluetooth Operations
- **Device Scanning**: Flexible scanning with service filtering and timeout support
- **Connection Management**: Reliable connection/disconnection with state monitoring
- **Service Discovery**: Complete service and characteristic discovery
- **Data Reading**: Characteristic value reading with timeout support
- **Data Writing**: Both response-required and fire-and-forget writing
- **Notifications**: Real-time characteristic value notifications
- **RSSI Reading**: RSSI value reading with timeout support
- **Real-time Monitoring**: Live streams for connection states and characteristic updates

## Platform Support

| Platform | Minimum Version |
|----------|----------------|
| iOS      | 15.0+          |
| macOS    | 12.0+          |
| tvOS     | 15.0+          |
| watchOS  | 8.0+           |

## Quick Start

### Basic Usage

```swift
import ActorCoreBluetooth

@MainActor
func connectToDevice() async throws {
    let central = BluetoothCentral()
    
    // Scan for devices
    let devices = try await central.scanForPeripherals(timeout: 5.0)
    guard let device = devices.first else { return }
    
    // Connect
    let peripheral = try await central.connect(device, timeout: 10.0)
    
    // Discover and read
    let services = try await peripheral.discoverServices(timeout: 5.0)
    for service in services {
        let characteristics = try await peripheral.discoverCharacteristics(for: service)
        for characteristic in characteristics where characteristic.properties.contains(.read) {
            let data = try await peripheral.readValue(for: characteristic)
            print("Read \(data?.count ?? 0) bytes")
        }
    }
}
```

## Detailed Features & Examples

### Device Scanning

Scan for Bluetooth devices with flexible filtering options:

```swift
@MainActor
func scanForDevices() async throws {
    let central = BluetoothCentral()
    
    // Scan for all devices with 10-second timeout
    let allDevices = try await central.scanForPeripherals(timeout: 10.0)
    
    // Scan for specific services only
    let heartRateDevices = try await central.scanForPeripherals(
        withServices: ["180D"], // Heart Rate service
        timeout: 5.0
    )
    
    // Continuous scanning (no timeout)
    let devices = try await central.scanForPeripherals()
    try central.stopScanning() // Stop manually when needed
}
```

### Connection Management

Robust connection handling with automatic state management:

```swift
@MainActor
func connectionExample() async throws {
    let central = BluetoothCentral()
    let devices = try await central.scanForPeripherals(timeout: 5.0)
    
    guard let device = devices.first else { return }
    
    // Connect with timeout
    let peripheral = try await central.connect(device, timeout: 10.0)
    print("Connected to: \(peripheral.name ?? "Unknown")")
    
    // Check connection status
    let isConnected = central.isConnected(peripheral.identifier)
    print("Connection status: \(isConnected)")
    
    // Reconnect to previously connected device
    let reconnected = try await central.connect(peripheral, timeout: 10.0)
    
    // Disconnect
    try await central.disconnect(peripheral, timeout: 5.0)
}
```

### One-Step Scan and Connect

Convenient method for scanning and connecting in a single operation:

```swift
@MainActor
func scanAndConnect() async throws {
    let central = BluetoothCentral()
    
    let peripheral = try await central.scanAndConnect(
        withServices: ["180D"], // Heart Rate service
        scanTimeout: 5.0,
        connectTimeout: 10.0
    ) { device in
        // Custom device selection logic
        return device.name?.contains("MyDevice") == true
    }
    
    print("Connected to: \(peripheral.name ?? "Unknown")")
}
```

### Service and Characteristic Discovery

Complete discovery with flexible options:

```swift
@MainActor
func discoverServices(peripheral: ConnectedPeripheral) async throws {
    // Discover all services
    let allServices = try await peripheral.discoverServices(timeout: 5.0)
    
    // Discover specific services only
    let heartRateServices = try await peripheral.discoverServices(
        serviceUUIDs: ["180D"],
        timeout: 5.0
    )
    
    // Discover characteristics for a service
    if let service = allServices.first {
        let characteristics = try await peripheral.discoverCharacteristics(
            for: service,
            timeout: 5.0
        )
        
        // Or discover specific characteristics
        let specificChars = try await peripheral.discoverCharacteristics(
            for: service,
            characteristicUUIDs: ["2A37"], // Heart Rate Measurement
            timeout: 5.0
        )
    }
    
    // Complete discovery in one call
    let servicesWithCharacteristics = try await peripheral.discoverServicesWithCharacteristics(
        serviceUUIDs: ["180D"],
        characteristicUUIDs: ["2A37"],
        timeout: 10.0
    )
}
```

### Reading Data

Read characteristic values with proper error handling:

```swift
@MainActor
func readCharacteristics(peripheral: ConnectedPeripheral) async throws {
    let services = try await peripheral.discoverServices(timeout: 5.0)
    
    for service in services {
        let characteristics = try await peripheral.discoverCharacteristics(for: service)
        
        for characteristic in characteristics where characteristic.properties.contains(.read) {
            do {
                let data = try await peripheral.readValue(for: characteristic, timeout: 3.0)
                
                if let data = data {
                    print("Read \(data.count) bytes from \(characteristic.uuid)")
                    print("Data: \(data.map { String(format: "%02x", $0) }.joined(separator: " "))")
                } else {
                    print("No data available for \(characteristic.uuid)")
                }
            } catch {
                print("Failed to read \(characteristic.uuid): \(error)")
            }
        }
    }
}
```

### Writing Data

Write data to characteristics with both response styles:

```swift
@MainActor
func writeToCharacteristic(peripheral: ConnectedPeripheral, characteristic: BluetoothCharacteristic) async throws {
    let dataToWrite = Data([0x01, 0x02, 0x03, 0x04])
    
    if characteristic.properties.contains(.write) {
        // Write with response (reliable)
        try await peripheral.writeValue(dataToWrite, for: characteristic, timeout: 5.0)
        print("Write completed with response")
    }
    
    if characteristic.properties.contains(.writeWithoutResponse) {
        // Write without response (fast, fire-and-forget)
        try peripheral.writeValueWithoutResponse(dataToWrite, for: characteristic)
        print("Write sent without response")
    }
}
```

### Notifications and Real-time Monitoring

Set up real-time notifications and monitor characteristic changes:

```swift
@MainActor
func monitorNotifications(peripheral: ConnectedPeripheral) async throws {
    let services = try await peripheral.discoverServices(timeout: 5.0)
    
    for service in services {
        let characteristics = try await peripheral.discoverCharacteristics(for: service)
        
        for characteristic in characteristics where characteristic.properties.contains(.notify) {
            // Enable notifications
            try await peripheral.setNotificationState(true, for: characteristic, timeout: 3.0)
            print("Notifications enabled for \(characteristic.uuid)")
        }
    }
    
    // Create monitoring streams
    let (valueStream, monitorID) = peripheral.createCharacteristicValueMonitor()
    let (notifyStream, notifyMonitorID) = peripheral.createNotificationMonitor()
    
    // Important: Store monitor IDs and ensure proper cleanup
    defer {
        peripheral.stopCharacteristicValueMonitoring(monitorID)
        peripheral.stopNotificationMonitoring(notifyMonitorID)
    }
    
    // Start monitoring tasks - these will run concurrently
    Task {
        for await (characteristic, data) in valueStream {
            if let data = data {
                print("Value update for \(characteristic.uuid): \(data.count) bytes")
            }
        }
    }
    
    Task {
        for await (characteristic, data) in notifyStream {
            print("Notification from \(characteristic.uuid)")
        }
    }
    
    // Note: In a real app, you'd typically want to keep this function running
    // or manage the task lifecycle differently. This example shows the setup pattern.
}
```

### Connection State Monitoring

Monitor connection state changes in real-time:

```swift
@MainActor
func monitorConnectionState(central: BluetoothCentral, peripheralID: UUID) async {
    let (stateStream, monitorID) = central.createConnectionStateMonitor(for: peripheralID)
    
    // Important: Ensure proper cleanup
    defer {
        central.stopConnectionStateMonitoring(monitorID)
    }
    
    // Monitor connection state changes
    Task {
        for await state in stateStream {
            switch state {
            case .disconnected:
                print("Device disconnected")
            case .connecting:
                print("Device connecting...")
            case .connected:
                print("Device connected")
            case .disconnecting:
                print("Device disconnecting...")
            }
        }
    }
    
    // Or use the convenience method with automatic cleanup
    await central.withConnectionStateMonitoring(for: peripheralID) { stateStream in
        for await state in stateStream {
            print("Connection state: \(state)")
            
            // Break out when connected
            if state == .connected {
                break
            }
        }
    }
}
```

### RSSI Reading

Read signal strength (RSSI) values to check connection quality:

```swift
@MainActor
func checkSignalStrength(peripheral: ConnectedPeripheral) async throws {
    // Read RSSI value with timeout
    let rssi = try await peripheral.readRSSI(timeout: 3.0)
    print("Current signal strength: \(rssi) dBm")
    
    // Interpret signal strength
    if rssi > -50 {
        print("Excellent signal")
    } else if rssi > -70 {
        print("Good signal")
    } else if rssi > -85 {
        print("Fair signal")
    } else {
        print("Weak signal")
    }
}

// Example: Read RSSI periodically
@MainActor
func monitorRSSI(peripheral: ConnectedPeripheral) async throws {
    for _ in 0..<10 {
        let rssi = try await peripheral.readRSSI(timeout: 3.0)
        print("RSSI: \(rssi) dBm")
        try await Task.sleep(for: .seconds(2))
    }
}
```

### Comprehensive Logging

Built-in logging system with multiple categories and levels:

```swift
import os.log

@MainActor
func setupLogging() {
    // Use built-in OS logging
    let central = BluetoothCentral(logger: OSLogBluetoothLogger())
    
    // Or create a custom logger
    final class CustomLogger: BluetoothLogger {
        func log(level: LogLevel, category: LogCategory, message: String, context: [String: Any]?) {
            print("[\(level.rawValue.uppercased())] [\(category.rawValue)] \(message)")
            if let context = context {
                print("Context: \(context)")
            }
        }
    }
    
    let centralWithCustomLogger = BluetoothCentral(logger: CustomLogger())
    
    // Disable logging entirely
    let silentCentral = BluetoothCentral(logger: nil)
}
```

## Installation

### Swift Package Manager

Add this to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/Linqa2/ActorCoreBluetooth.git", exact: "v0.1.0-alpha")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/Linqa2/ActorCoreBluetooth.git`
3. Select version: `v0.1.0-alpha`

## Requirements

- **Swift**: 5.7+
- **Xcode**: 14.0+
- **Deployment Targets**:
  - iOS 15.0+
  - macOS 12.0+  
  - tvOS 15.0+
  - watchOS 8.0+
  
## Related resources

[Modernizing CoreBluetooth with Swift 6 Concurrency: The ActorCoreBluetooth Story](https://medium.com/@konst.polin/modernizing-corebluetooth-with-swift-6-concurrency-the-actorcorebluetooth-story-c5ff95b7d68a)


## License

MIT License - see [LICENSE](LICENSE) file for details.
