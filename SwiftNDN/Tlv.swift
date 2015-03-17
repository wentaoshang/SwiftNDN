//
//  Tlv.swift
//  Swift-NDN
//
//  Created by Wentao Shang on 2/26/15.
//  Copyright (c) 2015 Wentao Shang. All rights reserved.
//

import Foundation

public class Tlv: Printable {
    
    public enum NDNType: UInt64, Printable {
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
        
        // Control Parameters
        case ControlResponse = 101
        case StatusCode = 102
        case StatusText = 103
        case ControlParameters = 104
        case FaceID = 105
        case Cost = 106
        case Flags = 108
        case ExpirationPeriod = 109
        case LocalControlFeature = 110
        case Origin = 111
        case Uri = 114
        
        case FaceStatus = 128
        case LocalUri = 129
        case FaceScope = 132
        case FacePersistency = 133
        case LinkType = 134
        case NInInterests = 144
        case NInDatas = 145
        case NOutInterests = 146
        case NOutDatas = 147
        case NInBytes = 148
        case NOutBytes = 149
        
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
                case .ControlParameters: return "ControlParameters"
                case .FaceID: return "FaceID"
                case .LocalControlFeature: return "LocalControlFeature"
                case .Origin: return "Origin"
                case .Cost: return "Cost"
                case .Flags: return "Flags"
                case .ExpirationPeriod: return "ExpirationPeriod"
                case .ControlResponse: return "ControlResponse"
                case .StatusCode: return "StatusCode"
                case .StatusText: return "StatusText"
                case .Uri: return "Uri"
                case .FaceStatus: return "FaceStatus"
                case .LocalUri: return "LocalUri"
                case .FaceScope: return "FaceScope"
                case .FacePersistency: return "FacePersistency"
                case .LinkType: return "LinkType"
                case .NInInterests: return "NInInterests"
                case .NInDatas: return "NInDatas"
                case .NOutInterests: return "NOutInterests"
                case .NOutDatas: return "NOutDatas"
                case .NInBytes: return "NInBytes"
                case .NOutBytes: return "NOutBytes"
                }
            }
        }
        
        func isNested() -> Bool {
            switch self {
            case .Interest: return true
            case .Data: return true
            case .Name: return true
            case .Selectors: return true
            case .Exclude: return true
            case .MetaInfo: return true
            case .SignatureInfo: return true
            case .FinalBlockId: return true
            case .KeyLocator: return true
            case .ControlParameters: return true
            case .ControlResponse: return true
            case .FaceStatus: return true
            default: return false
            }
        }
    }
    
    public class TypeCode: Printable {
        public let code: UInt64
        public let isNested: Bool
        
        public init(type: NDNType) {
            self.code = type.rawValue
            self.isNested = type.isNested()
        }
        
        public init(code: UInt64) {
            if let ndnType = NDNType(rawValue: code) {
                self.code = ndnType.rawValue
                self.isNested = ndnType.isNested()
            } else {
                self.code = code
                self.isNested = false
            }
        }
        
        public var description: String {
            if let ndnType = NDNType(rawValue: self.code) {
                return ndnType.description
            } else {
                return "Type(code: \(self.code), nested: \(self.isNested))"
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
                        //let l = blk.length
                        //totalLength += l + Buffer.getVarNumberEncodedLength(l)
                        //    + Buffer.getVarNumberEncodedLength(blk.type.rawValue)
                        totalLength += blk.tlvLength
                    }
                    return totalLength
                }
            }
        }
        
        var tlvLength: Length {
            let l = self.length
            return l + Buffer.getVarNumberEncodedLength(l)
                + Buffer.getVarNumberEncodedLength(self.type.code)
        }
        
        public init(type: TypeCode) {
            self.type = type
            if self.type.isNested {
                self.value = Value.Blocks([Block]())
            } else {
                self.value = Value.RawBytes([UInt8]())
            }
        }
        
        public convenience init(type: NDNType) {
            self.init(type: TypeCode(code: type.rawValue))
        }
        
        public init(type: TypeCode, bytes: [UInt8]) {
            self.type = type
            self.value = Value.RawBytes(bytes)
        }
        
        public convenience init(type: NDNType, bytes: [UInt8]) {
            self.init(type: TypeCode(code: type.rawValue), bytes: bytes)
        }
        
        public init(type: TypeCode, blocks: [Block]) {
            self.type = type
            self.value = Value.Blocks(blocks)
        }
        
        public convenience init(type: NDNType, blocks: [Block]) {
            self.init(type: TypeCode(code: type.rawValue), blocks: blocks)
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
                + Buffer.getVarNumberEncodedLength(self.type.code)
            var buf = Buffer(capacity: Int(totalLength))
            self.wireEncode(buf)
            return buf.buffer
        }
        
        public func wireEncode(buf: Buffer) {
            let len = self.length
            buf.writeVarNumber(self.type.code).writeVarNumber(len)
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
                // Then, read TLV length
                if let (len, lenLength) = buf.readVarNumber() {
                    lengthRead += lenLength
                    // Check type code
                    let typeCode = TypeCode(code: typeNumber)
                    if typeCode.isNested {
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
    if lhs.type.code != rhs.type.code {
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

public func == (lhs: Tlv.TypeCode, rhs: Tlv.TypeCode) -> Bool {
    return lhs.code == rhs.code
}

public func != (lhs: Tlv.TypeCode, rhs: Tlv.TypeCode) -> Bool {
    return lhs.code != rhs.code
}

public func == (lhs: Tlv.TypeCode, rhs: Tlv.NDNType) -> Bool {
    return lhs.code == rhs.rawValue
}

public func != (lhs: Tlv.TypeCode, rhs: Tlv.NDNType) -> Bool {
    return lhs.code != rhs.rawValue
}

public class NonNegativeIntegerTlv: Tlv {
    
    var tlvType: TypeCode {
        return TypeCode(code: 0)
    }
    
    var defaultValue: UInt64 {
        return 0
    }
    
    public var value: UInt64 = 0
    
    public override init() {
        super.init()
        self.value = self.defaultValue
    }
    
    public init(value: UInt64) {
        self.value = value
    }
    
    public init?(block: Block) {
        super.init()
        if block.type != self.tlvType {
            return nil
        }
        switch block.value {
        case .RawBytes(let bytes):
            self.value = Buffer.nonNegativeIntegerFromByteArray(bytes)
        default: return nil
        }
    }
    
    public override var block: Block? {
        let bytes = Buffer.byteArrayFromNonNegativeInteger(value)
        return Block(type: self.tlvType, bytes: bytes)
    }
}

public class StringTlv: Tlv {
    
    var tlvType: TypeCode {
        return TypeCode(code: 0)
    }
    
    var defaultValue: String {
        return "SwiftNDN"
    }
    
    public var value: String = ""
    
    public override init() {
        super.init()
        self.value = self.defaultValue
    }
    
    public init(value: String) {
        self.value = value
    }
    
    public init?(block: Block) {
        super.init()
        if block.type != self.tlvType {
            return nil
        }
        switch block.value {
        case .RawBytes(let bytes):
            if let str = Buffer.stringFromByteArray(bytes) {
                self.value = str
            } else {
                return nil
            }
        default: return nil
        }
    }
    
    public override var block: Block? {
        if let bytes = Buffer.byteArrayFromString(value) {
            return Block(type: self.tlvType, bytes: bytes)
        } else {
            return nil
        }
    }
}