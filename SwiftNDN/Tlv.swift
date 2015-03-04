//
//  Tlv.swift
//  Swift-NDN
//
//  Created by Wentao Shang on 2/26/15.
//  Copyright (c) 2015 Wentao Shang. All rights reserved.
//

import Foundation

public class Tlv: Printable {
    
    public enum TypeCode: UInt64, Printable {
        case Interest = 5
        case Data = 6
        case Name = 7
        case NameComponent = 8
        case Selectors = 9
        case Nonce = 10
        case Scope = 11
        case InterestLifetime = 12
        case MinSuffixComponent = 13
        case MaxSuffixComponent = 14
        case PublisherPublicKeyLocator = 15
        case Exclude = 16
        case ChildSelector = 17
        case MustBeFresh = 18
        case Any = 19
        case MetaInfo = 20
        case Content = 21
        case SignatureInfo = 22
        case SignatureValue = 23
        case ContentType = 24
        case FreshnessPeriod = 25
        case FinalBlockId = 26
        case SignatureType = 27
        case KeyLocator = 28
        case KeyDigest = 29
        case ImplicitSha256DigestComponent = 32
        
        public var description: String {
            get {
                switch self {
                case .Interest: return "Interest"
                case .Data: return "Data"
                case .Name: return "Name"
                case .NameComponent: return "NameComponent"
                case .Selectors: return "Selectors"
                case .Nonce: return "Nonce"
                case .Scope: return "Scope"
                case .InterestLifetime: return "InterestLifetime"
                case .MinSuffixComponent: return "MinSuffixComponent"
                case .MaxSuffixComponent: return "MaxSuffixComponent"
                case .PublisherPublicKeyLocator: return "PublisherPublicKeyLocator"
                case .Exclude: return "Exclude"
                case .ChildSelector: return "ChildSelector"
                case .MustBeFresh: return "MustBeFresh"
                case .Any: return "Any"
                case .MetaInfo: return "MetaInfo"
                case .Content: return "Content"
                case .SignatureInfo: return "SignatureInfo"
                case .SignatureValue: return "SignatureValue"
                case .ContentType: return "ContentType"
                case .FreshnessPeriod: return "FreshnessPeriod"
                case .FinalBlockId: return "FinalBlockId"
                case .SignatureType: return "SignatureType"
                case .KeyLocator: return "KeyLocator"
                case .KeyDigest: return "KeyDigest"
                case .ImplicitSha256DigestComponent: return "DigestComponent"
                }
            }
        }
        
        func isNested() -> Bool {
            switch self {
            case .Interest: return true
            case .Data: return true
            case .Name: return true
            case .NameComponent: return false
            case .Selectors: return true
            case .Nonce: return false
            case .Scope: return false
            case .InterestLifetime: return false
            case .MinSuffixComponent: return false
            case .MaxSuffixComponent: return false
            case .PublisherPublicKeyLocator: return false
            case .Exclude: return true
            case .ChildSelector: return false
            case .MustBeFresh: return false
            case .Any: return false
            case .MetaInfo: return true
            case .Content: return false
            case .SignatureInfo: return true
            case .SignatureValue: return false
            case .ContentType: return false
            case .FreshnessPeriod: return false
            case .FinalBlockId: return false
            case .SignatureType: return false
            case .KeyLocator: return true
            case .KeyDigest: return false
            case .ImplicitSha256DigestComponent: return false
            }
        }
    }
    
    public typealias Length = UInt64
    
    public enum Value {
        case RawBytes([UInt8])
        case Blocks([Block])
    }
    
    public class Block: Printable {
        
        var type: TypeCode
        var value: Value
        var length: Length {
            get {
                switch self.value {
                case .RawBytes(let bytes): return Length(bytes.count)
                case .Blocks(let blocks):
                    var totalLength: Length = 0
                    for blk in blocks {
                        let l = blk.length
                        totalLength += l + Buffer.getVarNumberEncodedLength(l)
                            + Buffer.getVarNumberEncodedLength(blk.type.rawValue)
                    }
                    return totalLength
                }
            }
        }
        
        public init(type: TypeCode) {
            self.type = type
            if self.type.isNested() {
                self.value = Value.Blocks([Block]())
            } else {
                self.value = Value.RawBytes([UInt8]())
            }
        }
        
