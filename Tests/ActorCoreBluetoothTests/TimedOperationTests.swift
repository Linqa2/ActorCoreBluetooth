//
//  TimedOperationTests.swift
//  ActorCoreBluetooth
//
//  Created by Konstantin Polin on 8/6/25.
//

import Foundation
import XCTest
@testable import ActorCoreBluetooth

@MainActor
final class TimedOperationTests: XCTestCase {
    
    func testTimedOperationBasicOperation() async throws {
        let logger = TestLogger()
        let operation = TimedOperation<String>(operationName: "Test", logger: logger)
        
        let result = try await withCheckedThrowingContinuation { continuation in
            operation.setup(continuation)
            
            // Simulate async completion
            Task {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                operation.resumeOnce(with: .success("Test Result"))
            }
        }
        
        XCTAssertEqual(result, "Test Result")
    }
    
    func testTimedOperationTimeout() async {
        let logger = TestLogger()
        let operation = TimedOperation<String>(operationName: "Timeout Test", logger: logger)
        
        do {
            let result: String = try await withCheckedThrowingContinuation { continuation in
                operation.setup(continuation)
                
                operation.setTimeoutTask(timeout: 0.1, onTimeout: {
                    print("timed out")
                })
                
                // Don't complete the operation - let it timeout
            }
            
            XCTFail("Should have thrown timeout error, got: \(result)")
        } catch BluetoothError.connectionTimeout {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testTimedOperationCancellation() async {
        let logger = TestLogger()
        let operation = TimedOperation<String>(operationName: "Cancel Test", logger: logger)
        
        do {
            let result: String = try await withCheckedThrowingContinuation { continuation in
                operation.setup(continuation)
                
                // Cancel immediately
                operation.cancel()
            }
            
            XCTFail("Should have thrown cancellation error, got: \(result)")
        } catch is CancellationError {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - testTimedOperationTimeoutIntegration
    func testTimedOperationTimeoutIntegration() async throws {
        let logger = TestLogger()
        let operation = TimedOperation<String>(
            operationName: "Integration Test",
            logger: logger
        )

        let clock = ContinuousClock()
        let start = clock.now

        do {
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                operation.setup(continuation)
                operation.setTimeoutTask(timeout: 0.1, onTimeout: {
                    // no-op
                })
            }
            XCTFail("Should have timed out")
        } catch BluetoothError.connectionTimeout {
            let elapsed = start.duration(to: clock.now) / .seconds(1)

            XCTAssertGreaterThanOrEqual(elapsed, 0.095, "Timeout should be close to the requested value")

            XCTAssertLessThanOrEqual(elapsed, 0.30, "Timeout shouldn't exceed a reasonable CI jitter")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    
    func testMultipleTimedOperationsIndependence() async throws {
        let logger = TestLogger()
        
        // Create multiple operations that should operate independently
        let operation1 = TimedOperation<String>(operationName: "Test 1", logger: logger)
        let operation2 = TimedOperation<Int>(operationName: "Test 2", logger: logger)
        
        async let result1: String = try withCheckedThrowingContinuation { continuation in
            Task {
                await operation1.setup(continuation)
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                await operation1.resumeOnce(with: .success("First"))
            }
        }
        
        async let result2: Int = try withCheckedThrowingContinuation { continuation in
            Task {
                await operation2.setup(continuation)
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                await operation2.resumeOnce(with: .success(42))
            }
        }
        
        let (r1, r2) = try await (result1, result2)
        XCTAssertEqual(r1, "First")
        XCTAssertEqual(r2, 42)
    }
    
    // MARK: - Custom Timeout Result Tests
    
    func testTimedOperationCustomTimeoutResult() async throws {
        let logger = TestLogger()
        let operation = TimedOperation<[Int]>(operationName: "Custom Timeout Test", logger: logger)
        
        let customResult = [1, 2, 3]
        
        let result = try await withCheckedThrowingContinuation { continuation in
            operation.setup(continuation)
            
            // Test the new timeout result functionality with return value
            operation.setTimeoutTask(timeout: 0.1, onTimeoutResult: {
                return customResult
            })
            
            // Don't complete the operation - let it timeout with custom result
        }
        
        XCTAssertEqual(result, customResult, "Should return custom result on timeout")
    }
    
    func testTimedOperationCustomTimeoutResultWithFailure() async {
        let logger = TestLogger()
        let operation = TimedOperation<String>(operationName: "Custom Failure Test", logger: logger)
        
        let customError = BluetoothError.peripheralNotFound
        
        do {
            _ = try await withCheckedThrowingContinuation { continuation in
                operation.setup(continuation)
                
                // Test custom timeout result with thrown error
                operation.setTimeoutTask(timeout: 0.1, onTimeoutResult: {
                    throw customError
                })
            }
            
            XCTFail("Should have thrown custom error")
        } catch BluetoothError.peripheralNotFound {
            // Expected custom error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testTimedOperationClosureBasedTimeoutResult() async throws {
        let logger = TestLogger()
        let operation = TimedOperation<[String]>(
            operationName: "Closure Timeout Test",
            logger: logger
        )

        var dynamicResult: [String] = []

        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[String], Error>) in
            operation.setup(continuation)

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 40_000_000)
                dynamicResult.append("item1")

                try? await Task.sleep(nanoseconds: 40_000_000)
                dynamicResult.append("item2")
            }

            operation.setTimeoutTask(timeout: 0.15, onTimeoutResult: {
                return dynamicResult
            })
        }

        XCTAssertEqual(result, ["item1", "item2"], "Should return dynamic result captured at timeout time")
    }
    
    func testTimedOperationTimeoutResultDoesNotOverrideSuccess() async throws {
        let logger = TestLogger()
        let operation = TimedOperation<String>(operationName: "No Override Test", logger: logger)
        
        let result = try await withCheckedThrowingContinuation { continuation in
            operation.setup(continuation)
            
            // Set timeout with custom result
            operation.setTimeoutTask(timeout: 0.2, onTimeoutResult: {
                return "timeout result"
            })
            
            // Complete before timeout
            Task {
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                operation.resumeOnce(with: .success("success result"))
            }
        }
        
        XCTAssertEqual(result, "success result", "Success should not be overridden by timeout result")
    }
    
    func testTimedOperationTimeoutHandlerStillCalled() async throws {
        let logger = TestLogger()
        let operation = TimedOperation<[Int]>(operationName: "Handler Test", logger: logger)
        
        var timeoutHandlerCalled = false
        let customResult = [42]
        
        let result = try await withCheckedThrowingContinuation { continuation in
            operation.setup(continuation)
            
            operation.setTimeoutTask(timeout: 0.1, onTimeoutResult: {
                timeoutHandlerCalled = true
                return customResult
            })
        }
        
        XCTAssertEqual(result, customResult, "Should return custom result")
        XCTAssertTrue(timeoutHandlerCalled, "Timeout handler should still be called")
    }
    
    func testTimedOperationDefaultTimeoutBehaviorUnchanged() async {
        let logger = TestLogger()
        let operation = TimedOperation<String>(operationName: "Default Behavior Test", logger: logger)
        
        do {
            _ = try await withCheckedThrowingContinuation { continuation in
                operation.setup(continuation)
                
                // Use original timeout method - should still throw connectionTimeout
                operation.setTimeoutTask(timeout: 0.1, onTimeout: {})
            }
            
            XCTFail("Should have thrown default timeout error")
        } catch BluetoothError.connectionTimeout {
            // Expected - default behavior should be unchanged
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
