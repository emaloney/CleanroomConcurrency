//
//  Registry.swift
//  Cleanroom Project
//
//  Created by Evan Maloney on 2/21/17.
//  Copyright © 2017 Gilt Groupe. All rights reserved.
//

/**
 `Registry` is a generic class designed to keep track of items (of type `T`)
 in a thread-safe way.
 
 The lifetime of an item in the registry is determined by the `Receipt` that
 was returned when the item was registered.
 
 You must maintain at least one strong reference to the returned `Receipt` for
 the duration of the time that you want the item it represents to remain
 registered. Once the `Receipt` deallocates, the associated item is removed
 from the registry.
 */
public class Registry<T>
{
    private var idsToRegistrants: LockedResource<[ObjectIdentifier: T]>

    /** The signature of a function to be called when a registrant is being
     de-registered. */
    public typealias DeregistrationHookFunction = (_ registry: Registry<T>, _ registrant: T, _ receipt: Receipt) -> Void

    /** `true` if the `Registry` contains 0 registrants; `false` if it contains
     at lease one registrant. */
    public var isEmpty: Bool {
        return idsToRegistrants.read { return $0.isEmpty }
    }

    /** The number of registered items. */
    public var count: Int {
        return idsToRegistrants.read { return $0.count }
    }

    /** An optional `DeregistrationHookFunction` which, if set, will be called
     when an item is being de-registered. */
    public var deregistrationHook: DeregistrationHookFunction?

    /**
     Creates a new `Registry` using the specified `LockMechanism`.

     - parameter mechanism: A `LockMechanism` value that governs the type of
     lock used for protecting concurrent access to the registry.
     */
    public init(lock mechanism: LockMechanism = .readWrite)
    {
        idsToRegistrants = LockedResource(resource: [ObjectIdentifier: T](), lock: mechanism)
    }

    /**
     Creates a new `Registry` using the specified `Lock`.

     - parameter lock: The `Lock` instance that will be used for protecting
     concurrent access to the registry.
     */
    public init(lock: Lock)
    {
        idsToRegistrants = LockedResource(resource: [ObjectIdentifier: T](), lock: lock)
    }

    /**
     Adds an item to the registry.
     
     You must maintain a reference to the returned `Receipt` for as long as
     you wish to have `item` registered. When the `Receipt` deallocates,
     `item` will be deregistered. You can also force deregistration prior
     to deallocation by calling the `Receipt`'s `deregister()` function.

     - parameter item: The item to register.

     - returns: A `Receipt` that controls the duration of `item`'s
     registration with the receiver.
     */
    public func register(_ item: T)
        -> Receipt
    {
        let receipt = ReceiptImpl<T>(registry: self)
        idsToRegistrants.write {
            $0[receipt.id] = item
        }
        return receipt
    }

    /** The items currently in the `Registry`. */
    public var registrants: [T] {
        return idsToRegistrants.read { [T]($0.values) }
    }

    /**
     Performs the given function once for each registered object.
     
     - parameter function: A function to perform on each object currently
     registered with the receiver.
     */
    public func withEachRegistrant(perform function: (T) -> Void)
    {
        registrants.forEach {
            function($0)
        }
    }

    fileprivate func deregister(_ receipt: Receipt)
    {
        guard let receipt = receipt as? ReceiptImpl<T> else {
            // if it isn't a ReceiptImpl, it's not ours
            return
        }

        if let deregistrationHook = deregistrationHook {
            let registrant = idsToRegistrants.read { $0[receipt.id] }
            if let registrant = registrant {
                deregistrationHook(self, registrant, receipt)
            }
        }

        idsToRegistrants.write {
            $0.removeValue(forKey: receipt.id)
        }
    }
}

private class ReceiptImpl<T>: Receipt
{
    var id: ObjectIdentifier {
        return _id
    }
    private var _id: ObjectIdentifier!
    private weak var registry: Registry<T>?

    init(registry: Registry<T>)
    {
        self.registry = registry
        _id = ObjectIdentifier(self)
    }

    deinit {
        deregister()
    }

    func deregister()
    {
        registry?.deregister(self)
        registry = nil
    }
}
