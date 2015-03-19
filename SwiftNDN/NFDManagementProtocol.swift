//
//  NFDManagementProtocol.swift
//  SwiftNDN
//
//  Created by Wentao Shang on 3/9/15.
//  Copyright (c) 2015 Wentao Shang. All rights reserved.
//

import Foundation

public struct NFDType {
    // Control Parameters
    public static let ControlResponse: UInt64 = 101
    public static let StatusCode: UInt64 = 102
    public static let StatusText: UInt64 = 103
    public static let ControlParameters: UInt64 = 104
    public static let FaceID: UInt64 = 105
    public static let Cost: UInt64 = 106
    public static let Flags: UInt64 = 108
    public static let ExpirationPeriod: UInt64 = 109
    public static let LocalControlFeature: UInt64 = 110
    public static let Origin: UInt64 = 111
    public static let Uri: UInt64 = 114
    
    // Face Status
    public static let FaceStatus: UInt64 = 128
    public static let LocalUri: UInt64 = 129
    public static let FaceScope: UInt64 = 132
    public static let FacePersistency: UInt64 = 133
    public static let LinkType: UInt64 = 134
    public static let NInInterests: UInt64 = 144
    public static let NInDatas: UInt64 = 145
    public static let NOutInterests: UInt64 = 146
    public static let NOutDatas: UInt64 = 147
    public static let NInBytes: UInt64 = 148
    public static let NOutBytes: UInt64 = 149
    
    // Rib Status
    public static let RibEntry: UInt64 = 128
    public static let Route: UInt64 = 129
    
    // Fib Status
    public static let FibEntry: UInt64 = 128
    public static let NextHopRecord: UInt64 = 129
}

public class FaceID: NonNegativeIntegerTlv {
    override var tlvType: UInt64 {
        return NFDType.FaceID
    }
}

public class LocalControlFeature: NonNegativeIntegerTlv {
    override var tlvType: UInt64 {
        return NFDType.LocalControlFeature
    }
}

public class Origin: NonNegativeIntegerTlv {
    override var tlvType: UInt64 {
        return NFDType.Origin
    }
}

public class Cost: NonNegativeIntegerTlv {
    override var tlvType: UInt64 {
        return NFDType.Cost
    }
}

public class Flags: NonNegativeIntegerTlv {
    override var tlvType: UInt64 {
        return NFDType.Flags
    }
}

public class ExpirationPeriod: NonNegativeIntegerTlv {
    override var tlvType: UInt64 {
        return NFDType.ExpirationPeriod
    }
}

public class ControlParameters: Tlv.Block {
    
    public var name: Name?
    public var faceID: FaceID?
    public var origin: Origin?
    public var cost: Cost?
    public var flags: Flags?
    public var expirePeriod: ExpirationPeriod?
    
    public init() {
        super.init(type: NFDType.ControlParameters)
    }
    
    public init?(block: Tlv.Block) {
        super.init(type: block.type, value: block.value)
        if block.type != NFDType.ControlParameters {
            return nil
        }
        if let blocks = Tlv.Block.wireDecodeBlockArray(block.value) {
            for blk in blocks {
                if let na = Name(block: blk) {
                    self.name = na
                } else if let fi = FaceID(block: blk) {
                    self.faceID = fi
                } else if let og = Origin(block: blk) {
                    self.origin = og
                } else if let co = Cost(block: blk) {
                    self.cost = co
                } else if let fg = Flags(block: blk) {
                    self.flags = fg
                } else if let ep = ExpirationPeriod(block: blk) {
                    self.expirePeriod = ep
                }
            }
        }
    }
    
    public class func wireDecode(bytes: [UInt8]) -> ControlParameters? {
        let (block, _) = Tlv.Block.wireDecodeWithBytes(bytes)
        if let blk = block {
            return ControlParameters(block: blk)
        } else {
            return nil
        }
    }
    
