![Gilt Tech logo](https://raw.githubusercontent.com/gilt/Cleanroom/master/Assets/gilt-tech-logo.png)

# CleanroomConcurrency

CleanroomConcurrency provides utilities for simplifying asynchronous code execution and coordinating concurrent access to shared resources.

CleanroomConcurrency is part of [the Cleanroom Project](https://github.com/gilt/Cleanroom) from [Gilt Tech](http://tech.gilt.com).


### Swift compatibility

This is the `master` branch. It uses **Swift 3.0.2** and **requires Xcode 8.2** to compile.


#### Current status

Branch|Build status
--------|------------------------
[`master`](https://github.com/emaloney/CleanroomConcurrency)|[![Build status: master branch](https://travis-ci.org/emaloney/CleanroomConcurrency.svg?branch=master)](https://travis-ci.org/emaloney/CleanroomConcurrency)


### License

CleanroomConcurrency is distributed under [the MIT license](https://github.com/emaloney/CleanroomConcurrency/blob/master/LICENSE).

CleanroomConcurrency is provided for your use—free-of-charge—on an as-is basis. We make no guarantees, promises or apologies. *Caveat developer.*


### Adding CleanroomConcurrency to your project

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

The simplest way to integrate CleanroomConcurrency is with the [Carthage](https://github.com/Carthage/Carthage) dependency manager.

First, add this line to your [`Cartfile`](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile):

```
github "emaloney/CleanroomConcurrency" ~> 1.0.0
```

Then, use the `carthage` command to [update your dependencies](https://github.com/Carthage/Carthage#upgrading-frameworks).

Finally, you’ll need to [integrate CleanroomConcurrency into your project](https://github.com/emaloney/CleanroomConcurrency/blob/master/INTEGRATION.md) in order to use [the API](https://rawgit.com/emaloney/CleanroomConcurrency/master/Documentation/API/index.html) it provides.

Once successfully integrated, just add the following `import` statement to any Swift file where you want to use CleanroomConcurrency:

```swift
import CleanroomConcurrency
```

See [the Integration document](https://github.com/emaloney/CleanroomConcurrency/blob/master/INTEGRATION.md) for additional details on integrating CleanroomConcurrency into your project.

## Using CleanroomConcurrency

CleanroomConcurrency provides:

- A small set of global [asynchronous dispatching functions](#asyncfunctions) that declare a simplified interface for executing code asynchronously.

- [`CriticalSection`](#criticalsection) — A simple way to synchronize the execution of code across multiple threads.

- [`ReadWriteCoordinator`](#readwritecoordinator) — A mechanism to coordinate access to mutable resources shared across multiple threads.

- [`ThreadLocalValue`](#threadlocalvalue) — Simplifies access to thread-local values stored in the `threadDictionary` of the calling `NSThread`.

### AsyncFunctions

The [`AsyncFunctions.swift`](AsyncFunctions.swift) file contains top-level functions that declare a simplified interface for executing code asynchronously.

Under the hood, these functions all rely on a single, privately-maintained concurrent Grand Central Dispatch (GCD) queue.

#### async

The `async` function provides a simple notation for specifying that a block of code should be executed asynchronously.

`async` takes as a parameter a no-argument function returning `Void`, and is typically invoked with a closure:

```swift
async {
	println("This will execute asynchronously")
}
```

The operation specified by the closure—the `println()` call above—will be executed asynchronously.
 
#### async with delay

A variation on the `async` function takes a `delay` parameter, an `NSTimeInterval` value specifying the *minimum* number of seconds to wait before asynchronously executing the closure:

```swift
async(delay: 0.35) {
	println("This will execute asynchronously after at least 0.35 seconds")
}
```

Note that this function does not perform real-time scheduling, so the asynchronous operation is **not** guaranteed to execute immediately once `delay` number of seconds has elapsed; instead, it will execute after *at least* `delay` number of seconds has elapsed.

#### mainThread

The `mainThread` function enqueues an operation for eventual execution on the main `NSThread` of the application.

This is useful because certain operations are only allowed to be executed on the main thread, such as view hierarchy manipulations. This is why the main thread is sometimes called *the user interface thread*.

The `mainThread` function is typically invoked with a closure as follows:

```swift
mainThread {
	UIApplication.sharedApplication().keyWindow!.rootViewController = self
}
```

The notation above ensures that the `rootViewController` is changed only on the main thread.

#### mainThread with delay

As with the `async` function, a variation of the `mainThread` function takes a `delay` parameter:

```swift
mainThread(delay: 0.35) {
	view.hidden = true
	view.alpha = 1.0
}
```

In the example above, the closure will be executed on the main thread after *at least* `0.35` seconds have elapsed.

#### asyncBarrier

The `asyncBarrier` function submits a barrier operation for asynchronous execution.

Barriers make it possible to create a synchronization point for operations:

- Operations submitted prior to the submission of the barrier operation are guaranteed to execute *before* the barrier.

- After all operations submitted prior to the barrier have been executed, *then* the barrier operation is executed. 

- While the barrier operation is executing, no other operations in the queue will execute.

- Once the barrier operation finishes executing, normal concurrent behavior resumes; operations submitted after the barrier will then be executed.

Barrier operations are submitted for eventual execution using the notation:

```swift
asyncBarrier {
	println("When this executes, no other operations will be executing")
}
```

**Important:** Because these functions all rely on a single shared GCD queue, use of the `asyncBarrier` function can have application-wide impact. As a result, the function should be used sparingly, and only in situations where an application-wide barrier is truly needed.

If you do not need an application-wide barrier, it may be best to maintain your own queue and use the `dispatch_barrier_async` GCD function instead.

### CriticalSection

A `CriticalSection` provides a simple way to synchronize the execution of code across multiple threads.

`CriticalSection`s are a form of a *mutex* (or *mutual exclusion*) lock: when one thread is executing code within a given critical section, it is guaranteed that no other thread will be executing within the same instance.

In this way, `CriticalSection`s are similar to `@synchronized` blocks in Objective-C.

#### Using a CriticalSection

With a `CriticalSection`, any code inside the `execute` closure (shown below as the "`// code to execute`" comment) is executed only after exclusive access to the critical section has been acquired by the calling thread.

```swift
let cs = CriticalSection()

cs.execute {
	// code to execute
}
```

Because it is possible for a `CriticalSection` to be used in a way where `execute` could block forever—resulting in a thread dealock—a variation is provided that allows a timeout to be specified:

```swift
let cs = CriticalSection()

let success = cs.executeWithTimeout(1.0) {
	// code to execute
}

if !success {
	// handle the fact that `executeWithTimeout()` timed out
}
```

The timeout is an `NSTimeInterval` value specifying the number of seconds to wait for access to the critical section before giving up.

In the example above, the calling thread may block for up to `1.0` seconds waiting for the critical section represented by `cs` to be acquired.

If `cs` can be acquired within that time, "`// code to execute`" will execute and `executeWithTimeout()` will return `true`.

If exclusive access to the critical section `cs` can't be acquired within `1.0` seconds, nothing will be executed and `executeWithTimeout()` will return `false`.

**Note:** It is best to design your implementation to avoid the potential for a deadlock. However, sometimes this is not possible, which is why the `executeWithTimeout()` function is provided.

#### Implementation Details

The `CriticalSection` implementation uses an `NSRecursiveLock` internally, which enables `CriticalSection`s to be re-entrant. This means that a thread can't deadlock on a `CriticalSection` it already holds.

In addition, the `CriticalSection` implementation also performs internal exception trapping to ensure that the lock state remains consistent.

### ReadWriteCoordinator

`ReadWriteCoordinator` instances can be used to coordinate access to a mutable resource shared across multiple threads.

You can think of the `ReadWriteCoordinator` as a dual read/write lock having the following properties:

- The *read lock* allows any number of *readers* to execute concurrently.

- The *write lock* allows one and only one *writer* to execute at a time.

- As long as there is at least one reader executing, the write lock cannot be acquired.

- As long as the write lock is held, no readers can execute.

- All reads execute synchronously; that is, they block the calling thread until they complete.

- All writes execute asynchronously.

- Any read submitted before a write is guaranteed to be executed before that write, while any write submitted before a read is guaranteed to be executed before that read. This ensures a consistent view of shared resource's state.

> The term *lock* is used in this document for conceptual clarity. In reality, the implementation uses Grand Central Dispatch and not a traditional lock.

#### Usage

For any given shared resource that needs to be protected by a read/write lock, you can create a `ReadWriteCoordinator` instance to manage access to that resource.

```swift
let lock = ReadWriteCoordinator()
```

You would then hold a reference to that `ReadWriteCoordinator` for the lifetime of the shared resource.

#### Reading

Whenever you need read-only access to the shared resource, you wrap your access within a call to the `ReadWriteCoordinator`'s `read()` function, which is typically called with a trailing closure:

```swift
lock.read {
	// read some data from the shared resource
}
```

Because reads are executed synchronously, the `ReadWriteCoordinator` can be used within property getters, eg.:

```swift
var globalCount: Int {
	get {
		var count: Int?
		lock.read {
			count = // get a count from the shared resource
		}
		return count!
	}
}
```

#### Writing

Whenever you need to modify the state of the shared resource, you do so using the `enqueueWrite()` function of the `ReadWriteCoordinator`.

As with `read()`, this function is typically invoked with a closure:

```swift
lock.enqueueWrite {
	// modify the shared resource
}
```

Unlike `read()`, however, the `enqueueWrite()` function is asynchronous, as its name implies. 

Write operations are submitted to the underlying GCD queue, and `enqueueWrite()` returns immediately.

When a write operation is enqueued, any already-pending read operations will be allowed to finish. Once the write lock can be acquired, the function passed to `enqueueWrite()` will be executed.

Under the hood, writes are submitted as asynchronous barrier operations to the receiver's GCD queue, ensuring that reads are always consistent with the order of writes.

### ThreadLocalValue

`ThreadLocalValue` provides a mechanism for accessing thread-local values stored in the `threadDictionary` of the calling `NSThread`.

This implementation provides three main advantages over using the
`threadDictionary` directly:

- **Type-safety** — `ThreadLocalValue` is implemented as a Swift generic, allowing it to enforce type safety.

- **Namespacing to avoid key clashes** — To prevent clashes between different code modules using thread-local storage, `ThreadLocalValue`s can be instantiated with a `namespace` used to construct the underlying `threadDictionary` key.

- **Use thread-local storage as a lockless cache** — `ThreadLocalValue`s can be constructed with an optional `instantiator` that is used to construct values when the underlying `threadDictionary` doesn't have a value for the given key.

#### Namespacing

Namespacing can prevent key clashes when multiple subsystems need to share thread-local storage.

For example, two different subsystems may wish to store an `NSDateFormatter` instance in thread-local storage. If they were each to store their `NSDateFormatter`s using the key "`dateFormatter`", for example, there would be a clash. The first value set for the "`dateFormatter`" key would always be overwritten by the second value set for that key.

Constructing your `ThreadLocalValue` with a `namespace` can prevent that:

```swift
let loggerDateFormatter = ThreadLocalValue<NSDateFormatter>(namespace: "Logger", key: "dateFormatter")

let saleDateFormatter = ThreadLocalValue<NSDateFormatter>(namespace: "SaleViewModel", key: "dateFormatter")
```

When a namespace is used, the `ThreadLocalValue` implementation constructs a value for its `fullKey` property by concatenating the values passed to the `namespace` and `key` parameters in the format "*namespace*.*key*".

In the example above, the `loggerDateFormatter` uses the `fullKey` "`Logger.dateFormatter`" while the `saleDateFormatter` uses "`SaleViewModel.dateFormatter`".

Because only the `fullKey` is used when accessing the underlying `threadDictionary`, these two `ThreadLocalValue` instances can each be used independently without their underlying values conflicting.

> Regardless of whether a `ThreadLocalValue` uses a namespace, the key used to access the `threadDictionary` is always available via the `fullKey` property.

#### Thread-local caching

`ThreadLocalValue` instances can also be used to treat thread-local storage as a lockless cache.

Objects that are expensive to create, such as `NSDateFormatter` instances, can be cached in thread-local storage without incurring the locking overhead that would be required by an object cache shared among multiple threads.

This capability is available to `ThreadLocalValue`s created with an `instantiator` function, and it works as follows:

- If the `value()` function is called when the underlying `threadDictionary` doesn't have a value associated with the receiver's `fullKey`, the `instantiator` will be invoked to create a value.

- If the `instantiator` returns a non-`nil` value, this value will be stored in the `threadDictionary` of the calling thread using the key `fullKey` of the `ThreadLocalValue` instance.

- Future calls to the `ThreadLocalValue`'s `value()` or `cachedValue()` functions will return the value created by the `instantiator` until the underlying value is changed.

Using a `ThreadLocalValue` instance to cache an `NSDateFormatter` would look like:

```swift
let df = ThreadLocalValue<NSDateFormatter>(namespace: "Events", key: "dateFormatter") { _ in
	let fmt = NSDateFormatter()
	fmt.locale = NSLocale(localeIdentifier: "en_US")
	fmt.timeZone = NSTimeZone(forSecondsFromGMT: 0)
	fmt.dateFormat = "yyyyMMdd_HHmmss"
	return fmt
}
```

In the example above, `df` is constructed with an `instantiator` closure. If `df.value()` is called when there is no `NSDateFormatter` associated with the key "`Events.dateFormatter`" in the calling thread's `theadDictionary`, the `instantiator` will be invoked to create a new `NSDateFormatter`.

Using thread-local storage as a cheap cache is best suited for cases where the long-term expense of acquiring read locks every time the object is accessed is greater than the expense of creating a new instance multiplied by the number of unique threads that will access the value.



### API documentation

For detailed information on using CleanroomConcurrency, [API documentation](https://rawgit.com/emaloney/CleanroomConcurrency/master/Documentation/API/index.html) is available.


## About

The Cleanroom Project began as an experiment to re-imagine Gilt’s iOS codebase in a legacy-free, Swift-based incarnation.

Since then, we’ve expanded the Cleanroom Project to include multi-platform support. Much of our codebase now supports tvOS in addition to iOS, and our lower-level code is usable on macOS and watchOS as well.

Cleanroom Project code serves as the foundation of Gilt on TV, our tvOS app [featured by Apple during the launch of the new Apple TV](http://www.apple.com/apple-events/september-2015/). And as time goes on, we'll be replacing more and more of our existing Objective-C codebase with Cleanroom implementations.

In the meantime, we’ll be tracking the latest releases of Swift & Xcode, and [open-sourcing major portions of our codebase](https://github.com/gilt/Cleanroom#open-source-by-default) along the way.


### Contributing

CleanroomConcurrency is in active development, and we welcome your contributions.

If you’d like to contribute to this or any other Cleanroom Project repo, please read [the contribution guidelines](https://github.com/gilt/Cleanroom#contributing-to-the-cleanroom-project).


### Acknowledgements

[API documentation for CleanroomConcurrency](https://rawgit.com/emaloney/CleanroomConcurrency/master/Documentation/API/index.html) is generated using [Realm](http://realm.io)’s [jazzy](https://github.com/realm/jazzy/) project, maintained by [JP Simard](https://github.com/jpsim) and [Samuel E. Giddins](https://github.com/segiddins).

