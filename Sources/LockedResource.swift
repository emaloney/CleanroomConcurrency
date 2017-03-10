//
//  LockedResource.swift
//  Cleanroom Project
//
//  Created by Evan Maloney on 3/8/17.
//  Copyright © 2017 Gilt Groupe. All rights reserved.
//

import Foundation

/**
 A generic class that protects a resource of type `T` with a `Lock`.
 
 The user of a `LockedResource` accesses the resource via a read or write
 function. The resource itself is available only within the scope of the
 passed-in function, during which time the appropriate lock is guaranteed
 to be held.
 */
open class LockedResource<T>
{
    private let lock: Lock
    private var resource: T

    /**
     Initializes a new `LockedResource` to protect the given resource 
     using the specified `LockMechanism`.
     
     - parameter resource: The resource to be protected with a lock.
     
     - parameter mechanism: A `LockMechanism` value specifying the type of
     lock that will be used to protect `resource`.
     */
    public init(resource: T, lock mechanism: LockMechanism)
    {
        self.lock = mechanism.createLock()
        self.resource = resource
    }

    /**
     Performs an operation with the read lock held.
     
     - parameter operation: A function that will be executed with the read
     lock held. The protected resource is passed as a parameter to `operation`,
     which may use it for reading only.
     */
    open func read(_ operation: (T) -> Void)
    {
        lock.read {
            operation(self.resource)
        }
    }

    /**
     Performs an operation with the write lock held.

     - note: Whether or not `operation` is an escaping function depends upon 
     the underlying lock mechanism. Because it *may* escape in *some* 
     implementations, it has to be declared `@escaping` here to cover all cases.

     - parameter operation: A function that will be executed with the write
     lock held. The protected resource is passed as an `inout` parameter to
     `operation` so that it may be mutated.
     */
    open func write(_ operation: (inout T) -> Void)
    {
        lock.write {
            operation(&self.resource)
        }
    }
}