    public override func wireEncodeValue() -> [UInt8] {
        var buf = Buffer(capacity: Int(self.length))
        self.name?.wireEncode(buf)
        self.faceID?.wireEncode(buf)
        self.origin?.wireEncode(buf)
        self.cost?.wireEncode(buf)
        self.flags?.wireEncode(buf)
        self.expirePeriod?.wireEncode(buf)
        self.value = buf.buffer
        return self.value
    }
    
    public override var length: UInt64 {
        var l: UInt64 = 0
        if let na = self.name {
            l += na.totalLength
        } else if let fi = self.faceID {
            l += fi.totalLength
        } else if let og = self.origin {
            l += og.totalLength
        } else if let co = self.cost {
            l += co.totalLength
        } else if let fg = self.flags {
            l += fg.totalLength
        } else if let ep = self.expirePeriod {
            l += ep.totalLength
        }
        return l
    }
}

public class StatusCode: NonNegativeIntegerTlv {
    override var tlvType: UInt64 {
        return NFDType.StatusCode
    }
}

public class StatusText: StringTlv {
    override var tlvType: UInt64 {
        return NFDType.StatusText
    }
}

public class ControlResponse: Tlv.Block {
    
    public var statusCode = StatusCode()
    public var statusText = StatusText()
    
    public init() {
        super.init(type: NFDType.ControlResponse)
    }
    
    public init?(block: Tlv.Block) {
        super.init(type: block.type, value: block.value)
        if block.type != NFDType.ControlResponse {
            return nil
        }
        if let blocks = Tlv.Block.wireDecodeBlockArray(block.value) {
            var hasCode = false
            var hasText = false
            for blk in blocks {
                if let sc = StatusCode(block: blk) {
                    self.statusCode = sc
                    hasCode = true
                } else if let st = StatusText(block: blk) {
                    self.statusText = st
                    hasText = true
                }
            }
            if !hasCode || !hasText {
                return nil
            }
        }
    }
    
    public class func wireDecode(bytes: [UInt8]) -> ControlResponse? {
        let (block, _) = Tlv.Block.wireDecodeWithBytes(bytes)
        if let blk = block {
            return ControlResponse(block: blk)
        } else {
            return nil
        }
    }
    
    public override func wireEncodeValue() -> [UInt8] {
        var buf = Buffer(capacity: Int(self.length))
        self.statusCode.wireEncode(buf)
        self.statusText.wireEncode(buf)
        self.value = buf.buffer
        return self.value
    }
    
    public override var length: UInt64 {
        var l = self.statusCode.totalLength
        l += self.statusText.totalLength
        return l
    }
}

public class ControlCommand: SignedInterest {
    
    public var module: Name.Component!
    public var verb: Name.Component!
    public var parameters: ControlParameters!
    
    public init(prefix: Name, module: Name.Component, verb: Name.Component, param: ControlParameters)
    {
        self.module = module
        self.verb = verb
        self.parameters = param
        let par = param.wireEncode()
        let p = Name(name: prefix).appendComponent(module)
            .appendComponent(verb).appendComponent(par)
        super.init(prefix: p)
    }
    
    public override init?(block: Tlv.Block) {
        super.init(block: block)
        if self.name.size < 7 {
            // Control Command name should have at least 7 components
            return nil
        }
        let paramEncode = self.name.getComponentByIndex(-5)!.value
        if let param = ControlParameters.wireDecode(paramEncode) {
            self.parameters = param
        } else {
            return nil
        }
        self.module = self.name.getComponentByIndex(-7)!
        self.verb = self.name.getComponentByIndex(-2)!
        //FIXME: parse SignatureInfo and SignatureValue
        //self.name = self.name.getPrefix(self.name.size - 3)
    }
    
    public override var prefix: Name {
        return self.name.getPrefix(self.name.size - 7)
    }
}

public class Uri: StringTlv {
    override var tlvType: UInt64 {
        return NFDType.Uri
    }
    
    override var defaultValue: String {
        return "/"
    }
}

public class LocalUri: StringTlv {
    override var tlvType: UInt64 {
        return NFDType.LocalUri
    }
    
