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

    public func write(_ fn: @escaping () -> Void)
    {
        fn()
    }
}

internal class CriticalSectionLock: Lock
{
    public let mechanism = LockMechanism.criticalSection
    private let cs = CriticalSection()

    public init() {}

    public func read(_ fn: () -> Void)
    {
        cs.execute(fn)
    }

    public func write(_ fn: @escaping () -> Void)
    {
        cs.execute(fn)
    }
}

internal class ReadWriteCoordinatorLock: Lock
{
    public let mechanism: LockMechanism
    private let synchronousWrites: Bool
    private let coordinator: ReadWriteCoordinator

    public init(synchronousWrites: Bool = false)
    {
        self.coordinator = ReadWriteCoordinator()
        self.mechanism = synchronousWrites ? .readAndBlockingWrite : .readAndAsyncWrite
        self.synchronousWrites = synchronousWrites
    }

    public func read(_ fn: () -> Void)
    {
        coordinator.read(fn)
    }

    public func write(_ fn: @escaping () -> Void)
    {
        synchronousWrites
            ? coordinator.blockingWrite(fn)
            : coordinator.enqueueWrite(fn)
    }
}
