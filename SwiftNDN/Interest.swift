//
//  Interest.swift
//  SwiftNDN
//
//  Created by Wentao Shang on 2/28/15.
//  Copyright (c) 2015 Wentao Shang. All rights reserved.
//

import Foundation

public class Interest: Tlv {
    
    public class Selectors: Tlv {
        
        public class Exclude: Tlv {
            
            var filter = [[UInt8]]()
            
            public override init() {
                super.init()
            }
            
            public init(filter: [[UInt8]]) {
                self.filter = filter
            }
            
            public init?(block: Block) {
                super.init()
                if block.type != TypeCode.Exclude {
                    return nil
                }
                switch block.value {
                case .Blocks(let blocks):
                    for blk in blocks {
                        if blk.type == TypeCode.Any {
                            self.filter.append([])
                        } else if let nc = Name.Component(block: blk) {
                            self.filter.append(nc.value)
                        } else {
                            return nil
                        }
                    }
                default: return nil
                }
            }
            
            public override var block: Block? {
                var blocks = [Block]()
                for arr in self.filter {
                    if arr.isEmpty {
                        blocks.append(Block(type: TypeCode.Any))
                    } else if let ncb = Name.Component(bytes: arr).block {
                        blocks.append(ncb)
                    }
                }
                return Block(type: TypeCode.Exclude, blocks: blocks)
            }
            
            // Return true if the component is covered by the exclude filter (i.e., should be excluded)
            // Return false if not covered
            public func matchesComponent(component: Name.Component) -> Bool {
                var lowerBound: Name.Component? = nil
                var insideRange = false  // flag
                
                for arr in self.filter {
                    if arr.isEmpty {
                        // Got ANY
                        insideRange = true // set flag
                    } else {
                        let nc = Name.Component(bytes: arr)
                        if insideRange {
                            // Got upper bound
                            if component <= nc {
                                // Check lowerbound if available
                                if let lb = lowerBound {
                                    if lb <= component {
                                        return true
                                    }
                                } else {
                                    // Current range is (*, nc]
                                    return true
                                }
                            }
                            // Clear lowerbound and reset flag
                            lowerBound = nil
                            insideRange = false
                        } else {
                            // Got new lowerbound
                            // If lowerbound is already set, check it before overwriting it
                            if let lb = lowerBound {
                                if lb == component {
                                    return true
                                }
                            }
                            // Set new lowerbound
                            lowerBound = nc
                        }
                    }
                }
                if let lb = lowerBound {
                    if insideRange {
                        // The last range is a right-open range [lb, *)
                        if lb <= component {
                            return true
                        }
                    } else {
                        // The last range is a single component
                        if lb == component {
                            return true
                        }
                    }
                }
                return false
            }
        }
        
        public class ChildSelector: Tlv {
            
            struct Val {
                static let LeftmostChild: UInt64 = 0
                static let RightmostChild: UInt64 = 1
            }
            
            var value: UInt64 = Val.LeftmostChild
            
            public override init() {
                super.init()
            }
            
            public init(value: UInt64) {
                self.value = value
            }
            
            public init?(block: Block) {
                super.init()
                if block.type != TypeCode.ChildSelector {
                    return nil
                }
                switch block.value {
                case .RawBytes(let bytes):
                    self.value = Buffer.byteArrayToNonNegativeInteger(bytes)
                default: return nil
                }
            }
            
            public override var block: Block? {
                let bytes = Buffer.nonNegativeIntegerToByteArray(value)
                return Block(type: TypeCode.ChildSelector, bytes: bytes)
            }
        }
        
        public class MustBeFresh: Tlv {
            
            public override var block: Block? {
                return Block(type: TypeCode.MustBeFresh)
            }
            
            public override init() {
                super.init()
            }
            
            public init?(block: Block) {
                super.init()
                if block.type != TypeCode.MustBeFresh {
                    return nil
                }
            }
        }
    }
    
    public class Scope: Tlv {
        
        struct Val {
            static let LocalDaemon: UInt64 = 0
            static let LocalHost: UInt64 = 1
            static let LocalHub: UInt64 = 2
        }
        
        var value: UInt64 = Val.LocalHost
        
        public override init() {
            super.init()
        }
        
