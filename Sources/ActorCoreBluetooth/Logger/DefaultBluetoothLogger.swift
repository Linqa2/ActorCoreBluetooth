//
//  DefaultBluetoothLogger.swift
//  ActorCoreBluetooth
//
//  Created by Konstantin Polin on 8/1/25.
//  Licensed under the MIT License. See LICENSE file in the project root.
//

import Foundation
import os.log

public final class DefaultBluetoothLogger: BluetoothLogger {
    private let subsystem = "com.actorcorebt.ActorCoreBluetooth"
    private let loggers: [LogCategory: Logger]
    
    public init() {
        // Create os.log Logger instances for each category
        var loggers: [LogCategory: Logger] = [:]
        for category in LogCategory.allCases {
            loggers[category] = Logger(subsystem: subsystem, category: category.rawValue)
        }
        self.loggers = loggers
    }
    
    public func log(level: LogLevel, category: LogCategory, message: String, context: [String: Any]?) {
        guard let logger = loggers[category] else { return }
        
        let contextString = context?.map { key, value in
            "\(key): \(value)"
        }.joined(separator: ", ") ?? ""
        
        let fullMessage = "\(message)\(contextString)"
        
        switch level {
        case .debug:
            logger.debug("\(fullMessage)")
        case .info:
            logger.info("\(fullMessage)")
        case .notice:
            logger.notice("\(fullMessage)")
        case .warning:
            logger.warning("\(fullMessage)")
        case .error:
            logger.error("\(fullMessage)")
        case .fault:
            logger.fault("\(fullMessage)")
        }
    }
}
