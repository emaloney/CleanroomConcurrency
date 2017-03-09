//
//  Receipt.swift
//  Cleanroom Project
//
//  Created by Evan Maloney on 3/7/17.
//  Copyright © 2017 Gilt Groupe. All rights reserved.
//

/**
 Represents a specific registrant within a specific `Registry`.
 
 A `Receipt` is given when an item is registered, and is used to manage the
 lifetime of item in the registry.
 
 When the `Receipt` is deallocated, the associated registrant is automatically
 de-registered. You can also call `deregister()` to force removal of the item
 prior to deallocation of its `Receipt`.
 */
public protocol Receipt: class
{
    /**
     Removes the item represented by this `Receipt` from the `Registry`
     to which it is registered.
     */
    func deregister()
}
