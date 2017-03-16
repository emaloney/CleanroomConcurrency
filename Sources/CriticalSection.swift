//
//  CriticalSection.swift
//  Cleanroom Project
//
//  Created by Evan Maloney on 4/6/15.
//  Copyright © 2015 Gilt Groupe. All rights reserved.
//

import Foundation

/**
 `CriticalSection`s can be used to ensure exclusive access to a given resource.

 By protecting a resource with a `CriticalSection`, you ensure that only one
 one thread can be executing code using that critical section at any given time.

 `CriticalSection`s are re-entrant, meaning that code already holding access
 to the critical section may re-enter the critical section without causing
 a deadlock. (The `NSRecursiveLock` class is used under the hood.)
 */
public struct CriticalSection
{
    private let lock = NSRecursiveLock()

    /**
     Initializer.
     */
    public init() {}

    /**
     Attempts to acquire exclusive access to the critical section before
     executing the passed-in function. The calling thread will block
     indefinitely until it is able to acquire the critical section.

     - parameter fn: The function to execute once exclusive access to the
     critical section has been acquired.
     */
    public func execute<T>(_ fn: () -> T)
        -> T
    {
        lock.lock()
        defer {
            lock.unlock()
        }

        return fn()
    }

    /**
     Attempts to acquire exclusive access to the critical section before
     executing the passed-in function. The calling thread will block for at most
     `timeout` seconds while waiting to enter the critical section before giving
     up.

     - parameter timeout: The maximum time to wait while attempting to acquire
     exclusive access to the critical section.

     - parameter fn: The function to execute once exclusive access to the
     critical section has been acquired.

     - returns: `true` if exclusive access to the critical section was acquired
     and `fn` was executed. `false` if `timeout` expired and `fn` was not
     executed.
     */
    public func execute(timeout: TimeInterval, _ fn: () -> Void)
        -> Bool
    {
        if lock.lock(before: Date().addingTimeInterval(timeout)) {
            defer {
                lock.unlock()
            }
            fn()
            return true
        }

        return false
    }
}
