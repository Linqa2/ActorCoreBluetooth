//
//  TestLogger.swift
//  ActorCoreBluetooth
//
//  Created by Konstantin Polin on 8/6/25.
//

import Foundation
@testable import ActorCoreBluetooth

final class TestLogger: BluetoothLogger {
    // Helper class for thread-safe property storage
    private final class Box<T>: @unchecked Sendable {
        private let lock = NSLock()
        private var _value: T
        
        init(_ value: T) {
            _value = value
        }
        
        var value: T {
            get {
                lock.lock()
                defer { lock.unlock() }
                return _value
            }
            set {
                lock.lock()
                defer { lock.unlock() }
                _value = newValue
            }
        }
    }
    
    private let _lastLevel = Box<LogLevel?>(nil)
    private let _lastCategory = Box<LogCategory?>(nil)
    private let _lastMessage = Box<String?>(nil)
    private let _lastContext = Box<[String: Any]?>(nil)
    
    var lastLevel: LogLevel? { _lastLevel.value }
    var lastCategory: LogCategory? { _lastCategory.value }
    var lastMessage: String? { _lastMessage.value }
    var lastContext: [String: Any]? { _lastContext.value }
    
    func log(level: LogLevel, category: LogCategory, message: String, context: [String: Any]?) {
        _lastLevel.value = level
        _lastCategory.value = category
        _lastMessage.value = message
        _lastContext.value = context
    }
}
