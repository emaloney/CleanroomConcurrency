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
            XCTAssertTrue(!Thread.isMainThread)

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
//        print("testAsyncBarrierFunction() @ \(#line) -- entering function")

        var startAsyncWork = false
        var preBarrierStageCompleted = 0
        var inBarrierStageCompleted = 0
        var postBarrierStageCompleted = 0

        func testBarrier(with semaphore: NSCondition, startingGun: NSCondition)
        {
            XCTAssertTrue(Thread.isMainThread)  // we expect tests to run on the main thread

//            print("testBarrierWithSemaphore() @ \(#line) -- entering function")

            for _ in 0..<IterationsPerBarrierStage {
//                print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): v enter async {} -- preBarrierStage")

                async {
                    XCTAssertTrue(!Thread.isMainThread)

//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): v startingGun.lock() -- preBarrierStage")
                    startingGun.lock()
//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): ^ startingGun.lock() -- preBarrierStage")
                    while !startAsyncWork {
//                        print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): v startingGun.wait() -- preBarrierStage")
                        startingGun.wait()
//                        print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): ^ startingGun.wait() -- preBarrierStage")
                    }
//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): v startingGun.unlock() -- preBarrierStage")
                    startingGun.unlock()
//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): ^ startingGun.unlock() -- preBarrierStage")

//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): v semaphore.lock() -- preBarrierStage")
                    semaphore.lock()
//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): ^ semaphore.lock() -- preBarrierStage")

                    XCTAssertTrue(inBarrierStageCompleted == 0)
                    XCTAssertTrue(postBarrierStageCompleted == 0)

                    preBarrierStageCompleted += 1

//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): v semaphore.signal() -- preBarrierStage")
                    semaphore.signal()
//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): ^ semaphore.signal() -- preBarrierStage")

//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): v semaphore.unlock() -- preBarrierStage")
                    semaphore.unlock()
//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): ^ semaphore.unlock() -- preBarrierStage")
                }

//                print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): ^ leave async {} -- preBarrierStage")
            }

//            print("testBarrierWithSemaphore() @ \(#line)")

            for _ in 0..<IterationsPerBarrierStage {
//                print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): v enter asyncBarrier {} -- inBarrierStage")

                asyncBarrier {
                    XCTAssertTrue(!Thread.isMainThread)

//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): v startingGun.lock() -- inBarrierStage")
                    startingGun.lock()
//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): ^ startingGun.lock() -- inBarrierStage")
                    while !startAsyncWork {
//                        print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): v startingGun.wait() -- inBarrierStage")
                        startingGun.wait()
//                        print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): ^ startingGun.wait() -- inBarrierStage")
                    }
//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): v startingGun.unlock() -- inBarrierStage")
                    startingGun.unlock()
//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): ^ startingGun.unlock() -- inBarrierStage")

//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): v semaphore.lock() -- inBarrierStage")
                    semaphore.lock()
//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): ^ semaphore.lock() -- inBarrierStage")

                    XCTAssertTrue(preBarrierStageCompleted == self.IterationsPerBarrierStage)
                    XCTAssertTrue(postBarrierStageCompleted == 0)

                    inBarrierStageCompleted += 1

//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): v semaphore.signal() -- inBarrierStage")
                    semaphore.signal()
//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): ^ semaphore.signal() -- inBarrierStage")

//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): v semaphore.unlock() -- inBarrierStage")
                    semaphore.unlock()
//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): ^ semaphore.unlock() -- inBarrierStage")
                }

//                print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): ^ leave asyncBarrier {} -- inBarrierStage")
            }

//            print("testBarrierWithSemaphore() @ \(#line)")
            for _ in 0..<IterationsPerBarrierStage {

//                print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): v enter async {} -- postBarrierStage")

                async {
                    XCTAssertTrue(!Thread.isMainThread)

//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): v startingGun.lock() -- postBarrierStage")
                    startingGun.lock()
//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): ^ startingGun.lock() -- postBarrierStage")
                    while !startAsyncWork {
//                        print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): v startingGun.wait() -- postBarrierStage")
                        startingGun.wait()
//                        print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): ^ startingGun.wait() -- postBarrierStage")
                    }
//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): v startingGun.unlock() -- postBarrierStage")
                    startingGun.unlock()
//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): ^ startingGun.unlock() -- postBarrierStage")

//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): v semaphore.lock() -- postBarrierStage")
                    semaphore.lock()
//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): ^ semaphore.lock() -- postBarrierStage")

                    XCTAssertTrue(preBarrierStageCompleted == self.IterationsPerBarrierStage)
                    XCTAssertTrue(inBarrierStageCompleted == self.IterationsPerBarrierStage)

                    postBarrierStageCompleted += 1

//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): v semaphore.signal() -- postBarrierStage")
                    semaphore.signal()
//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): ^ semaphore.signal() -- postBarrierStage")

//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): v semaphore.unlock() -- postBarrierStage")
                    semaphore.unlock()
//                    print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): ^ semaphore.unlock() -- postBarrierStage")
                }

//                print("testBarrierWithSemaphore() @ \(#line) (\(i+1)/\(self.IterationsPerBarrierStage)): ^ leave async {} -- postBarrierStage")
            }

//            print("testBarrierWithSemaphore() @ \(#line) -- leaving function")
        }

