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
        case ImplicitSha256DigestComponent = 32
        
        public var description: String {
            get {
                switch self {
                case .Interest: return "Interest"
                case .Data: return "Data"
                case .Name: return "Name"
                case .NameComponent: return "NameComponent"
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
        
        public func wireEncode() -> Buffer? {
            let len = self.length
            if len == 0 {
                return nil
            }
            let totalLength = len + Buffer.getVarNumberEncodedLength(len)
                + Buffer.getVarNumberEncodedLength(self.type.rawValue)
            var buf = Buffer(capacity: Int(totalLength))
            self.wireEncode(buf)
            return buf
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
    
    public func wireEncode() -> Buffer? {
        return self.block?.wireEncode()
    }
}