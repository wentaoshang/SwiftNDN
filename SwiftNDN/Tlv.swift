//
//  Tlv.swift
//  Swift-NDN
//
//  Created by Wentao Shang on 2/26/15.
//  Copyright (c) 2015 Wentao Shang. All rights reserved.
//

import Foundation

public class Tlv {
    
    public struct NDNType {
        public static let Interest: UInt64 = 5
        public static let Data: UInt64 = 6
        public static let Name: UInt64 = 7
        public static let NameComponent: UInt64 = 8
        public static let Selectors: UInt64 = 9
        public static let Nonce: UInt64 = 10
        public static let Scope: UInt64 = 11
        public static let InterestLifetime: UInt64 = 12
        public static let MinSuffixComponent: UInt64 = 13
        public static let MaxSuffixComponent: UInt64 = 14
        public static let PublisherPublicKeyLocator: UInt64 = 15
        public static let Exclude: UInt64 = 16
        public static let ChildSelector: UInt64 = 17
        public static let MustBeFresh: UInt64 = 18
        public static let Any: UInt64 = 19
        public static let MetaInfo: UInt64 = 20
        public static let Content: UInt64 = 21
        public static let SignatureInfo: UInt64 = 22
        public static let SignatureValue: UInt64 = 23
        public static let ContentType: UInt64 = 24
        public static let FreshnessPeriod: UInt64 = 25
        public static let FinalBlockId: UInt64 = 26
        public static let SignatureType: UInt64 = 27
        public static let KeyLocator: UInt64 = 28
        public static let KeyDigest: UInt64 = 29
        public static let ImplicitSha256DigestComponent: UInt64 = 32
        
    }
    
    public class Block {
        
        public var type: UInt64 = 0
        public var value = [UInt8]()
        
        public var length: UInt64 {
            return UInt64(value.count)
        }
        
        public var totalLength: UInt64 {
            let l = self.length
            return l + Buffer.getVarNumberEncodedLength(l)
                + Buffer.getVarNumberEncodedLength(self.type)
        }
        
        public init(type: UInt64) {
            self.type = type
        }
        
        public init(type: UInt64, value: [UInt8]) {
            self.type = type
            self.value = value
        }
        
        public func wireEncode() -> [UInt8] {
            var buf = Buffer(capacity: Int(self.totalLength))
            self.wireEncode(buf)
            return buf.buffer
        }
        
        func wireEncode(buf: Buffer) {
            buf.writeVarNumber(self.type)
                .writeVarNumber(self.length)
                .writeByteArray(self.wireEncodeValue())
        }
        
        public func wireEncodeValue() -> [UInt8] {
            return self.value
        }
        
        public class func wireDecodeWithBytes(bytes: [UInt8]) -> (block: Block?, lengthRead: Int) {
            let buf = Buffer(buffer: bytes)
            return wireDecodeWithBuffer(buf)
        }
        
        public class func wireDecodeWithBuffer(buf: Buffer) -> (block: Block?, lengthRead: Int) {
            // First, read TLV type code
            var lengthRead: Int = 0
            if let (typeNumber, typeLength) = buf.readVarNumber() {
                lengthRead += typeLength
                // Then, read TLV length
                if let (lenNumber, lenLength) = buf.readVarNumber() {
                    lengthRead += lenLength

                    if let (bytes, bytesLength) = buf.readByteArray(Int(lenNumber)) {
                        lengthRead += bytesLength
                        return (Block(type: typeNumber, value: bytes), lengthRead)
                    }
                }
            }
            return (nil, lengthRead)
        }
        
        public class func wireDecodeBlockArray(bytes: [UInt8]) -> [Block]? {
            var bytesRead: Int = 0
            let buf = Buffer(buffer: bytes)
            var ret = [Block]()
            while bytesRead < bytes.count {
                let (block, lengthRead) = Block.wireDecodeWithBuffer(buf)
                if let blk = block {
                    bytesRead += lengthRead
                    ret.append(blk)
                } else {
                    return nil
                }
            }
            return ret
        }
    }
}

public func == (lhs: Tlv.Block, rhs: Tlv.Block) -> Bool {
    if lhs.type != rhs.type {
        return false
    }
    
    if lhs.value != rhs.value {
        return false
    }
    
    return true
}

public func == (lhs: Tlv, rhs: Tlv) -> Bool {
    return false
}

public class NonNegativeIntegerTlv: Tlv.Block {
    
    var tlvType: UInt64 {
        return 0
    }
    
    var defaultValue: UInt64 {
        return 0
    }
    
    public var integerValue: UInt64 = 0
    
    public override var length: UInt64 {
        return Buffer.getNonNegativeIntegerEncodedLength(self.integerValue)
    }
    
    public init() {
        super.init(type: 0)
        self.type = self.tlvType
        self.integerValue = self.defaultValue
    }
    
    public init(value: UInt64) {
        super.init(type: 0)
        self.type = self.tlvType
        self.integerValue = value
    }
    
    public init?(block: Tlv.Block) {
        super.init(type: block.type, value: block.value)
        if block.type != self.tlvType {
            return nil
        }
        self.integerValue = Buffer.nonNegativeIntegerFromByteArray(block.value)
    }
    
    public override func wireEncodeValue() -> [UInt8] {
        //XXX: recompute the value anyway...
        //TODO: use dirty bit
        self.value = Buffer.byteArrayFromNonNegativeInteger(self.integerValue)
        return self.value
    }
}

public class StringTlv: Tlv.Block {
    
    var tlvType: UInt64 {
        return 0
    }
    
    var defaultValue: String {
        return "nil"
    }
    
    public override var length: UInt64 {
        return UInt64(count(self.stringValue.utf16))
    }
    
    public var stringValue: String = ""
    
    public init() {
        super.init(type: 0)
        self.type = self.tlvType
        self.stringValue = self.defaultValue
    }
    
    public init?(value: String) {
        super.init(type: 0)
        self.type = self.tlvType
        self.stringValue = value
    }
    
    public init?(block: Tlv.Block) {
        super.init(type: block.type, value: block.value)
        if block.type != self.tlvType {
            return nil
        }
        if let string = Buffer.stringFromByteArray(block.value) {
            self.stringValue = string
        } else {
            return nil
        }
    }
    
    public override func wireEncodeValue() -> [UInt8] {
        //XXX: recompute the value anyway...
        //TODO: use dirty bit
        self.value = Buffer.byteArrayFromString(self.stringValue) ?? []
        return self.value
    }
}