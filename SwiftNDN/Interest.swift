//
//  Interest.swift
//  SwiftNDN
//
//  Created by Wentao Shang on 2/28/15.
//  Copyright (c) 2015 Wentao Shang. All rights reserved.
//

import Foundation

public class Interest: Tlv {
    
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
        
        return blk
    }
    
    public init?(block: Block) {
        super.init()
        if block.type != TypeCode.Interest {
            return nil
        }
        switch block.value {
        case .Blocks(let blocks):
            if let na = Name(block: blocks[0]) {
                self.name = na
            } else {
                return nil
            }
            
            if let no = Nonce(block: blocks[1]) {
                self.nonce = no
            } else {
                return nil
            }
        default: return nil
        }
    }
    
    public class func wireDecode(buf: Buffer) -> Interest? {
        let (block, _) = Block.wireDecode(buf)
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