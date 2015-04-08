//
//  Data.swift
//  SwiftNDN
//
//  Created by Wentao Shang on 3/3/15.
//  Copyright (c) 2015 Wentao Shang. All rights reserved.
//

import Foundation

public class Data: Tlv.Block {
    
    public class MetaInfo: Tlv.Block {
        
        public class ContentType: NonNegativeIntegerTlv {
            
            struct Val {
                static let Blob: UInt64 = 0
                static let Link: UInt64 = 1
                static let Key:  UInt64 = 2
            }
            
            override var tlvType: UInt64 {
                return Tlv.NDNType.ContentType
            }
            
            override var defaultValue: UInt64 {
                return 0
            }
            
        }
        
        public class FreshnessPeriod: NonNegativeIntegerTlv {
            
            override var tlvType: UInt64 {
                return Tlv.NDNType.FreshnessPeriod
            }

        }
        
        public class FinalBlockID: Tlv.Block {
            
            var component = Name.Component(bytes: [0, 0])
            
            public init() {
                super.init(type: Tlv.NDNType.FinalBlockId)
            }
            
            public init(component: Name.Component) {
                super.init(type: Tlv.NDNType.FinalBlockId)
                self.component = component
            }
            
            public init?(block: Tlv.Block) {
                super.init(type: block.type, value: block.value)
                if block.type != Tlv.NDNType.FinalBlockId {
                    return nil
                }
                if let blocks = Tlv.Block.wireDecodeBlockArray(block.value) {
                    if blocks.count != 1 {
                        return nil
                    }
                    if let nc = Name.Component(block: blocks[0]) {
                        self.component = nc
                    } else {
                        return nil
                    }
                }
            }
            
            public override func wireEncode() -> [UInt8] {
                self.value = self.component.wireEncode()
                return super.wireEncode()
            }
            
            public override var length: UInt64 {
                return self.component.totalLength
            }
        }
            
        var contentType: ContentType?
        var freshnessPeriod: FreshnessPeriod?
        var finalBlockID: FinalBlockID?
        
        public init() {
            super.init(type: Tlv.NDNType.MetaInfo)
        }
        
        public init?(block: Tlv.Block) {
            super.init(type: block.type, value: block.value)
            if block.type != Tlv.NDNType.MetaInfo {
                return nil
            }
            if let blocks = Tlv.Block.wireDecodeBlockArray(block.value) {
                //FIXME: enforce order during decoding?
                for blk in blocks {
                    if let ct = ContentType(block: blk) {
                        self.contentType = ct
                    } else if let fp = FreshnessPeriod(block: blk) {
                        self.freshnessPeriod = fp
                    } else if let fbi = FinalBlockID(block: blk) {
                        self.finalBlockID = fbi
                    }
                }
            }
        }
        
        public override func wireEncodeValue() -> [UInt8] {
            var buf = Buffer(capacity: Int(self.length))
            self.contentType?.wireEncode(buf)
            self.freshnessPeriod?.wireEncode(buf)
            self.finalBlockID?.wireEncode(buf)
            self.value = buf.buffer
            return self.value
        }
        
        public override var length: UInt64 {
            var l: UInt64 = 0
            if let ct = self.contentType {
                l += ct.totalLength
            }
            if let fp = self.freshnessPeriod {
                l += fp.totalLength
            }
            if let fbi = self.finalBlockID {
                l += fbi.totalLength
            }
            return l
        }
    }
    
    public class Content: Tlv.Block {
        
        public init() {
            super.init(type: Tlv.NDNType.Content)
        }
        
        public init(value: [UInt8]) {
            super.init(type: Tlv.NDNType.Content, value: value)
        }
        
        public init?(block: Tlv.Block) {
            super.init(type: block.type, value: block.value)
            if block.type != Tlv.NDNType.Content {
                return nil
            }
        }
    }
    
    public class SignatureInfo: Tlv.Block {
        
        public class SignatureType: NonNegativeIntegerTlv {
            
            public struct Val {
                public static let DigestSha256: UInt64 = 0
                public static let SignatureSha256WithRsa: UInt64 = 1
                public static let SignatureSha256WithEcdsa: UInt64 = 3
            }
            
            override var tlvType: UInt64 {
                return Tlv.NDNType.SignatureType
            }
            
            override var defaultValue: UInt64 {
                return Val.SignatureSha256WithRsa
            }
            
        }
        
        public class KeyLocator: Tlv.Block {
            
            var name = Name()
            //TODO: support KeyDigest
            
            public init() {
                super.init(type: Tlv.NDNType.KeyLocator)
            }
            
            public init(name: Name) {
                super.init(type: Tlv.NDNType.KeyLocator)
                self.name = name
            }
            
            public init?(block: Tlv.Block) {
                super.init(type: block.type, value: block.value)
                if block.type != Tlv.NDNType.KeyLocator {
                    return nil
                }
                if let blocks = Tlv.Block.wireDecodeBlockArray(block.value) {
                    if blocks.count != 1 {
                        return nil
                    }
                    if let n = Name(block: blocks[0]) {
                        self.name = n
                    } else {
                        return nil
                    }
                }
            }
            
            public override func wireEncodeValue() -> [UInt8] {
                self.value = self.name.wireEncode()
                return self.value
            }
            
            public override var length: UInt64 {
                return self.name.totalLength
            }
        }
        
