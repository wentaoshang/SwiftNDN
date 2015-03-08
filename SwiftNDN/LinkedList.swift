//
//  LinkedList.swift
//  SwiftNDN
//
//  Created by Wentao Shang on 3/7/15.
//  Copyright (c) 2015 Wentao Shang. All rights reserved.
//

import Foundation

public class ListEntry<T> {
    weak var prev: ListEntry?
    var next: ListEntry?
    
    public var value: T?
    
    public init() {
        self.prev = nil
        self.next = nil
        self.value = nil
    }
    
    public init(value: T) {
        self.value = value
        self.prev = nil
        self.next = nil
    }
    
    public func detach() {
        self.prev?.next = self.next
        self.next?.prev = self.prev
    }
}

public class LinkedList<T> {
    var head: ListEntry<T>
    var tail: ListEntry<T>
    
    // O(n) complexity
    public var size: Int {
        var s = 0
        var iter = head.next
        while iter !== tail && iter != nil {
            ++s
            iter = iter?.next
        }
        return s
    }
    
    public init() {
        head = ListEntry<T>()
        tail = ListEntry<T>()
        
        head.next = tail
        tail.prev = head
    }
    
    public var isEmpty: Bool {
        return head.next! === tail
    }
    
    public func appendAtTail(t: T) -> ListEntry<T> {
        var entry = ListEntry<T>(value: t)
        tail.prev?.next = entry
        entry.prev = tail.prev
        entry.next = tail
        tail.prev = entry
        return entry
    }
    
    public func appendInFront(t: T) -> ListEntry<T> {
        var entry = ListEntry<T>(value: t)
        head.next?.prev = entry
        entry.next = head.next
        entry.prev = head
        head.next = entry
        return entry
    }
    
    public func forEach(action: (t: T) -> Void) {
        var iter = head.next
        while iter !== tail && iter != nil {
            if let value = iter!.value {
                action(t: value)
            }
            iter = iter!.next
        }
    }
    
    public func forEachEntry(action: (t: ListEntry<T>) -> Void) {
        var iter = head.next
        while iter !== tail && iter != nil {
            var iterNext = iter!.next
            action(t: iter!)
            iter = iterNext
        }
    }
    
    public func findOneIf(condition: (t: T) -> Bool) -> T? {
        var iter = head.next
        while iter !== tail && iter != nil {
            if let entry = iter {
                if let value = entry.value {
                    if condition(t: value) {
                        return value
                    }
                }
            }
            iter = iter?.next
        }
        return nil
    }
    
    public func findAllIf(condition: (t: T) -> Bool) -> [T] {
        var arr = [T]()
        var iter = head.next
        while iter !== tail && iter != nil {
            if let entry = iter {
                if let value = entry.value {
                    if condition(t: value) {
                        arr.append(value)
                    }
                }
            }
            iter = iter?.next
        }
        return arr
    }

    
    public func removeOneIf(condition: (t: T) -> Bool) -> Bool {
        var iter = head.next
        while iter !== tail && iter != nil {
            var iterNext = iter?.next
            if let entry = iter {
                if let value = entry.value {
                    if condition(t: value) {
                        entry.detach()
                        return true
                    }
                }
            }
            iter = iterNext
        }
        return false
    }
    
    public func removeAllIf(condition: (t: T) -> Bool) -> Bool {
        var removedSomething = false
        var iter = head.next
        while iter !== tail && iter != nil {
            var iterNext = iter?.next
            if let entry = iter {
                if let value = entry.value {
                    if condition(t: value) {
                        entry.detach()
                        removedSomething = true
                    }
                }
            }
            iter = iterNext
        }
        return removedSomething
    }
}