//
//  ThreadLocalValue.swift
//  Cleanroom Project
//
//  Created by Evan Maloney on 3/25/15.
//  Copyright © 2015 Gilt Groupe. All rights reserved.
//

import Foundation

/**
 Provides a type-safe mechanism for accessing thread-local values (of type `T`)
 stored in the `threadDictionary` associated with the calling thread.

 As the class name implies, values set using `ThreadLocalValue` are only visible
 to the thread that set those values.
 */
public struct ThreadLocalValue<T: Any>
{
    /** If the receiver was initialized with a `namespace`, this property
     will contain that value. */
    public let namespace: String?

    /** The `key` that was originally passed to the receiver's initializer.
     If the receiver was initialized with a `namespace`, this value *will not*
     include the namespace; `fullKey` will include the namespace. */
    public let key: String

    /** Contains the key that will be used to access the underlying
     `threadDictionary`. Unless the receiver was initialized with a
     `namespace`, this value will be the same as `key`. */
    public let fullKey: String

    /** The signature of a function to be used for providing values when
     none exist in the `current` thread's `threadDictionary`. */
    public typealias ValueProvider = (ThreadLocalValue) -> T?

    private let valueProvider: ValueProvider

    /**
     Initializes a new instance referencing the thread-local value associated
     with the specified key.

     - parameter key: The key used to access the value associated with the
     receiver in the `threadDictionary`.

     - parameter valueProvider: A `ValueProvider` function used to provide a
     value when the underlying `threadDictionary` does not contain a value.
     */
    public init(key: String, valueProvider: @escaping ValueProvider = { _ in return nil })
    {
        self.namespace = nil
        self.key = key
        self.fullKey = key
        self.valueProvider = valueProvider
    }

    /**
     Initializes a new instance referencing the thread-local value associated
     with the specified namespace and key.

     - parameter namespace: The name of the code module that will own the
     receiver. This is used in constructing the `fullKey`.

     - parameter key: The key within the namespace. Used to construct the
     `fullKey` associated with the receiver.

     - parameter valueProvider: A `ValueProvider` function used to provide a
     value when the underlying `threadDictionary` does not contain a value.
     */
    public init(namespace: String, key: String, valueProvider: @escaping ValueProvider = { _ in return nil })
    {
        self.namespace = namespace
        self.key = key
        self.fullKey = "\(namespace).\(key)"
        self.valueProvider = valueProvider
    }

    /** Retrieves the `current` thread's `threadDictionary` value associated
     with the receiver's `fullKey`. If the value is `nil` or if it is not of
     type `T`, the receiver's `valueProvider` will be consulted to provide a
     value, which will be stored in the `threadDictionary` using the key
     `fullKey`. `nil` will be returned if no value was provided. */
    public var value: T? {
        if let value = cachedValue {
            return value
        }

        if let value = valueProvider(self) {
            set(value)
            return value
        }
        return nil
    }

    /** Retrieves the `threadDictionary` value currently associated with the
     receiver's `fullKey`. Will be `nil` if there is no value associated with
     `fullKey` or if the underlying value is not of type `T`. */
    public var cachedValue: T? {
        return Thread.current.threadDictionary[fullKey] as? T
    }

    /**
     Sets a new value in the `current` thread's `threadDictionary` for the key
     specified by the receiver's `fullKey` property.

     - parameter newValue: The new thread-local value.
     */
    public func set(_ newValue: T?)
    {
        Thread.current.threadDictionary[fullKey] = newValue
    }
}

