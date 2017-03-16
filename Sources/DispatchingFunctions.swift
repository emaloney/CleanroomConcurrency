//
//  DispatchingFunctions.swift
//  Cleanroom Project
//
//  Created by Evan Maloney on 3/17/15.
//  Copyright © 2015 Gilt Groupe. All rights reserved.
//

import Dispatch
import Foundation

/**
 Asynchronously executes the passed-in function on a concurrent GCD queue.

 - parameter fn: The function to execute asynchronously.
 */
public func async(_ fn: @escaping () -> Void)
{
    AsyncQueue.instance.queue.async {
        fn()
    }
}

/**
 After a specified delay, asynchronously executes the passed-in function on a
 concurrent GCD queue.

 - parameter delay: The number of seconds to wait before executing `fn`
 asynchronously. This is not real-time scheduling, so the function is
 guaranteed to execute after *at least* this amount of time, not
 after *exactly* this amount of time.

 - parameter fn: The function to execute asynchronously.
 */
public func async(delay: TimeInterval, _ fn: @escaping () -> Void)
{
    let time = DispatchTime.now() + Double(Int64(delay * TimeInterval(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
    AsyncQueue.instance.queue.asyncAfter(deadline: time)  {
        fn()
    }
}

/**
 Asynchronously executes the passed-in function on a concurrent GCD queue,
 treating it as a barrier. Functions submitted to the queue prior to the barrier
 are guaranteed to execute before the barrier, while functions submitted after
 the barrier are guaranteed to execute after the passed-in function has
 executed.

 - parameter fn: The function to execute asynchronously.
 */
public func asyncBarrier(_ fn: @escaping () -> Void)
{
    AsyncQueue.instance.queue.async(flags: .barrier)  {
        fn()
    }
}

/**
 Asynchronously executes the specified function on the main thread.

 - parameter fn: The function to execute on the main thread.
*/
public func mainThread(_ fn: @escaping () -> Void)
{
    DispatchQueue.main.async {
        fn()
    }
}

/**
 Asynchronously executes the specified function on the main thread.

 - parameter delay: The number of seconds to wait before executing `fn`
 asynchronously. This is not real-time scheduling, so the function is
 guaranteed to execute after *at least* this amount of time, not
 after *exactly* this amount of time.

 - parameter fn: The function to execute on the main thread.
*/
public func mainThread(delay: TimeInterval, _ fn: @escaping () -> Void)
{
    let time = DispatchTime.now() + Double(Int64(delay * TimeInterval(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
    DispatchQueue.main.asyncAfter(deadline: time)  {
        fn()
    }
}

private struct AsyncQueue
{
    static let instance = AsyncQueue()

    let queue: DispatchQueue

    init()
    {
        queue = DispatchQueue(label: "CleanroomConcurrency.AsyncQueue", attributes: .concurrent)
    }
}
