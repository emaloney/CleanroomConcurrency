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
        XCTAssertTrue(Thread.isMainThread)  // we expect tests to run on the main thread

        let semaphore = NSCondition()
        var completed = false

        async {
            XCTAssertTrue(!Thread.isMainThread())

            semaphore.lock()
            completed = true
            semaphore.signal()
            semaphore.unlock()
        }

        semaphore.lock()
        if !completed {
            semaphore.wait(until: Date().addingTimeInterval(1.0))
        }
        semaphore.unlock()

        XCTAssertTrue(completed)
    }

    func testAsyncWithDelayFunction()
    {
        var completed = 0

        func testDelay(_ delay: TimeInterval, withSemaphore semaphore: NSCondition)
        {
            XCTAssertTrue(Thread.isMainThread)  // we expect tests to run on the main thread

            let endTime = Date().addingTimeInterval(delay)

            async(delay: delay) {
                XCTAssertTrue(!Thread.isMainThread())

                let now = Date()
                XCTAssertTrue((endTime as NSDate).laterDate(now) == now)

                semaphore.lock()
                completed++
                semaphore.signal()
                semaphore.unlock()
            }
        }

        let semaphore = NSCondition()

        for _ in 0..<IterationsForDelayedTests {
            let delay = TimeInterval(Double(arc4random() % 1000) / 1000)
            testDelay(delay, withSemaphore: semaphore)
        }

        var lastCompleted: Int?
        semaphore.lock()
        while completed < IterationsForDelayedTests {
            semaphore.wait(until: Date().addingTimeInterval(1.1))
            if let last = lastCompleted {
                XCTAssertTrue(completed > last)
            }
            lastCompleted = completed
        }
        semaphore.unlock()

        XCTAssertTrue(completed == IterationsForDelayedTests)
    }

    func testAsyncBarrierFunction()
    {
        var preBarrierStageCompleted = 0
        var inBarrierStageCompleted = 0
        var postBarrierStageCompleted = 0

        func testBarrierWithSemaphore(_ semaphore: NSCondition)
        {
            XCTAssertTrue(Thread.isMainThread)  // we expect tests to run on the main thread

            for _ in 0..<IterationsPerBarrierStage {
                async {
                    XCTAssertTrue(!Thread.isMainThread())

                    semaphore.lock()

                    XCTAssertTrue(inBarrierStageCompleted == 0)
                    XCTAssertTrue(postBarrierStageCompleted == 0)

                    preBarrierStageCompleted++

                    semaphore.signal()
                    semaphore.unlock()
                }
            }

            for _ in 0..<IterationsPerBarrierStage {
                asyncBarrier {
                    XCTAssertTrue(!Thread.isMainThread())

                    semaphore.lock()

                    XCTAssertTrue(preBarrierStageCompleted == self.IterationsPerBarrierStage)
                    XCTAssertTrue(postBarrierStageCompleted == 0)

                    inBarrierStageCompleted++

                    semaphore.signal()
                    semaphore.unlock()
                }
            }

            for _ in 0..<IterationsPerBarrierStage {
                async {
                    XCTAssertTrue(!Thread.isMainThread())

                    semaphore.lock()

                    XCTAssertTrue(preBarrierStageCompleted == self.IterationsPerBarrierStage)
                    XCTAssertTrue(inBarrierStageCompleted == self.IterationsPerBarrierStage)

                    postBarrierStageCompleted++

                    semaphore.signal()
                    semaphore.unlock()
                }
            }
        }

        for _ in 0..<IterationsOfBarrierTest {
            let semaphore = NSCondition()

            testBarrierWithSemaphore(semaphore)

            let waitingFor = IterationsPerBarrierStage * 3  // because there are 3 test stages

            var completed = 0
            var lastCompleted: Int?
            semaphore.lock()
            while completed < waitingFor {
                semaphore.wait(until: Date().addingTimeInterval(1.1))
                completed = preBarrierStageCompleted + inBarrierStageCompleted + postBarrierStageCompleted
                if let last = lastCompleted {
                    XCTAssertTrue(completed > last)
                }
                lastCompleted = completed
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
