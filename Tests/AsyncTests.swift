//
//  AsyncTests.swift
//  Cleanroom Project
//
//  Created by Evan Maloney on 3/23/15.
//  Copyright © 2015 Gilt Groupe. All rights reserved.
//

import XCTest
import CleanroomConcurrency

class AsyncTests: XCTestCase
{
    let IterationsForDelayedTests   = 10
    let IterationsPerBarrierStage   = 5
    let IterationsOfBarrierTest     = 10

    func testAsyncFunction()
    {
        XCTAssertTrue(NSThread.isMainThread())  // we expect tests to run on the main thread

        let semaphore = NSCondition()
        var completed = false

        async {
            XCTAssertTrue(!NSThread.isMainThread())

            semaphore.lock()
            completed = true
            semaphore.signal()
            semaphore.unlock()
        }

        semaphore.lock()
        var tries = 0
        while !semaphore.waitUntilDate(NSDate().dateByAddingTimeInterval(1.0)) && !completed && tries < 10 {
            NSRunLoop.currentRunLoop().runMode(NSRunLoopCommonModes, beforeDate: NSDate().dateByAddingTimeInterval(1.0))
            tries += 1
        }
        semaphore.unlock()

        XCTAssertTrue(completed)
    }

    func testAsyncWithDelayFunction()
    {
        var completed = 0

        func testDelay(delay: NSTimeInterval, withSemaphore semaphore: NSCondition)
        {
            XCTAssertTrue(NSThread.isMainThread())  // we expect tests to run on the main thread

            let endTime = NSDate().dateByAddingTimeInterval(delay)

            async(delay: delay) {
                XCTAssertTrue(!NSThread.isMainThread())

                let now = NSDate()
                XCTAssertTrue(endTime.laterDate(now) == now)

                semaphore.lock()
                completed += 1
                semaphore.signal()
                semaphore.unlock()
            }
        }

        let semaphore = NSCondition()

        for _ in 0..<IterationsForDelayedTests {
            let delay = NSTimeInterval(Double(arc4random() % 1000) / 1000) + 0.01
            testDelay(delay, withSemaphore: semaphore)
        }

        var lastCompleted: Int?
        semaphore.lock()
        while completed < IterationsForDelayedTests {
            if !semaphore.waitUntilDate(NSDate().dateByAddingTimeInterval(1.0)) {
                NSRunLoop.currentRunLoop().runMode(NSRunLoopCommonModes, beforeDate: NSDate().dateByAddingTimeInterval(1.0))
            }
            else {
                if let last = lastCompleted {
                    XCTAssertTrue(completed > last)
                }
                lastCompleted = completed
            }
        }
        semaphore.unlock()

        XCTAssertTrue(completed == IterationsForDelayedTests)
    }

    func testAsyncBarrierFunction()
    {
        var startAsyncWork = false
        var preBarrierStageCompleted = 0
        var inBarrierStageCompleted = 0
        var postBarrierStageCompleted = 0

        func testBarrier(with semaphore: NSCondition, startingGun: NSCondition)
        {
            XCTAssertTrue(NSThread.isMainThread())  // we expect tests to run on the main thread

            for _ in 0..<IterationsPerBarrierStage {
                async {
                    XCTAssertTrue(!NSThread.isMainThread())

                    startingGun.lock()
                    while !startAsyncWork {
                        startingGun.wait()
                    }
                    startingGun.unlock()
                    semaphore.lock()
                    XCTAssertTrue(inBarrierStageCompleted == 0)
                    XCTAssertTrue(postBarrierStageCompleted == 0)

                    preBarrierStageCompleted += 1

                    semaphore.signal()
                    semaphore.unlock()
                }

            }

            for _ in 0..<IterationsPerBarrierStage {
                asyncBarrier {
                    XCTAssertTrue(!NSThread.isMainThread())

                    startingGun.lock()
                    while !startAsyncWork {
                        startingGun.wait()
                    }
                    startingGun.unlock()
                    semaphore.lock()
                    XCTAssertTrue(preBarrierStageCompleted == self.IterationsPerBarrierStage)
                    XCTAssertTrue(postBarrierStageCompleted == 0)

                    inBarrierStageCompleted += 1

                    semaphore.signal()
                    semaphore.unlock()
                }

            }

            for _ in 0..<IterationsPerBarrierStage {
                async {
                    XCTAssertTrue(!NSThread.isMainThread())

                    startingGun.lock()
                    while !startAsyncWork {
                        startingGun.wait()
                    }
                    startingGun.unlock()
                    semaphore.lock()
                    XCTAssertTrue(preBarrierStageCompleted == self.IterationsPerBarrierStage)
                    XCTAssertTrue(inBarrierStageCompleted == self.IterationsPerBarrierStage)

                    postBarrierStageCompleted += 1

                    semaphore.signal()
                    semaphore.unlock()
                }

            }

        }

        for _ in 0..<IterationsOfBarrierTest {
            let semaphore = NSCondition()
            let startingGun = NSCondition()

            testBarrier(with: semaphore, startingGun: startingGun)
            let waitingFor = IterationsPerBarrierStage * 3  // because there are 3 test stages

            var completed = 0
            var lastCompleted: Int?
            semaphore.lock()
            startingGun.lock()
            startAsyncWork = true
            startingGun.broadcast()
            startingGun.unlock()
            while completed < waitingFor {
                if !semaphore.waitUntilDate(NSDate().dateByAddingTimeInterval(1.0)) {
                    NSRunLoop.currentRunLoop().runMode(NSRunLoopCommonModes, beforeDate: NSDate().dateByAddingTimeInterval(1.0))
                }
                else {
                    completed = preBarrierStageCompleted + inBarrierStageCompleted + postBarrierStageCompleted
                    if let last = lastCompleted {
                        XCTAssertTrue(completed > last)
                    }
                    lastCompleted = completed
                }
            }
            semaphore.unlock()
            XCTAssertTrue(completed == waitingFor)

            // reset vars for next run
            preBarrierStageCompleted = 0
            inBarrierStageCompleted = 0
            postBarrierStageCompleted = 0
        }
    }

    func testMainThreadFunction()
    {
        // not really sure how to test this effectively. because the tests
        // execute on the main thread, it isn't possible to use a semaphore
        // the way we do in testAsyncWithDelayFunction, because doing so
        // would cause the main thread to block and would prevent execution
        // of the delayed functions
    }

    func testMainThreadWithDelayFunction()
    {
        // not really sure how to test this effectively. because the tests
        // execute on the main thread, it isn't possible to use a semaphore
        // the way we do in testAsyncWithDelayFunction, because doing so
        // would cause the main thread to block and would prevent execution
        // of the delayed functions
    }
}