        public init(type: TypeCode, bytes: [UInt8]) {
            self.type = type
            self.value = Value.RawBytes(bytes)
        }
        
        public init(type: TypeCode, blocks: [Block]) {
            self.type = type
            self.value = Value.Blocks(blocks)
        }
        
        public var description: String {
            get {
                var str = "Type: \(self.type), Length: \(self.length), Value: "
                switch self.value {
                case .RawBytes(let bytes):
                    str += "\(bytes)\n"
                case .Blocks(let blocks):
                    str += "\n{"
                    for blk in blocks {
                        str += "\(blk)"
                    }
                    str += "}\n"
                }
                return str
            }
        }
        
        public func appendBlock(blk: Block) {
            switch self.value {
            case .RawBytes(_):
                return // Should we signal error?
            case .Blocks(var blocks):
                blocks.append(blk)
                self.value = Tlv.Value.Blocks(blocks)
                return
            }
        }
        
        public func wireEncode() -> [UInt8] {
            let len = self.length
            let totalLength = len + Buffer.getVarNumberEncodedLength(len)
                + Buffer.getVarNumberEncodedLength(self.type.rawValue)
            var buf = Buffer(capacity: Int(totalLength))
            self.wireEncode(buf)
            return buf.buffer
        }
        
        public func wireEncode(buf: Buffer) {
            let len = self.length
            buf.writeVarNumber(self.type.rawValue).writeVarNumber(len)
            switch self.value {
            case .RawBytes(let bytes):
                buf.writeByteArray(bytes)
            case .Blocks(let blocks):
                for blk in blocks {
                    // Encode each block in the same order as they appear in the array
                    blk.wireEncode(buf)
                }
            }
        }
        
        public class func wireDecode(bytes: [UInt8]) -> (block: Block?, lengthRead: Int) {
            let buf = Buffer(buffer: bytes)
            return wireDecode(buf)
        }
        
        public class func wireDecode(buf: Buffer) -> (block: Block?, lengthRead: Int) {
            // First, read TLV type code
            var lengthRead: Int = 0
            if let (typeNumber, typeLength) = buf.readVarNumber() {
                lengthRead += typeLength
                if let typeCode = Tlv.TypeCode(rawValue: typeNumber) {
                    // Then, read TLV length
                    if let (len, lenLength) = buf.readVarNumber() {
                        lengthRead += lenLength
                        if typeCode.isNested() {
                            // Recursive TLV
                            var blocks = [Block]()
                            var remainingLength = len
                            while remainingLength > 0 {
                                let (block, l) = wireDecode(buf)
                                lengthRead += l
                                if let blk = block {
                                    blocks.append(blk)
                                } else {
                                    break
                                }
                                remainingLength -= l
                            }
                            if remainingLength == 0 {
                                // length of this TLV matches the value
                                return (Block(type: typeCode, blocks: blocks), lengthRead)
                            }
                        } else {
                            // Non-recursive TLV
                            if let (bytes, bytesLength) = buf.readByteArray(Int(len)) {
                                lengthRead += bytesLength
                                return (Block(type: typeCode, bytes: bytes), lengthRead)
                            }
                        }
                    }
                }
            }
            return (nil, lengthRead)
        }
        
    }
    
    public var block: Block? {
        return nil
    }
    
    public var description: String {
        if let blk = self.block {
            return blk.description
        } else {
            return "!!Invalid TLV block!!"
        }
    }
    
    public func wireEncode() -> [UInt8]? {
        return self.block?.wireEncode()
    }
}

public func == (lhs: Tlv.Block, rhs: Tlv.Block) -> Bool {
    if lhs.type != rhs.type {
        return false
    }
    
    switch (lhs.value, rhs.value) {
    case (Tlv.Value.RawBytes(let l), Tlv.Value.RawBytes(let r)):
        if l != r {
            return false
        }
    case (Tlv.Value.Blocks(let l), Tlv.Value.Blocks(let r)):
        if l.count != r.count {
            return false
        }
        for i in 0..<l.count {
            if !(l[i] == r[i]) {
                return false
            }
        }
    default: return false
    }
    return true
}

public func == (lhs: Tlv, rhs: Tlv) -> Bool {
    return false
}