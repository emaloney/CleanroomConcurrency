//
//  AsyncLock.swift
//  Cleanroom Project
//
//  Created by Evan Maloney on 3/16/17.
//  Copyright © 2017 Gilt Groupe. All rights reserved.
//

/**
 A generic interface describing a lock that can be acquired for synchronous
 (blocking) reading or (potentially) asynchronous writing.
 
 `AsyncLock` differs from `Lock` by virtue of the fact that, in the case of
 the former, write operations _may_ (but are not _guaranteed_ to) be
 asynchronous, a trait that depends on the underlying implementation.

 Because of this possibility, the `write()` function accepts an escaping
 function.
 */
public protocol AsyncLock
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
    func write(_ fn: @escaping () -> Void)
}
