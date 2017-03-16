//
//  ReadWriteCoordinator.swift
//  Cleanroom Project
//
//  Created by Evan Maloney on 3/24/15.
//  Copyright © 2015 Gilt Groupe. All rights reserved.
//

import Dispatch

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
public final class ReadWriteCoordinator
{
    private let queue: DispatchQueue

    /**
     Initializes a new `ReadWriteCoordinator` instance.
     */
    public init()
    {
        queue = DispatchQueue(label: "CleanroomConcurrency.ReadWriteCoordinator", attributes: .concurrent)
    }

    /**
     Initializes a new `ReadWriteCoordinator` instance.

     - parameter label: The value to assign as the `label` for the Grand Central
     Dispatch queue that will be created for the new `ReadWriteCoordinator`.
     */
    public init(queueLabel label: String)
    {
        queue = DispatchQueue(label: label, attributes: .concurrent)
    }

    /**
     Executes the given function with a read lock held, returning its
     result.

     - parameter fn: A function to perform while a read lock is held.

     - returns: The result of calling `fn()`.
    */
    public func read<R>(_ fn: () -> R)
        -> R
    {
        var result: R?
        queue.sync {
            result = fn()
        }
        return result!
    }

    /**
     Enqueues an asynchronous request for the write lock and returns to the
     caller immediately. When the write lock is eventually acquired, the
     passed-in function will be executed.

     This provides additional efficiency for callers that do not immediately 
     depend on the results of the operation being performed.
     
     - parameter function: A no-argument function that will be called while the
     lock is held.
    */
    public func enqueueWrite(_ function: @escaping () -> Void)
    {
        queue.async(flags: .barrier) {
            function()
        }
    }

    /**
     Attempts to acquire the write lock, blocking if necessary. Once the write
     lock has been acquired, the passed-in function will be executed.

     Unlike with `enqueueWrite()`, this function will block the calling thread
     if necessary while waiting to acquire the write lock. This function should
     only be used in cases where the results of the write operation need to
     be available to the caller immediately upon return of this function.

     - parameter function: A no-argument function that will be called while the
     lock is held.
    */
    public func blockingWrite(_ function: () -> Void)
    {
        queue.sync(flags: .barrier) {
            function()
        }
    }
}