        public init(value: UInt64) {
            self.value = value
        }
        
        public init?(block: Block) {
            super.init()
            if block.type != TypeCode.Scope {
                return nil
            }
            switch block.value {
            case .RawBytes(let bytes):
                self.value = Buffer.byteArrayToNonNegativeInteger(bytes)
            default: return nil
            }
        }
        
        public override var block: Block? {
            let bytes = Buffer.nonNegativeIntegerToByteArray(value)
            return Block(type: TypeCode.Scope, bytes: bytes)
        }
    }
    
    public class InterestLifetime: Tlv {
        
        var value: UInt64 = 4000 // in ms
        
        public override init() {
            super.init()
        }
        
        public init(value: UInt64) {
            self.value = value
        }
        
        public init?(block: Block) {
            super.init()
            if block.type != TypeCode.InterestLifetime {
                return nil
            }
            switch block.value {
            case .RawBytes(let bytes):
                self.value = Buffer.byteArrayToNonNegativeInteger(bytes)
            default: return nil
            }
        }
        
        public override var block: Block? {
            let bytes = Buffer.nonNegativeIntegerToByteArray(value)
            return Block(type: TypeCode.InterestLifetime, bytes: bytes)
        }
    }
    
    public class Nonce: Tlv {
        
        var value = [UInt8](count: 4, repeatedValue: 0)
        
        public override var block: Block? {
            return Block(type: TypeCode.Nonce, bytes: self.value)
        }
        
        public override init() {
            super.init()
            
            let random32bit = arc4random()
            value[0] = UInt8((random32bit >> 24) & 0xFF)
            value[1] = UInt8((random32bit >> 16) & 0xFF)
            value[2] = UInt8((random32bit >> 8) & 0xFF)
            value[3] = UInt8(random32bit & 0xFF)
        }
        
        public init?(block: Block) {
            super.init()
            if block.type != TypeCode.Nonce {
                return nil
            }
            switch block.value {
            case .RawBytes(let bytes):
                if bytes.count != 4 {
                    return nil
                } else {
                    self.value = bytes
                }
            default: return nil
            }
        }
    }
    
    public var name = Name()
    
    public var nonce = Nonce()
    public var scope: Scope?
    public var interestLifetime: InterestLifetime?
    
    public override init() {
        super.init()
    }
    
    public override var block: Block? {
        var blk = Block(type: TypeCode.Interest)
        if let nameBlock = self.name.block {
            blk.appendBlock(nameBlock)
        } else {
            return nil
        }
        
        blk.appendBlock(self.nonce.block!) // Nonce.block will never return nil
        
        if let scopeBlock = self.scope?.block {
            blk.appendBlock(scopeBlock)
        }
        
        if let ilBlock = self.interestLifetime?.block {
            blk.appendBlock(ilBlock)
        }
        
        return blk
    }
    
    public init?(block: Block) {
        super.init()
        if block.type != TypeCode.Interest {
            return nil
        }
        switch block.value {
        case .Blocks(let blocks):
            var hasName = false
            var hasNonce = false
            for blk in blocks {
                if let na = Name(block: blk) {
                    self.name = na
                    hasName = true
                } else if let no = Nonce(block: blk) {
                    self.nonce = no
                    hasNonce = true
                } else if let so = Scope(block: blk) {
                    self.scope = so
                } else if let il = InterestLifetime(block: blk) {
                    self.interestLifetime = il
                }
            }
            if !hasName || !hasNonce {
                return nil
            }
        default: return nil
        }
    }
    
    public func setScope(value: UInt64) {
        self.scope = Scope(value: value)
    }
    
    public func getScope() -> UInt64? {
        return self.scope?.value
    }
    
    public func setInterestLifetime(value: UInt64) {
        self.interestLifetime = InterestLifetime(value: value)
    }
    
    public func getInterestLifetime() -> UInt64? {
        return self.interestLifetime?.value
    }
    
    public class func wireDecode(bytes: [UInt8]) -> Interest? {
        let (block, _) = Block.wireDecode(bytes)
        if let blk = block {
            return Interest(block: blk)
        } else {
            return nil
        }
    }
}

public func == (lhs: Interest.Nonce, rhs: Interest.Nonce) -> Bool {
    return lhs.value == rhs.value
}