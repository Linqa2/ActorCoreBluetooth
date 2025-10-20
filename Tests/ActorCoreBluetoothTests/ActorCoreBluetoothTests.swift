import XCTest
import CoreBluetooth
@testable import ActorCoreBluetooth

@MainActor
final class ActorCoreBluetoothTests: XCTestCase {
    
    // MARK: - PeripheralState Tests
    
    func testPeripheralStateMapping() {
        XCTAssertEqual(PeripheralState(cbState: .disconnected), .disconnected)
        XCTAssertEqual(PeripheralState(cbState: .connecting), .connecting)
        XCTAssertEqual(PeripheralState(cbState: .connected), .connected)
        XCTAssertEqual(PeripheralState(cbState: .disconnecting), .disconnecting)
    }
    
    // MARK: - CharacteristicProperties Tests
    
    func testCharacteristicPropertiesMapping() {
        let cbProperties: CBCharacteristicProperties = [.read, .write, .notify]
        let properties = CharacteristicProperties(cbProperties: cbProperties)
        
        XCTAssertTrue(properties.contains(.read))
        XCTAssertTrue(properties.contains(.write))
        XCTAssertTrue(properties.contains(.notify))
        XCTAssertFalse(properties.contains(.indicate))
        XCTAssertFalse(properties.contains(.broadcast))
    }
    
    func testCharacteristicPropertiesAllFlags() {
        let cbProperties: CBCharacteristicProperties = [
            .broadcast,
            .read,
            .writeWithoutResponse,
            .write,
            .notify,
            .indicate,
            .authenticatedSignedWrites,
            .extendedProperties
        ]
        
        let properties = CharacteristicProperties(cbProperties: cbProperties)
        
        XCTAssertTrue(properties.contains(.broadcast))
        XCTAssertTrue(properties.contains(.read))
        XCTAssertTrue(properties.contains(.writeWithoutResponse))
        XCTAssertTrue(properties.contains(.write))
        XCTAssertTrue(properties.contains(.notify))
        XCTAssertTrue(properties.contains(.indicate))
        XCTAssertTrue(properties.contains(.authenticatedSignedWrites))
        XCTAssertTrue(properties.contains(.extendedProperties))
    }
    
    func testCharacteristicPropertiesEmpty() {
        let cbProperties: CBCharacteristicProperties = []
        let properties = CharacteristicProperties(cbProperties: cbProperties)
        
        XCTAssertFalse(properties.contains(.read))
        XCTAssertFalse(properties.contains(.write))
        XCTAssertFalse(properties.contains(.notify))
        XCTAssertEqual(properties.rawValue, 0)
    }
    
    // MARK: - AdvertisementData Tests
    
    func testAdvertisementDataParsing() {
        let testUUID = CBUUID(string: "180F")
        let testData = Data([0x01, 0x02, 0x03])
        
        let cbAdvertisementData: [String: Any] = [
            CBAdvertisementDataLocalNameKey: "Test Device",
            CBAdvertisementDataManufacturerDataKey: testData,
            CBAdvertisementDataServiceUUIDsKey: [testUUID],
            CBAdvertisementDataServiceDataKey: [testUUID: testData],
            CBAdvertisementDataTxPowerLevelKey: -20,
            CBAdvertisementDataIsConnectable: true
        ]
        
        let advertisementData = AdvertisementData(cbAdvertisementData: cbAdvertisementData)
        
        XCTAssertEqual(advertisementData.localName, "Test Device")
        XCTAssertEqual(advertisementData.manufacturerData, testData)
        XCTAssertEqual(advertisementData.serviceUUIDs, ["180F"])
        XCTAssertEqual(advertisementData.serviceData?["180F"], testData)
        XCTAssertEqual(advertisementData.txPowerLevel, -20)
        XCTAssertEqual(advertisementData.isConnectable, true)
    }
    
    func testAdvertisementDataEmpty() {
        let advertisementData = AdvertisementData(cbAdvertisementData: [:])
        
        XCTAssertNil(advertisementData.localName)
        XCTAssertNil(advertisementData.manufacturerData)
        XCTAssertNil(advertisementData.serviceUUIDs)
        XCTAssertNil(advertisementData.serviceData)
        XCTAssertNil(advertisementData.txPowerLevel)
        XCTAssertNil(advertisementData.isConnectable)
    }
    
    // MARK: - Logger Tests
    
    func testLoggerConvenienceMethods() {
        let logger = TestLogger()
        
        logger.centralInfo("Central test")
        XCTAssertEqual(logger.lastCategory, .central)
        XCTAssertEqual(logger.lastLevel, .info)
        XCTAssertEqual(logger.lastMessage, "Central test")
        
        logger.errorError("Error test")
        XCTAssertEqual(logger.lastCategory, .error)
        XCTAssertEqual(logger.lastLevel, .error)
        XCTAssertEqual(logger.lastMessage, "Error test")
        
        logger.connectionWarning("Connection warning")
        XCTAssertEqual(logger.lastCategory, .connection)
        XCTAssertEqual(logger.lastLevel, .warning)
        XCTAssertEqual(logger.lastMessage, "Connection warning")
    }
    
    func testLoggerWithContext() {
        let logger = TestLogger()
        let testUUID = UUID()
        
        logger.logCharacteristic(
            operation: "Reading",
            uuid: "180F",
            peripheralID: testUUID,
            dataLength: 10,
            context: ["extra": "info"]
        )
        
        XCTAssertEqual(logger.lastCategory, .characteristic)
        XCTAssertEqual(logger.lastLevel, .info)
        XCTAssertEqual(logger.lastMessage, "Reading")
        
        let context = logger.lastContext
        XCTAssertEqual(context?["characteristicUUID"] as? String, "180F")
        XCTAssertEqual(context?["peripheralID"] as? String, testUUID.uuidString)
        XCTAssertEqual(context?["dataLength"] as? Int, 10)
        XCTAssertEqual(context?["extra"] as? String, "info")
    }
    

    
    // MARK: - BluetoothCentral Initialization Tests
    
    func testBluetoothCentralInitialization() {
        let logger = TestLogger()
        let central = BluetoothCentral(logger: logger)
        
        // Should initialize without issues
        XCTAssertNotNil(central)
        XCTAssertEqual(central.connectedPeripheralIDs.count, 0)
    }
    
    // MARK: - LogLevel and LogCategory Tests
    
    func testLogLevelOSLogMapping() {
        XCTAssertEqual(LogLevel.debug.osLogType, .debug)
        XCTAssertEqual(LogLevel.info.osLogType, .info)
        XCTAssertEqual(LogLevel.notice.osLogType, .default)
        XCTAssertEqual(LogLevel.warning.osLogType, .error)
        XCTAssertEqual(LogLevel.error.osLogType, .error)
        XCTAssertEqual(LogLevel.fault.osLogType, .fault)
    }
    
    func testLogCategoryUserFacing() {
        let userFacingCategories = LogCategory.userFacing
        
        XCTAssertTrue(userFacingCategories.contains(.central))
        XCTAssertTrue(userFacingCategories.contains(.peripheral))
        XCTAssertTrue(userFacingCategories.contains(.connection))
        XCTAssertTrue(userFacingCategories.contains(.characteristic))
        XCTAssertTrue(userFacingCategories.contains(.service))
        XCTAssertTrue(userFacingCategories.contains(.stream))
        XCTAssertTrue(userFacingCategories.contains(.error))
        XCTAssertFalse(userFacingCategories.contains(.internal))
    }
}
