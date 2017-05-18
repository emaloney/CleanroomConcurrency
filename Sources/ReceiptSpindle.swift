//
//  ReceiptSpindle.swift
//  CleanroomConcurrency
//
//  Created by Evan Maloney on 5/17/17.
//  Copyright © 2017 Gilt Groupe. All rights reserved.
//

import Foundation

/**
 Allows you to store related receipts together in a single place, to
 prevent proliferation of `Receipt` references that might defeat certain 
 memory management strategies, such as relying on automatic de-registration
 upon `Receipt` deallocation.
 */
open class ReceiptSpindle
{
    private var idsToReceipts: LockedResource<[ObjectIdentifier: Receipt]>

    /**
     Creates a new `ReceiptSpindle` using the specified `LockMechanism`.

     - parameter mechanism: A `LockMechanism` value that governs the type of
     lock used for protecting concurrent access to the spindle.
     */
    public init(lock mechanism: LockMechanism = .readWrite)
    {
        idsToReceipts = LockedResource(resource: [ObjectIdentifier: Receipt](), lock: mechanism)
    }

    /**
     Creates a new `ReceiptSpindle` using the specified `Lock`.

     - parameter lock: The `Lock` instance that will be used for protecting
     concurrent access to the spindle.
     */
    public init(lock: Lock)
    {
        idsToReceipts = LockedResource(resource: [ObjectIdentifier: Receipt](), lock: lock)
    }

    /**
     Adds a receipt to the spindle, ensuring that the receipt (and the
     object it references) is not deallocated.
     
     - parameter receipt: The `Receipt` to add to the spindle.
     
     - returns: A receipt identifier that can be used to remove `receipt` from
     the spindle at a later time.
     */
    @discardableResult
    open func add(_ receipt: Receipt)
        -> ObjectIdentifier
    {
        return idsToReceipts.write { receipts in
            receipts[receipt.id] = receipt
            return receipt.id
        }
    }

    /**
     Removes the `Receipt`s with the given identifiers from the spindle.

     - parameter receiptIDs: The `ObjectIdentifier`s of the `Receipt`s
     to be removed from the spindle.

     - returns: The number of receipts removed from the spindle.
     */
    @discardableResult
    open func remove(_ receiptIDs: [ObjectIdentifier])
        -> Int
    {
        let removed = idsToReceipts.write { receipts in
            return receiptIDs.reduce(0) {
                let removed = (receipts.removeValue(forKey: $1) != nil)
                return $0 + (removed ? 1 : 0)
            }
        }
        return removed
    }

    /**
     Removes the `Receipt` with the given identifier from the spindle.

     - parameter receiptID: The `ObjectIdentifier` of the `Receipt` to be
     removed from the spindle.

     - returns: `true` if there was a `Receipt` on the spindle for the
     `receiptIdentifier` (and it was removed); `false` if nothing was done
     because no receipt with the given identifier was found on the spindle.
     */
    @discardableResult
    open func remove(_ receiptID: ObjectIdentifier)
        -> Bool
    {
        return remove([receiptID]) > 0
    }
}
