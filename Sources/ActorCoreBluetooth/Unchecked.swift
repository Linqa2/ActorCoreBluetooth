//
//  Unchecked.swift
//  ActorCoreBluetooth
//
//  Created by Konstantin Polin on 8/1/25.
//  Licensed under the MIT License. See LICENSE file in the project root.
//

import Foundation

/// Transport-level wrapper for non-Sendable types that need to cross concurrency boundaries.
///
/// This type should ONLY be used at Sendable boundaries (continuations, AsyncStream, Task capture)
/// where the compiler requires Sendable conformance. It does not make the wrapped value thread-safe;
/// the caller is responsible for ensuring proper synchronization (e.g., @MainActor isolation).
@usableFromInline
struct Unchecked<T>: @unchecked Sendable {
    @usableFromInline
    let value: T
    
    @inlinable
    init(_ value: T) {
        self.value = value
    }
    
    @inlinable
    func map<U>(_ transform: (T) -> U) -> Unchecked<U> {
        Unchecked<U>(transform(value))
    }
    
    @inlinable
    func withValue<U>(_ operation: (T) throws -> U) rethrows -> U {
        try operation(value)
    }
}