    override var defaultValue: String {
        return "/"
    }
}

public class FaceScope: NonNegativeIntegerTlv {
    override var tlvType: UInt64 {
        return NFDType.FaceScope
    }
    
    public struct Val {
        public static let NonLocal: UInt64 = 0
        public static let Local: UInt64 = 1
    }
    
    override var defaultValue: UInt64 {
        return Val.NonLocal
    }
}

public class FacePersistency: NonNegativeIntegerTlv {
    override var tlvType: UInt64 {
        return NFDType.FacePersistency
    }
    
    public struct Val {
        public static let Persistent: UInt64 = 0
        public static let OnDemand: UInt64 = 1
        public static let Permanent: UInt64 = 2
    }
    
    override var defaultValue: UInt64 {
        return Val.Permanent
    }
}

public class LinkType: NonNegativeIntegerTlv {
    override var tlvType: UInt64 {
        return NFDType.LinkType
    }
    
    public struct Val {
        public static let Point2Point: UInt64 = 0
        public static let MultiAccess: UInt64 = 1
    }
    
    override var defaultValue: UInt64 {
        return Val.Point2Point
    }
}

public class NInInterests: NonNegativeIntegerTlv {
    override var tlvType: UInt64 {
        return NFDType.NInInterests
    }
}

public class NInDatas: NonNegativeIntegerTlv {
    override var tlvType: UInt64 {
        return NFDType.NInDatas
    }
}

public class NOutInterests: NonNegativeIntegerTlv {
    override var tlvType: UInt64 {
        return NFDType.NOutInterests
    }
}

public class NOutDatas: NonNegativeIntegerTlv {
    override var tlvType: UInt64 {
        return NFDType.NOutDatas
    }
}

public class NInBytes: NonNegativeIntegerTlv {
    override var tlvType: UInt64 {
        return NFDType.NInBytes
    }
}

public class NOutBytes: NonNegativeIntegerTlv {
    override var tlvType: UInt64 {
        return NFDType.NOutBytes
    }
}

public class FaceStatus: Tlv.Block {
    
    public var faceID = FaceID()
    public var uri = Uri()
    public var localUri = LocalUri()
    public var expirePeriod: ExpirationPeriod?
    public var faceScope = FaceScope()
    public var facePersistency = FacePersistency()
    public var linkType = LinkType()
    public var nInInterests = NInInterests()
    public var nInDatas = NInDatas()
    public var nOutInterests = NOutInterests()
    public var nOutDatas = NOutDatas()
    public var nInBytes = NInBytes()
    public var nOutBytes = NOutBytes()
    
    public init() {
        super.init(type: NFDType.FaceStatus)
    }
    
    public init?(block: Tlv.Block) {
        super.init(type: block.type, value: block.value)
        if block.type != NFDType.FaceStatus {
            return nil
        }
        if let blocks = Tlv.Block.wireDecodeBlockArray(block.value) {
            //TODO: check for completeness
            for blk in blocks {
                if let fi = FaceID(block: blk) {
                    self.faceID = fi
                } else if let uri = Uri(block: blk) {
                    self.uri = uri
                } else if let lu = LocalUri(block: blk) {
                    self.localUri = lu
                } else if let ep = ExpirationPeriod(block: blk) {
                    self.expirePeriod = ep
                } else if let fs = FaceScope(block: blk) {
                    self.faceScope = fs
                } else if let fp = FacePersistency(block: blk) {
                    self.facePersistency = fp
                } else if let lt = LinkType(block: blk) {
                    self.linkType = lt
                } else if let nii = NInInterests(block: blk) {
                    self.nInInterests = nii
                } else if let nid = NInDatas(block: blk) {
                    self.nInDatas = nid
                } else if let noi = NOutInterests(block: blk) {
                    self.nOutInterests = noi
                } else if let nod = NOutDatas(block: blk) {
                    self.nOutDatas = nod
                } else if let nib = NInBytes(block: blk) {
                    self.nInBytes = nib
                } else if let nob = NOutBytes(block: blk) {
                    self.nOutBytes = nob
                }
            }
        }
    }
    
