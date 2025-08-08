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
                
                operation.setTimeoutTask(timeout: 0.1) {
                    print("timed out")
                }
                
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
    
    func testTimedOperationTimeoutIntegration() async throws {
        let logger = TestLogger()
        let operation = TimedOperation<String>(operationName: "Integration Test", logger: logger)
        
        let startTime = Date()
        
        do {
            _ = try await withCheckedThrowingContinuation { continuation in
                operation.setup(continuation)
                operation.setTimeoutTask(timeout: 0.1) {
                    print("timed out")
                }
            }
            
            XCTFail("Should have timed out")
        } catch BluetoothError.connectionTimeout {
            let elapsed = Date().timeIntervalSince(startTime)
            XCTAssertGreaterThanOrEqual(elapsed, 0.1, "Timeout should have taken at least 0.1 seconds")
            XCTAssertLessThan(elapsed, 0.2, "Timeout should not have taken much longer than 0.1 seconds")
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
}
