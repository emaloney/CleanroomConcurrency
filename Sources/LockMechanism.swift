//
//  LockMechanism.swift
//  Cleanroom Project
//
//  Created by Evan Maloney on 3/8/17.
//  Copyright © 2017 Gilt Groupe. All rights reserved.
//

/**
 Represents different mechanisms that can be used for locking.
 */
public enum LockMechanism
{
    /** A mechanism that peforms no read or write locking. This should only
     be used to optimize for scenarios where a lock is required but 
     thread-safety can be guaranteed through other means. (In other
     words, if you use this value, you are assuming responsibility for
     ensuring thread-safety on your own.)
     */
    case none

    /** A mechanism that relies on a `CriticalSection` for a re-entrant
     mutual exclusion lock. */
    case mutex

    /** A read/write lock mechanism that relies on a `ReadWriteCoordinator` 
     for a many-reader/single-writer. */
    case readWrite
}

extension LockMechanism
{
    /**
     Creates a new `Lock` instance that uses the locking mechanism specified
     by the value of the receiver.

     - returns: The new `Lock`.
     */
    public func createLock()
        -> Lock
    {
        switch self {
        case .none:         return NoLock()
        case .mutex:        return MutexLock()
        case .readWrite:    return ReadWriteLock()
        }
    }

    /**
     Creates a new `AsyncLock` instance that uses the locking mechanism 
     specified by the value of the receiver.

     - returns: The new `AsyncLock`.
     */
    public func createAsyncLock()
        -> AsyncLock
    {
        switch self {
        case .none:         return AsyncLockFacade(wrapping: NoLock())
        case .mutex:        return AsyncLockFacade(wrapping: MutexLock())
        case .readWrite:    return ReadAsyncWriteLock()
        }
    }
}
