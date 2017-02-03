//
//  ReadWriteCoordinatorTests.swift
//  Cleanroom Project
//
//  Created by Evan Maloney on 3/25/15.
//  Copyright © 2015 Gilt Groupe. All rights reserved.
//

import XCTest
import CleanroomConcurrency

private var counter = 0             // a global value to protect with a ReadWriteCoordinator
private var remainingThreads = 0    // used with an NSCondition signal to keep track of our threads

class ReadWriteCoordinatorTests: XCTestCase
{
    class TestThread: Thread
    {
        let lock: ReadWriteCoordinator
        let signal: NSCondition

        init(lock: ReadWriteCoordinator, signal: NSCondition)
        {
            self.lock = lock
            self.signal = signal
        }

        override func main()
        {
            lock.enqueueWrite {
                let curVal = counter + 1
                counter = curVal
            }

            signal.lock()
            remainingThreads -= 1
            signal.signal()
            signal.unlock()
        }
    }

    func testReadWriteCoordinator()
    {
        let NumberOfThreads = 100

        let lock = ReadWriteCoordinator()
        let signal = NSCondition()

        signal.lock()

        remainingThreads = NumberOfThreads
        for _ in 0..<NumberOfThreads {
            TestThread(lock: lock, signal: signal).start()
        }

        while remainingThreads > 0 {
            signal.wait()

            lock.read {
                print("counter: \(counter)")
            }
        }
        signal.unlock()

        var curVal: Int?
        lock.read {
            curVal = counter
        }

        XCTAssert(remainingThreads == 0)
        XCTAssertNotNil(curVal)
        XCTAssert(curVal! == 100)
    }
}
