//
//  ThreadLocalValueTests.swift
//  Cleanroom Project
//
//  Created by Evan Maloney on 3/25/15.
//  Copyright © 2015 Gilt Groupe. All rights reserved.
//

import XCTest
import CleanroomConcurrency

private var counter = 0
private var remainingThreads = 0

class ThreadLocalValueTests: XCTestCase
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

    func testThreadLocalValue()
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

    func testNamespacing()
    {
        let tlv1 = ThreadLocalValue<NSString>(namespace: "namespace", key: "key")
        XCTAssertTrue(tlv1.fullKey.hasPrefix("namespace"))
        XCTAssertTrue(tlv1.fullKey.hasSuffix("key"))

        let tlv2 = ThreadLocalValue<NSString>(namespace: "space2", key: "key")
        XCTAssertTrue(tlv2.fullKey.hasPrefix("space2"))
        XCTAssertTrue(tlv2.fullKey.hasSuffix("key"))

        tlv1.set("tlv1 value")
        tlv2.set("tlv2 value")

        XCTAssertTrue(tlv1.value == "tlv1 value")
        XCTAssertTrue(tlv2.value == "tlv2 value")
    }

    func testValueStorage()
    {
        let tlv1 = ThreadLocalValue<NSString>(key: "key")
        XCTAssertTrue(tlv1.fullKey == "key")

        let tlv2 = ThreadLocalValue<NSString>(key: "key")
        XCTAssertTrue(tlv2.fullKey == "key")

        tlv1.set("foo")

        XCTAssertTrue(tlv2.cachedValue == "foo")
    }

    func testInstantiator()
    {
        let NumberOfThreads = 100

        class TestThread: Thread
        {
            let resultStorage: NSMutableDictionary
            let signal: NSCondition

            init(threadNumber: Int, resultStorage: NSMutableDictionary, signal: NSCondition)
            {
                self.resultStorage = resultStorage
                self.signal = signal
                super.init()
                self.name = "Test thread \(threadNumber)"
            }

            override func main()
            {
                let tlv = ThreadLocalValue<String>(key: "threadName") { _ in
                    return Thread.current.name
                }

                var result = false
                let threadName = Thread.current.name!
                if let value = tlv.value {
                    result = value == threadName
                }

                self.signal.lock()
                self.resultStorage[threadName] = NSNumber(value: result)
                self.signal.signal()
                self.signal.unlock()
            }
        }

        let results = NSMutableDictionary()
        let signal = NSCondition()

        for i in 0..<NumberOfThreads {
            TestThread(threadNumber: i, resultStorage: results, signal: signal).start()
        }

        signal.lock()
        while results.count < NumberOfThreads {
            signal.wait()
        }
        signal.unlock()

        for (key, value) in results {
            if let result = (value as? NSNumber)?.boolValue {
                XCTAssertTrue(result, "Test failed for thread \(key)")
            }
        }
    }

    func testValueRetrievalVariations()
    {
        let tlv = ThreadLocalValue<NSString>(key: "lazy") { _ in
            return "I'm not taciturn, I'm just laconic."
        }

        XCTAssertTrue(Thread.current.threadDictionary["lazy"] == nil)
        XCTAssertTrue(tlv.cachedValue == nil)
        XCTAssertTrue(tlv.value == "I'm not taciturn, I'm just laconic.")
        XCTAssertTrue(tlv.cachedValue == "I'm not taciturn, I'm just laconic.")
        XCTAssertTrue(Thread.current.threadDictionary["lazy"] as? String == "I'm not taciturn, I'm just laconic.")
    }
}
