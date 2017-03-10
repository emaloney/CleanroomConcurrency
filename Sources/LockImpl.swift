//
//  LockImpl.swift
//  Cleanroom Project
//
//  Created by Evan Maloney on 3/8/17.
//  Copyright © 2017 Gilt Groupe. All rights reserved.
//

internal class NoLock: Lock
{
    public let mechanism = LockMechanism.none

    public init() {}

    public func read(_ fn: () -> Void)
    {
        fn()
    }

    public func write(_ fn: () -> Void)
    {
        fn()
    }
}

internal class MutexLock: Lock
{
    public let mechanism = LockMechanism.mutex
    private let cs = CriticalSection()

    public init() {}

    public func read(_ fn: () -> Void)
    {
        cs.execute(fn)
    }

    public func write(_ fn: () -> Void)
    {
        cs.execute(fn)
    }
}

internal class ReadWriteLock: Lock
{
    public let mechanism = LockMechanism.readWrite
    private let coordinator = ReadWriteCoordinator()

    public init() {}

    public func read(_ fn: () -> Void)
    {
        coordinator.read(fn)
    }

    public func write(_ fn: () -> Void)
    {
        coordinator.blockingWrite(fn)
    }
}
