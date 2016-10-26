//
//  ReadWriteCoordinator.swift
//  Cleanroom Project
//
//  Created by Evan Maloney on 3/24/15.
//  Copyright © 2015 Gilt Groupe. All rights reserved.
//

import Foundation

/**
`ReadWriteCoordinator` instances can be used to coordinate access to a mutable
resource shared across multiple threads.

You can think of the `ReadWriteCoordinator` as a read/write lock having the
following properties:

    - The *read lock* allows any number of *readers* to execute concurrently.

    - The *write lock* allows one and only one *writer* to execute at a time.

    - As long as there is at least one reader executing, the write lock cannot be acquired.

    - As long as the write lock is held, no readers can execute.
*/
public struct ReadWriteCoordinator
{
    /// The dispatch queue used by the receiver.
    let queue: DispatchQueue

    /** 
    Initializes a new `ReadWriteCoordinator` instance.
    */
    public init()
    {
        queue = DispatchQueue(label: "CleanroomBase.ConcurrentReadWriteCoordinatorQueue", attributes: .concurrent)
    }

    /**
    Initializes a new `ReadWriteCoordinator` instance.
    
    :param:     queueName The name for the Grand Central Dispatch queue that 
                will be created for the new `ReadWriteCoordinator`.
    */
    public init(queueName: String)
    {
        queue = DispatchQueue(label: queueName, attributes: .concurrent)
    }

    /**
    Synchronously acquires the read lock and executes the passed-in function.
    
    :param:     fn A no-argument function that will be called when the read
                lock is held.
    */
    public func read(_ fn: () -> Void)
    {
        queue.sync {
            fn()
        }
    }

    /**
    Enqueues an asynchronous request for the write lock and returns immediately.
    When the write lock is acquired, the passed-in function is executed.

    :param:     fn A no-argument function that will be called when the write
                lock is held.
    */
    public func enqueueWrite(_ fn: @escaping () -> Void)
    {
        queue.async(flags: .barrier) {
            fn()
        }
    }

    /**
    Synchronously attempts to acquire the write lock, blocking if necessary. 
    When the write lock is acquired, the passed-in function is executed.

    :param:     fn A no-argument function that will be called when the write
                lock is held.
    */
    public func blockingWrite(_ fn: () -> Void)
    {
        queue.sync(flags: .barrier) {
            fn()
        }
    }
}
