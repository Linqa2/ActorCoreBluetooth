//
//  ConsoleBluetoothLogger.swift
//  ActorCoreBluetooth
//
//  Created by Konstantin Polin on 8/1/25.
//  Licensed under the MIT License. See LICENSE file in the project root.
//

import Foundation

public final class ConsoleBluetoothLogger: BluetoothLogger {
    private let minimumLevel: LogLevel
    private let enabledCategories: Set<LogCategory>
    
    public init(minimumLevel: LogLevel = .info, enabledCategories: Set<LogCategory> = LogCategory.userFacing) {
        self.minimumLevel = minimumLevel
        self.enabledCategories = enabledCategories
    }
    
    public func log(level: LogLevel, category: LogCategory, message: String, context: [String: Any]?) {
        guard enabledCategories.contains(category) else { return }
        guard level.priority >= minimumLevel.priority else { return }
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let contextString = context?.map { key, value in
            "\(key): \(value)"
        }.joined(separator: ", ") ?? ""
        
        print("[\(timestamp)] [\(level.rawValue.uppercased())] [\(category.rawValue)] \(message)\(contextString)")
    }
}

private extension LogLevel {
    var priority: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .notice: return 2
        case .warning: return 3
        case .error: return 4
        case .fault: return 5
        }
    }
}
