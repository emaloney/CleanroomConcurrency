//
//  Lock.swift
//  Cleanroom Project
//
//  Created by Evan Maloney on 3/8/17.
//  Copyright © 2017 Gilt Groupe. All rights reserved.
//

/**
 A generic interface describing a lock that can be acquired for synchronous
 (blocking) reading or writing.
 */
public protocol Lock
{
    /** Describes the underlying locking mechanism used by the receiver. */
    var mechanism: LockMechanism { get }

    /**
     Executes the given function with a read lock held, returning its
     result.

     The implementation acquires a read lock, executes `fn` and records its
     result, releases the lock, and returns the result of executing `fn`.

     - parameter fn: A function to perform while a read lock is held.

     - returns: The result of calling `fn()`.
     */
    func read<T>(_ fn: () -> T)
        -> T

    /**
     Executes the given function with the write lock held.

     The implementation acquires the write lock, executes `fn`, and then
     releases the lock it acquired.

     - parameter fn: A function to perform while the write lock is held.
     */
    func write(_ fn: () -> Void)
}
