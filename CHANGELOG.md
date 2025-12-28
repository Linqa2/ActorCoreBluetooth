# Changelog

All notable changes to ActorCoreBluetooth will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Extensive testing on Bluetooth hardware (Nordic nRF52840 Dongle)
- API stabilization for 1.0.0 release

## [0.1.1-alpha] - 2024-12-27

### Added
- **Refactor:** Retroactive @unchecked Sendable conformances replaced with transport-level wrapper
- Added RSSI Reading Support with Async/Await API
- Added System-Connected Peripherals Retrieval

## [0.1.0-alpha] - 2024-10-22

### Added
- Initial release with core Bluetooth Central functionality
- Swift 6 strict concurrency compliance with MainActor isolation
- Comprehensive async/await APIs for CoreBluetooth Central operations
- Device scanning with service filtering and timeout support
- Robust connection/disconnection management with state monitoring
- Complete service and characteristic discovery
- Data reading and writing (both with and without response)
- Real-time notifications and characteristic value monitoring
- Stream-based monitoring with AsyncStream for connection states
- Built-in logging system with multiple categories and levels
- Timeout support for all operations
- Reconnection support for dropped connections
- **Central mode only** - does not support Bluetooth Peripheral mode

### Notes
- APIs are subject to change until version 1.0.0
- This is an alpha release - use with caution in production

### Supported Platforms
- iOS 15.0+
- macOS 12.0+
- tvOS 15.0+
- watchOS 8.0+

### Dependencies
- Swift 5.7+
- CoreBluetooth framework
