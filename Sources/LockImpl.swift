//
//  LockImpl.swift
//  Cleanroom Project
//
//  Created by Evan Maloney on 3/8/17.
//  Copyright © 2017 Gilt Groupe. All rights reserved.
//

internal class AsyncLockFacade: AsyncLock
{
    public var mechanism: LockMechanism {
        return lock.mechanism
    }

    private let lock: Lock

    public init(wrapping: Lock)
    {
        lock = wrapping
    }

    public func read<R>(_ fn: () -> R)
        -> R
    {
        return lock.read(fn)
    }

    public func write(_ fn: @escaping () -> Void)
    {
        lock.write(fn)
    }
}

internal class NoLock: Lock
{
    public let mechanism = LockMechanism.none

    public init() {}

    public func read<R>(_ fn: () -> R)
        -> R
    {
        return fn()
    }

    public func write<R>(_ fn: () -> R)
        -> R
    {
        return fn()
    }
}

internal class MutexLock: Lock
{
    public let mechanism = LockMechanism.mutex
    private let cs = CriticalSection()

    public init() {}

    public func read<R>(_ fn: () -> R)
        -> R
    {
        return cs.execute(fn)
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

    public func read<R>(_ fn: () -> R)
        -> R
    {
        return coordinator.read(fn)
    }

    public func write(_ fn: () -> Void)
    {
        coordinator.blockingWrite(fn)
    }
}

internal class ReadAsyncWriteLock: AsyncLock
{
    public let mechanism = LockMechanism.readWrite
    private let coordinator = ReadWriteCoordinator()

    public init() {}

    public func read<R>(_ fn: () -> R)
        -> R
    {
        return coordinator.read(fn)
    }

    public func write(_ fn: @escaping () -> Void)
    {
        coordinator.enqueueWrite(fn)
    }
}