        public var signatureType = SignatureType()
        public var keyLocator: KeyLocator?
        
        public init() {
            super.init(type: Tlv.NDNType.SignatureInfo)
        }
        
        public init?(block: Tlv.Block) {
            super.init(type: block.type, value: block.value)
            if block.type != Tlv.NDNType.SignatureInfo {
                return nil
            }
            if let blocks = Tlv.Block.wireDecodeBlockArray(block.value) {
                if blocks.count < 1 {
                    return nil
                }
                if let si = SignatureType(block: blocks[0]) {
                    self.signatureType = si
                } else {
                    return nil
                }
                if blocks.count == 2 {
                    if let kl = KeyLocator(block: blocks[1]) {
                        self.keyLocator = kl
                    }
                }
            }
        }
        
        public override func wireEncodeValue() -> [UInt8] {
            var buf = Buffer(capacity: Int(self.length))
            self.signatureType.wireEncode(buf)
            self.keyLocator?.wireEncode(buf)
            self.value = buf.buffer
            return self.value
        }
        
        public override var length: UInt64 {
            var l: UInt64 = 0
            l += self.signatureType.totalLength
            if let kl = self.keyLocator {
                l += kl.totalLength
            }
            return l
        }
    }
    
    public class SignatureValue: Tlv.Block {
        
        public init() {
            super.init(type: Tlv.NDNType.SignatureValue)
        }
        
        public init(value: [UInt8]) {
            super.init(type: Tlv.NDNType.SignatureValue, value: value)
        }
        
        public init?(block: Tlv.Block) {
            super.init(type: block.type, value: block.value)
            if block.type != Tlv.NDNType.SignatureValue {
                return nil
            }
        }
    }
    
    public var name = Name()
    public var metaInfo = MetaInfo()
    public var content = Content()
    public var signatureInfo = SignatureInfo()
    public var signatureValue = SignatureValue()
    
    public init() {
        super.init(type: Tlv.NDNType.Data)
    }
    
    public init?(block: Tlv.Block) {
        super.init(type: block.type, value: block.value)
        if block.type != Tlv.NDNType.Data {
            return nil
        }
        if let blocks = Tlv.Block.wireDecodeBlockArray(block.value) {
            if blocks.count != 5 {
                return nil
            }
            if let name = Name(block: blocks[0]) {
                self.name = name
            } else {
                return nil
            }
            if let meta = MetaInfo(block: blocks[1]) {
                self.metaInfo = meta
            } else {
                return nil
            }
            if let content = Content(block: blocks[2]) {
                self.content = content
            } else {
                return nil
            }
            if let si = SignatureInfo(block: blocks[3]) {
                self.signatureInfo = si
            } else {
                return nil
            }
            if let sv = SignatureValue(block: blocks[4]) {
                self.signatureValue = sv
            } else {
                return nil
            }
        }
    }
    
    public override func wireEncodeValue() -> [UInt8] {
        var buf = Buffer(capacity: Int(self.length))
        self.name.wireEncode(buf)
        self.metaInfo.wireEncode(buf)
        self.content.wireEncode(buf)
        self.signatureInfo.wireEncode(buf)
        self.signatureValue.wireEncode(buf)
        self.value = buf.buffer
        return self.value
    }
    
    public override var length: UInt64 {
        var l: UInt64 = 0
        l += self.name.totalLength
        l += self.metaInfo.totalLength
        l += self.content.totalLength
        l += self.signatureInfo.totalLength
        l += self.signatureValue.totalLength
        return l
    }
    
    public func setContent(value: [UInt8]) {
        self.content = Content(value: value)
    }
    
    public func getContent() -> [UInt8] {
        return self.content.value
    }
    
    public func setFreshnessPeriod(value: UInt64) {
        self.metaInfo.freshnessPeriod = MetaInfo.FreshnessPeriod(value: value)
    }
    
    public func getFreshnessPeriod() -> UInt64? {
        return self.metaInfo.freshnessPeriod?.integerValue
    }
    
    public func setContentType(value: UInt64) {
        self.metaInfo.contentType = MetaInfo.ContentType(value: value)
    }
    
    public func getContentType() -> UInt64? {
        return self.metaInfo.contentType?.integerValue
    }
    
    public func setFinalBlockID(value: Name.Component) {
        self.metaInfo.finalBlockID = MetaInfo.FinalBlockID(component: value)
    }
    
    public func getFinalBlockID() -> Name.Component? {
        return self.metaInfo.finalBlockID?.component
    }
    
    func setSignature(value: [UInt8]) {
        self.signatureValue = SignatureValue(value: value)
    }
    
    func getSignature() -> [UInt8] {
        return self.signatureValue.value
    }
    
    public func getSignedPortion() -> [UInt8] {
        let nameEncode = self.name.wireEncode()
        let sigInfoEncode = self.signatureInfo.wireEncode()
        let metaEncode = self.metaInfo.wireEncode()
        let contentEncode = self.content.wireEncode()
        return nameEncode + metaEncode + contentEncode + sigInfoEncode
    }
    
    public class func wireDecode(bytes: [UInt8]) -> Data? {
        let (block, _) = Tlv.Block.wireDecodeWithBytes(bytes)
        if let blk = block {
            return Data(block: blk)
        } else {
            return nil
        }
    }
}