//        print("testAsyncBarrierFunction() @ \(#line): v enter main test loop (will execute \(IterationsOfBarrierTest) times)")

        for _ in 0..<IterationsOfBarrierTest {
//            print("testAsyncBarrierFunction() @ \(#line) (\(i+1)/\(IterationsOfBarrierTest)): creating semaphore")

            let semaphore = NSCondition()
            let startingGun = NSCondition()

//            print("testAsyncBarrierFunction() @ \(#line) (\(i+1)/\(IterationsOfBarrierTest)): v testBarrierWithSemaphore()")
            testBarrier(with: semaphore, startingGun: startingGun)
//            print("testAsyncBarrierFunction() @ \(#line) (\(i+1)/\(IterationsOfBarrierTest)): ^ testBarrierWithSemaphore()")

            let waitingFor = IterationsPerBarrierStage * 3  // because there are 3 test stages

            var completed = 0
            var lastCompleted: Int?
//            print("testAsyncBarrierFunction() @ \(#line) (\(i+1)/\(IterationsOfBarrierTest)): v semaphore.lock()")
            semaphore.lock()
//            print("testAsyncBarrierFunction() @ \(#line) (\(i+1)/\(IterationsOfBarrierTest)): ^ semaphore.lock()")

//            print("testAsyncBarrierFunction() @ \(#line): v startingGun.lock()")
            startingGun.lock()
//            print("testAsyncBarrierFunction() @ \(#line): ^ startingGun.lock()")
            startAsyncWork = true
//            print("testAsyncBarrierFunction() @ \(#line): v startingGun.broadcast()")
            startingGun.broadcast()
//            print("testAsyncBarrierFunction() @ \(#line): ^ startingGun.broadcast()")
//            print("testAsyncBarrierFunction() @ \(#line): v startingGun.unlock()")
            startingGun.unlock()
//            print("testBarrierWithSemaphore() @ \(#line): ^ startingGun.unlock()")

            while completed < waitingFor {
//                print("testAsyncBarrierFunction() @ \(#line) (\(i+1)/\(IterationsOfBarrierTest)): v semaphore.waitUntilDate()")
                let result = semaphore.wait(until: Date().addingTimeInterval(1.1))
//                print("testAsyncBarrierFunction() @ \(#line) (\(i+1)/\(IterationsOfBarrierTest)): ^ semaphore.waitUntilDate()")
                if result {
                    completed = preBarrierStageCompleted + inBarrierStageCompleted + postBarrierStageCompleted
                    if let last = lastCompleted {
                        XCTAssertTrue(completed > last)
                    }
                    lastCompleted = completed
                }
                else {
//                    print("testAsyncBarrierFunction() @ \(#line) (\(i+1)/\(IterationsOfBarrierTest)): FAILED TO ACQUIRE LOCK IN TIME!")
                }
            }
//            print("testAsyncBarrierFunction() @ \(#line) (\(i+1)/\(IterationsOfBarrierTest)): v semaphore.unlock()")
            semaphore.unlock()
//            print("testAsyncBarrierFunction() @ \(#line) (\(i+1)/\(IterationsOfBarrierTest)): ^ semaphore.unlock()")

            XCTAssertTrue(completed == waitingFor)

            // reset vars for next run
            preBarrierStageCompleted = 0
            inBarrierStageCompleted = 0
            postBarrierStageCompleted = 0
        }

//        print("testAsyncBarrierFunction() @ \(#line): ^ leave main test loop")
//
//        print("testAsyncBarrierFunction() @ \(#line) -- leaving function")
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
