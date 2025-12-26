//
//  TimedOperation.swift
//  ActorCoreBluetooth
//
//  Created by Konstantin Polin on 8/1/25.
//  Licensed under the MIT License. See LICENSE file in the project root.
//

import Foundation
internal import ActorCoreBluetoothRuntime

/// Generic timed operation for managing continuations with timeout support
@MainActor
final class TimedOperation<T: Sendable> {
    private var continuation: CheckedContinuation<T, Error>?
    private var task: Task<Void, Never>?
    private let operationName: String
    private let logger: BluetoothLogger?
    
    init(operationName: String = "Unknown", logger: BluetoothLogger?) {
        self.operationName = operationName
        self.logger = logger
        logger?.internalDebug("TimedOperation created", context: ["operation": operationName])
    }
    
    func setup(_ cont: CheckedContinuation<T, Error>) {
        assert(continuation == nil, "Double continuation set for \(operationName)!")
        logger?.internalDebug("Continuation set", context: ["operation": operationName])
        continuation = cont
    }
    
    func resumeOnce(with result: Result<T, Error>) {
        guard let cont = continuation else {
            logger?.internalWarning("Attempted to resume but no continuation exists", context: ["operation": operationName])
            return
        }
        continuation = nil
        
        task?.cancel()
        task = nil
        
        switch result {
        case .success(let value):
            logger?.internalDebug("Operation completed successfully", context: ["operation": operationName])
            cont.resume(returning: value)
        case .failure(let error):
            logger?.internalWarning("Operation failed", context: [
                "operation": operationName,
                "error": error.localizedDescription
            ])
            cont.resume(throwing: error)
        }
    }
    
    func setTimeoutTask(timeout: TimeInterval, onTimeout: @escaping () -> Void) {
        setTimeoutTask(timeout: timeout, onTimeoutResult: {
            onTimeout()
            throw BluetoothError.connectionTimeout
        })
    }
    
    func setTimeoutTask(timeout: TimeInterval, onTimeoutResult: @escaping () throws -> T) {
        task?.cancel()
        
        logger?.internalDebug("Setting timeout task", context: [
            "operation": operationName,
            "timeout": timeout
        ])
                
        task = Task { [weak self, logger, operationName] in
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            
            guard !Task.isCancelled else {
                logger?.internalDebug("Timeout task cancelled", context: ["operation": operationName])
                return
            }
            
            await MainActor.run {
                // Only proceed if TimedOperation still exists and has active continuation
                guard let self = self, self.continuation != nil else {
                    logger?.internalDebug("Timeout occurred but TimedOperation no longer active", context: ["operation": operationName])
                    return
                }
                
                logger?.logTimeout(operation: operationName, timeout: timeout)
                
                // Execute the timeout handler and get result
                do {
                    let result = try onTimeoutResult()
                    self.resumeOnce(with: .success(result))
                } catch {
                    self.resumeOnce(with: .failure(error))
                }
            }
        }
    }
    
    func cancel() {
        logger?.internalInfo("Cancelling operation", context: ["operation": operationName])
        task?.cancel()
        task = nil
        continuation?.resume(throwing: CancellationError())
        continuation = nil
    }
    
    deinit {
        logger?.internalDebug("TimedOperation deallocated", context: ["operation": operationName])
        task?.cancel()
        if continuation != nil {
            logger?.internalWarning("TimedOperation deallocated with active continuation", context: ["operation": operationName])
        }
    }
}
