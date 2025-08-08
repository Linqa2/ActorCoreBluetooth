# ActorCoreBluetooth

**⚠️ Active Development - APIs may change**

A modern Swift Bluetooth library providing async/await APIs for CoreBluetooth using MainActor isolation.

## Features

- Swift 6 ready strict concurrency async/await APIs
- MainActor isolation for thread safety
- Comprehensive timeout support
- Stream-based monitoring with AsyncStream
- Built-in logging system
- Reconnection support

## Quick Example

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

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/Linqa2/ActorCoreBluetooth.git", from: "0.1.0-alpha")
]
```

## Requirements

- iOS 15.0+ / macOS 12.0+ / tvOS 15.0+ / watchOS 8.0+
- Swift 5.7+
- Xcode 14.0+

## Status

This library is in active development. APIs are subject to change until version 1.0.0.

## License

MIT License - see LICENSE file for details.
