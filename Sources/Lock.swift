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

     - parameter fn: A function to perform while a read lock is held.

     - returns: The result of calling `fn()`.
     */
    @discardableResult
    func read<R>(_ fn: () -> R)
        -> R

    /**
     Executes the given function with the write lock held, returning its
     result.

     - parameter fn: A function to perform while the write lock is held.

     - returns: The result of calling `fn()`.
     */
    @discardableResult
    func write<R>(_ fn: () -> R)
        -> R
}