    public override func wireEncodeValue() -> [UInt8] {
        var buf = Buffer(capacity: Int(self.length))
        self.faceID.wireEncode(buf)
        self.uri.wireEncode(buf)
        self.localUri.wireEncode(buf)
        self.expirePeriod?.wireEncode(buf)
        self.faceScope.wireEncode(buf)
        self.facePersistency.wireEncode(buf)
        self.linkType.wireEncode(buf)
        self.nInInterests.wireEncode(buf)
        self.nInDatas.wireEncode(buf)
        self.nOutInterests.wireEncode(buf)
        self.nOutDatas.wireEncode(buf)
        self.nInBytes.wireEncode(buf)
        self.nOutBytes.wireEncode(buf)
        self.value = buf.buffer
        return self.value
    }
    
    public override var length: UInt64 {
        var l = self.faceID.totalLength
        l += self.uri.totalLength
        l += self.localUri.totalLength
        if let ep = self.expirePeriod {
            l += ep.totalLength
        }
        l += self.faceScope.totalLength
        l += self.facePersistency.totalLength
        l += self.linkType.totalLength
        l += self.nInInterests.totalLength
        l += self.nInDatas.totalLength
        l += self.nOutInterests.totalLength
        l += self.nOutDatas.totalLength
        l += self.nInBytes.totalLength
        l += self.nOutBytes.totalLength
        return l
    }
    
    public class func parseFaceStatusDataset(bytes: [UInt8]) -> [FaceStatus] {
        var ret = [FaceStatus]()
        if let blocks = Tlv.Block.wireDecodeBlockArray(bytes) {
            for blk in blocks {
                if let fs = FaceStatus(block: blk) {
                    ret.append(fs)
                } else {
                    break
                }
            }
        }
        return ret
    }
}

public class Route: Tlv.Block {
    
    public var faceID = FaceID()
    public var origin = Origin()
    public var cost = Cost()
    public var flags = Flags()
    public var expirePeriod: ExpirationPeriod?
    
    public init() {
        super.init(type: NFDType.Route)
    }
    
    public init?(block: Tlv.Block) {
        super.init(type: block.type, value: block.value)
        if block.type != NFDType.Route {
            return nil
        }
        if let blocks = Tlv.Block.wireDecodeBlockArray(block.value) {
            for blk in blocks {
                if let fi = FaceID(block: blk) {
                    self.faceID = fi
                } else if let og = Origin(block: blk) {
                    self.origin = og
                } else if let co = Cost(block: blk) {
                    self.cost = co
                } else if let fg = Flags(block: blk) {
                    self.flags = fg
                } else if let ep = ExpirationPeriod(block: blk) {
                    self.expirePeriod = ep
                }
            }
        }
    }
    
    public override func wireEncodeValue() -> [UInt8] {
        var buf = Buffer(capacity: Int(self.length))
        self.faceID.wireEncode(buf)
        self.origin.wireEncode(buf)
        self.cost.wireEncode(buf)
        self.flags.wireEncode(buf)
        self.expirePeriod?.wireEncode(buf)
        self.value = buf.buffer
        return self.value
    }
    
    public override var length: UInt64 {
        var l: UInt64 = 0
        l += self.faceID.totalLength
        l += self.origin.totalLength
        l += self.cost.totalLength
        l += self.flags.totalLength
        if let ep = self.expirePeriod {
            l += ep.totalLength
        }
        return l
    }
}

public class RibEntry: Tlv.Block {
    public var name = Name()
    public var routes = [Route]()
    
    public init() {
        super.init(type: NFDType.RibEntry)
    }
    
