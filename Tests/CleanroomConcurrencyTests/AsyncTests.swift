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
    let iterationsForDelayedTests   = 10
    let iterationsPerBarrierStage   = 10
    let iterationsOfBarrierTest     = 10

    func testAsyncFunction()
    {
        XCTAssertTrue(Thread.isMainThread)  // we expect tests to run on the main thread

        let semaphore = NSCondition()
        var completed = false

        async {
            XCTAssertTrue(!Thread.isMainThread)

            semaphore.lock()
            completed = true
            semaphore.signal()
            semaphore.unlock()
        }

        semaphore.lock()
        var tries = 0
        while !semaphore.wait(until: Date().addingTimeInterval(1.0)) && !completed && tries < 10 {
            RunLoop.current.run(mode: .defaultRunLoopMode, before: Date().addingTimeInterval(1.0))
            tries += 1
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
                XCTAssertTrue(!Thread.isMainThread)

                let now = Date()
                XCTAssertTrue((endTime as NSDate).laterDate(now) == now)

                semaphore.lock()
                completed += 1
                semaphore.signal()
                semaphore.unlock()
            }
        }

        let semaphore = NSCondition()

        for _ in 0..<iterationsForDelayedTests {
            let delay = TimeInterval(Double(arc4random() % 1000) / 1000) + 0.01
            testDelay(delay, withSemaphore: semaphore)
        }

        var lastCompleted: Int?
        semaphore.lock()
        while completed < iterationsForDelayedTests {
            if !semaphore.wait(until: Date().addingTimeInterval(1.0)) {
                RunLoop.current.run(mode: .defaultRunLoopMode, before: Date().addingTimeInterval(1.0))
            }
            else {
                if let last = lastCompleted {
                    XCTAssertTrue(completed > last)
                }
                lastCompleted = completed
            }
        }
        semaphore.unlock()

        XCTAssertTrue(completed == iterationsForDelayedTests)
    }

    func testAsyncBarrierFunction()
    {
        var startAsyncWork = false
        var preBarrierStageCompleted = 0
        var inBarrierStageCompleted = 0
        var postBarrierStageCompleted = 0

        func testBarrier(with semaphore: NSCondition, startingGun: NSCondition)
        {
            XCTAssertTrue(Thread.isMainThread)  // we expect tests to run on the main thread

            for _ in 0..<iterationsPerBarrierStage {
                async {
                    XCTAssertTrue(!Thread.isMainThread)
                    startingGun.lock()
                    while !startAsyncWork {
                        if !startingGun.wait(until: Date().addingTimeInterval(1.0)) {
                            RunLoop.current.run(mode: .defaultRunLoopMode, before: Date().addingTimeInterval(1.0))
                        }
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

            for _ in 0..<iterationsPerBarrierStage {
                asyncBarrier {
                    XCTAssertTrue(!Thread.isMainThread)

                    semaphore.lock()

                    XCTAssertTrue(preBarrierStageCompleted == self.iterationsPerBarrierStage)
                    XCTAssertTrue(postBarrierStageCompleted == 0)

                    inBarrierStageCompleted += 1

                    semaphore.signal()
                    semaphore.unlock()
                }
            }

            for _ in 0..<iterationsPerBarrierStage {
                async {
                    XCTAssertTrue(!Thread.isMainThread)

                    semaphore.lock()

                    XCTAssertTrue(preBarrierStageCompleted == self.iterationsPerBarrierStage)
                    XCTAssertTrue(inBarrierStageCompleted == self.iterationsPerBarrierStage)

                    postBarrierStageCompleted += 1

                    semaphore.signal()
                    semaphore.unlock()
                }
            }
        }

        for _ in 0..<iterationsOfBarrierTest {
            let semaphore = NSCondition()
            let startingGun = NSCondition()
            testBarrier(with: semaphore, startingGun: startingGun)
            let waitingFor = iterationsPerBarrierStage * 3  // because there are 3 test stages

            var completed = 0
            semaphore.lock()
            startingGun.lock()
            startAsyncWork = true
            startingGun.broadcast()
            startingGun.unlock()
            while completed < waitingFor {
                if !semaphore.wait(until: Date().addingTimeInterval(1.0)) {
                    RunLoop.current.run(mode: .defaultRunLoopMode, before: Date().addingTimeInterval(1.0))
                }
                completed = preBarrierStageCompleted + inBarrierStageCompleted + postBarrierStageCompleted
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
