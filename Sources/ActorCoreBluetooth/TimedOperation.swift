//
//  TimedOperation.swift
//  ActorCoreBluetooth
//
//  Created by Konstantin Polin on 8/1/25.
//  Licensed under the MIT License. See LICENSE file in the project root.
//

import Foundation

/// Generic timed operation for managing continuations with timeout support
@MainActor
final class TimedOperation<T: Sendable> {
    private var continuation: CheckedContinuation<T, Error>?
    private var task: Task<Void, Never>?
    private let operationName: String
    private let logger: BluetoothLogger
    
    init(operationName: String = "Unknown", logger: BluetoothLogger) {
        self.operationName = operationName
        self.logger = logger
        logger.internalDebug("TimedOperation created", context: ["operation": operationName])
    }
    
    func setup(_ cont: CheckedContinuation<T, Error>) {
        assert(continuation == nil, "Double continuation set for \(operationName)!")
        logger.internalDebug("Continuation set", context: ["operation": operationName])
        continuation = cont
    }
    
    func resumeOnce(with result: Result<T, Error>) {
        guard let cont = continuation else {
            logger.internalWarning("Attempted to resume but no continuation exists", context: ["operation": operationName])
            return
        }
        continuation = nil
        
        // Cancel any active timeout task
        task?.cancel()
        task = nil
        
        switch result {
        case .success(let value):
            logger.internalDebug("Operation completed successfully", context: ["operation": operationName])
            cont.resume(returning: value)
        case .failure(let error):
            logger.internalWarning("Operation failed", context: [
                "operation": operationName,
                "error": error.localizedDescription
            ])
            cont.resume(throwing: error)
        }
    }
    
    func setTimeoutTask(timeout: TimeInterval, onTimeout: @escaping @MainActor () -> Void) {
        task?.cancel()
        
        logger.internalDebug("Setting timeout task", context: [
            "operation": operationName,
            "timeout": timeout
        ])
        
        task = Task {
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            if !Task.isCancelled {
                logger.logTimeout(operation: operationName, timeout: timeout)
                onTimeout()
            }
        }
    }
    
    func cancel() {
        logger.internalInfo("Cancelling operation", context: ["operation": operationName])
        task?.cancel()
        task = nil
        continuation?.resume(throwing: CancellationError())
        continuation = nil
    }
    
    deinit {
        logger.internalDebug("TimedOperation deallocated", context: ["operation": operationName])
        if continuation != nil {
            logger.internalWarning("TimedOperation deallocated with active continuation", context: ["operation": operationName])
        }
    }
}