    public init?(block: Tlv.Block) {
        super.init(type: block.type, value: block.value)
        if block.type != NFDType.RibEntry {
            return nil
        }
        if let blocks = Tlv.Block.wireDecodeBlockArray(block.value) {
            if blocks.count < 2 {
                return nil
            }
            if let na = Name(block: blocks[0]) {
                self.name = na
            } else {
                return nil
            }
            var rts = [Route]()
            for i in 1 ..< blocks.count {
                if let rt = Route(block: blocks[i]) {
                    rts.append(rt)
                }
                // Ignore unexpected TLVs
            }
            self.routes = rts
        }
    }
    
    public override func wireEncodeValue() -> [UInt8] {
        var buf = Buffer(capacity: Int(self.length))
        self.name.wireEncode(buf)
        for rt in routes {
            rt.wireEncode(buf)
        }
        self.value = buf.buffer
        return self.value
    }
    
    public override var length: UInt64 {
        var l: UInt64 = 0
        l += self.name.totalLength
        for rt in routes {
            l += rt.totalLength
        }
        return l
    }
    
    public class func parseRIBDataset(bytes: [UInt8]) -> [RibEntry] {
        var ret = [RibEntry]()
        if let blocks = Tlv.Block.wireDecodeBlockArray(bytes) {
            for blk in blocks {
                if let re = RibEntry(block: blk) {
                    ret.append(re)
                } else {
                    break
                }
            }
        }
        return ret
    }
}

public class NextHopRecord: Tlv.Block {
    
    public var faceID = FaceID()
    public var cost = Cost()
    
    public init() {
        super.init(type: NFDType.NextHopRecord)
    }
    
    public init?(block: Tlv.Block) {
        super.init(type: block.type, value: block.value)
        if block.type != NFDType.NextHopRecord {
            return nil
        }
        if let blocks = Tlv.Block.wireDecodeBlockArray(block.value) {
            for blk in blocks {
                if let fi = FaceID(block: blk) {
                    self.faceID = fi
                } else if let co = Cost(block: blk) {
                    self.cost = co
                }
            }
        }
    }
    
    public override func wireEncodeValue() -> [UInt8] {
        var buf = Buffer(capacity: Int(self.length))
        self.faceID.wireEncode(buf)
        self.cost.wireEncode(buf)
        self.value = buf.buffer
        return self.value
    }
    
    public override var length: UInt64 {
        var l: UInt64 = 0
        l += self.faceID.totalLength
        l += self.cost.totalLength
        return l
    }
}

public class FibEntry: Tlv.Block {
    public var name = Name()
    public var nexthops = [NextHopRecord]()
    
    public init() {
        super.init(type: NFDType.FibEntry)
    }
    
    public init?(block: Tlv.Block) {
        super.init(type: block.type, value: block.value)
        if block.type != NFDType.FibEntry {
            return nil
        }
        if let blocks = Tlv.Block.wireDecodeBlockArray(block.value) {
            if blocks.count < 2 {
                return nil
            }
            if let na = Name(block: blocks[0]) {
                self.name = na
            } else {
                return nil
            }
            var nhs = [NextHopRecord]()
            for i in 1 ..< blocks.count {
                if let nh = NextHopRecord(block: blocks[i]) {
                    nhs.append(nh)
                }
                // Ignore unexpected TLVs
            }
            self.nexthops = nhs
        }
    }
    
    public override func wireEncodeValue() -> [UInt8] {
        var buf = Buffer(capacity: Int(self.length))
        self.name.wireEncode(buf)
        for nh in self.nexthops {
            nh.wireEncode(buf)
        }
        self.value = buf.buffer
        return self.value
    }
    
    public override var length: UInt64 {
        var l: UInt64 = 0
        l += self.name.totalLength
        for nh in self.nexthops {
            l += nh.totalLength
        }
        return l
    }
    
    public class func parseFIBDataset(bytes: [UInt8]) -> [FibEntry] {
        var ret = [FibEntry]()
        if let blocks = Tlv.Block.wireDecodeBlockArray(bytes) {
            for blk in blocks {
                if let fe = FibEntry(block: blk) {
                    ret.append(fe)
                } else {
                    break
                }
            }
        }
        return ret
    }
}

