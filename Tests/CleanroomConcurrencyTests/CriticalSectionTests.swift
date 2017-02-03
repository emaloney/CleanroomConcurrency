//
//  CriticalSectionTests.swift
//  Cleanroom Project
//
//  Created by Evan Maloney on 4/6/15.
//  Copyright © 2015 Gilt Groupe. All rights reserved.
//

import XCTest
import CleanroomConcurrency

private var protect = 0             // a global value to protect with a ReadWriteCoordinator
private var remainingThreads = 0    // used with an NSCondition signal to keep track of our threads
private var executions = 0          // count the number of times the

private let ShortWaitTimeout        = TimeInterval(1.0)
private let LongWaitTimeout         = TimeInterval(100.0)
private let TestThreadIterations    = 1000

class CriticalSectionTests: XCTestCase
{
    class ExpectedSuccessTestThread: Thread
    {
        let signal: NSCondition
        let lock: CriticalSection
        let lockTimeout: TimeInterval?

        init(signal: NSCondition, lock: CriticalSection, lockTimeout: TimeInterval? = nil)
        {
            self.signal = signal
            self.lock = lock
            self.lockTimeout = lockTimeout
        }

        override func main()
        {
            let fn = { () -> Void in
                // this also tests re-entrancy
                let gotLock = self.lock.executeWithTimeout(LongWaitTimeout) {
                    executions += 1

                    XCTAssertTrue(protect == 0)
                    protect += 1
                    XCTAssertTrue(protect == 1)
                    protect -= 1
                    XCTAssertTrue(protect == 0)
                }
                XCTAssertTrue(gotLock)
            }

            for _ in 0..<TestThreadIterations {
                if let timeout = lockTimeout {
                    let executed = lock.executeWithTimeout(timeout, fn)
                    XCTAssertTrue(executed)
                }
                else {
                    lock.execute(fn)
                }
                Thread.sleep(forTimeInterval: 0.0)
            }

            signal.lock()
            remainingThreads -= 1
            signal.signal()
            signal.unlock()
        }
    }
    
    func testCriticalSectionExclusivity()
    {
        let NumberOfThreads = 100

        let lock = CriticalSection()
        let signal = NSCondition()

        signal.lock()

        remainingThreads = NumberOfThreads
        for _ in 0..<NumberOfThreads {
            ExpectedSuccessTestThread(signal: signal, lock: lock).start()
        }

        while remainingThreads > 0 {
            signal.wait(until: Date().addingTimeInterval(LongWaitTimeout))
        }
        signal.unlock()

        XCTAssert(protect == 0)
        XCTAssert(executions == NumberOfThreads * TestThreadIterations)
        XCTAssert(remainingThreads == 0)
    }

    class ExpectedTimeoutTestThread: Thread
    {
        let signal: NSCondition
        let lock: CriticalSection

        init(signal: NSCondition, lock: CriticalSection)
        {
            self.signal = signal
            self.lock = lock
        }

        override func main()
        {
            let gotLock = lock.executeWithTimeout(ShortWaitTimeout) {
                XCTAssertTrue(false, "we weren't expecting to be able to grab this lock")
            }

            XCTAssertFalse(gotLock)

            signal.lock()
            remainingThreads -= 1
            signal.signal()
            signal.unlock()
        }
    }
    
    func testCriticalSectionTimeout()
    {
        let NumberOfThreads = 25

        let lock = CriticalSection()
        let signal = NSCondition()

        lock.execute {
            signal.lock()

            remainingThreads = NumberOfThreads
            for _ in 0..<NumberOfThreads {
                ExpectedTimeoutTestThread(signal: signal, lock: lock).start()
            }

            while remainingThreads > 0 {
                signal.wait(until: Date().addingTimeInterval(LongWaitTimeout))
            }
            signal.unlock()
        }

        XCTAssert(protect == 0)
        XCTAssert(remainingThreads == 0)
    }
}
