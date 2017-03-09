//
//  Lock.swift
//  Cleanroom Project
//
//  Created by Evan Maloney on 3/8/17.
//  Copyright © 2017 Gilt Groupe. All rights reserved.
//

/**
 A generic interface describing a lock that can be acquired for reading
 or writing.
 */
public protocol Lock
{
    /** Describes the underlying locking mechanism used by the receiver. */
    var mechanism: LockMechanism { get }

    /**
     Performs the given function with a read lock held.
     
     The implementation acquires a read lock, executes `fn`, and then
     releases the lock it acquired.

     - parameter fn: A function to perform while a read lock is held.
     */
    func read(_ fn: () -> Void)

    /**
     Performs the given function with the write lock held.

     The implementation acquires the write lock, executes `fn`, and then
     releases the lock it acquired.

     - note: Whether or not `fn` is an escaping function depends upon
     the underlying lock mechanism. Because it *may* escape in *some*
     implementations, it has to be declared `@escaping` here to cover all cases.

     - parameter fn: A function to perform while the write lock is held.
     */
    func write(_ fn: @escaping () -> Void)
}
