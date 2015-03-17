//
//  NFDManagementProtocol.swift
//  SwiftNDN
//
//  Created by Wentao Shang on 3/9/15.
//  Copyright (c) 2015 Wentao Shang. All rights reserved.
//

import Foundation

public class FaceID: NonNegativeIntegerTlv {
    override var tlvType: TypeCode {
        return TypeCode(type: NDNType.FaceID)
    }
}

public class LocalControlFeature: NonNegativeIntegerTlv {
    override var tlvType: TypeCode {
        return TypeCode(type: NDNType.LocalControlFeature)
    }
}

public class Origin: NonNegativeIntegerTlv {
    override var tlvType: TypeCode {
        return TypeCode(type: NDNType.Origin)
    }
}

public class Cost: NonNegativeIntegerTlv {
    override var tlvType: TypeCode {
        return TypeCode(type: NDNType.Cost)
    }
}

public class Flags: NonNegativeIntegerTlv {
    override var tlvType: TypeCode {
        return TypeCode(type: NDNType.Flags)
    }
}

public class ExpirationPeriod: NonNegativeIntegerTlv {
    override var tlvType: TypeCode {
        return TypeCode(type: NDNType.ExpirationPeriod)
    }
}

public class ControlParameters: Tlv {
    
    public var name: Name?
    public var faceID: FaceID?
    public var origin: Origin?
    public var cost: Cost?
    public var flags: Flags?
    public var expirePeriod: ExpirationPeriod?
    
    public override var block: Block? {
        var blk = Block(type: NDNType.ControlParameters)
        if let naBlock = self.name?.block {
            blk.appendBlock(naBlock)
        } else if let fiBlock = self.faceID?.block {
            blk.appendBlock(fiBlock)
        } else if let ogBlock = self.origin?.block {
            blk.appendBlock(ogBlock)
        } else if let coBlock = self.cost?.block {
            blk.appendBlock(coBlock)
        } else if let fgBlock = self.flags?.block {
            blk.appendBlock(fgBlock)
        } else if let epBlock = self.expirePeriod?.block {
            blk.appendBlock(epBlock)
        }
        return blk
    }
    
    public override init() {
        super.init()
    }
    
    public init?(block: Block) {
        super.init()
        if block.type != NDNType.ControlParameters {
            return nil
        }
        switch block.value {
        case .Blocks(let blocks):
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
        default: return nil
        }
    }
    
    public class func wireDecode(bytes: [UInt8]) -> ControlParameters? {
        let (block, _) = Block.wireDecode(bytes)
        if let blk = block {
            return ControlParameters(block: blk)
        } else {
            return nil
        }
    }
}

public class StatusCode: NonNegativeIntegerTlv {
    override var tlvType: TypeCode {
        return TypeCode(type: NDNType.StatusCode)
    }
    
    override var defaultValue: UInt64 {
        return 200
    }
}

public class StatusText: StringTlv {
    override var tlvType: TypeCode {
        return TypeCode(type: NDNType.StatusText)
    }
    
    override var defaultValue: String {
        return "OK"
    }
}

public class ControlResponse: Tlv {
    
    public var statusCode = StatusCode()
    public var statusText = StatusText()
    
    public override var block: Block? {
        var blocks = [Block]()
        if let codeBlock = statusCode.block {
            blocks.append(codeBlock)
        } else {
            return nil
        }
        if let textBlock = statusText.block {
            blocks.append(textBlock)
        } else {
            return nil
        }
        return Block(type: NDNType.ControlResponse, blocks: blocks)
    }
    
    public override init() {
        super.init()
    }
    
    public init?(block: Block) {
        super.init()
        if block.type != NDNType.ControlResponse {
            return nil
        }
        switch block.value {
        case .Blocks(let blocks):
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
        default: return nil
        }
    }
    
    public class func wireDecode(bytes: [UInt8]) -> ControlResponse? {
        let (block, _) = Block.wireDecode(bytes)
        if let blk = block {
            return ControlResponse(block: blk)
        } else {
            return nil
        }
    }
}

public class ControlCommand: SignedInterest {
    
    public var module: String
    public var verb: String
    public var parameters: ControlParameters
    
    public init(prefix: Name, module: String, verb: String, param: ControlParameters)
    {
        self.module = module
        self.verb = verb
        self.parameters = param
        super.init(name: prefix)
    }
    
    public override var fullName: Name? {
        if let sigInfo = signatureInfo.wireEncode() {
            if let sigVal = signatureValue.wireEncode() {
                if let modComp = Name.Component(url: module) {
                    if let verbComp = Name.Component(url: verb) {
                        if let param = parameters.wireEncode() {
                            return Name(name: self.name)
                                .appendComponent(modComp)
                                .appendComponent(verbComp)
                                .appendComponent(param)
                                .appendNumber(timestamp)
                                .appendNumber(randomValue)
                                .appendComponent(sigInfo)
                                .appendComponent(sigVal)
                        }
                    }
                }
            }
        }
        return nil
    }
    
    public override init?(block: Block) {
        self.module = ""
        self.verb = ""
        self.parameters = ControlParameters()
        super.init(block: block)
        if self.name.size < 3 {
            // Control Command name should have at least 3 components
            // (after signed interest components are removed)
            return nil
        }
        let paramEncode = self.name.getComponentByIndex(-1)!.value
        if let param = ControlParameters.wireDecode(paramEncode) {
            self.parameters = param
        } else {
            return nil
        }
        self.module = self.name.getComponentByIndex(-3)!.toUri()
        self.verb = self.name.getComponentByIndex(-2)!.toUri()
        //FIXME: parse SignatureInfo and SignatureValue
        self.name = self.name.getPrefix(self.name.size - 3)
    }
}

public class Uri: StringTlv {
    override var tlvType: TypeCode {
        return TypeCode(type: NDNType.Uri)
    }
    
    override var defaultValue: String {
        return "/"
    }
}

public class LocalUri: StringTlv {
    override var tlvType: TypeCode {
        return TypeCode(type: NDNType.LocalUri)
    }
    
    override var defaultValue: String {
        return "/"
    }
}

public class FaceScope: NonNegativeIntegerTlv {
    override var tlvType: TypeCode {
        return TypeCode(type: NDNType.FaceScope)
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
    override var tlvType: TypeCode {
        return TypeCode(type: NDNType.FacePersistency)
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
    override var tlvType: TypeCode {
        return TypeCode(type: NDNType.LinkType)
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
    override var tlvType: TypeCode {
        return TypeCode(type: NDNType.NInInterests)
    }
}

public class NInDatas: NonNegativeIntegerTlv {
    override var tlvType: TypeCode {
        return TypeCode(type: NDNType.NInDatas)
    }
}

public class NOutInterests: NonNegativeIntegerTlv {
    override var tlvType: TypeCode {
        return TypeCode(type: NDNType.NOutInterests)
    }
}

public class NOutDatas: NonNegativeIntegerTlv {
    override var tlvType: TypeCode {
        return TypeCode(type: NDNType.NOutDatas)
    }
}

public class NInBytes: NonNegativeIntegerTlv {
    override var tlvType: TypeCode {
        return TypeCode(type: NDNType.NInBytes)
    }
}

public class NOutBytes: NonNegativeIntegerTlv {
    override var tlvType: TypeCode {
        return TypeCode(type: NDNType.NOutBytes)
    }
}

public class FaceStatus: Tlv {
    
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
    
    public override var block: Block? {
        var blocks = [Block]()
        if let fib = faceID.block {
            blocks.append(fib)
        } else {
            return nil
        }
        if let ub = uri.block {
            blocks.append(ub)
        } else {
            return nil
        }
        if let lub = localUri.block {
            blocks.append(lub)
        } else {
            return nil
        }
        if let epb = expirePeriod?.block {
            blocks.append(epb)
        }
        if let fsb = faceScope.block {
            blocks.append(fsb)
        } else {
            return nil
        }
        if let fpb = facePersistency.block {
            blocks.append(fpb)
        } else {
            return nil
        }
        if let lb = linkType.block {
            blocks.append(lb)
        } else {
            return nil
        }
        if let niib = nInInterests.block {
            blocks.append(niib)
        } else {
            return nil
        }
        if let nidb = nInDatas.block {
            blocks.append(nidb)
        } else {
            return nil
        }
        if let noib = nOutInterests.block {
            blocks.append(noib)
        } else {
            return nil
        }
        if let nodb = nOutDatas.block {
            blocks.append(nodb)
        } else {
            return nil
        }
        if let nibb = nInBytes.block {
            blocks.append(nibb)
        } else {
            return nil
        }
        if let nobb = nOutBytes.block {
            blocks.append(nobb)
        } else {
            return nil
        }
        return Block(type: NDNType.ControlResponse, blocks: blocks)
    }
    
    public override init() {
        super.init()
    }
    
    public init?(block: Block) {
        super.init()
        if block.type != NDNType.FaceStatus {
            return nil
        }
        switch block.value {
        case .Blocks(let blocks):
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
        default: return nil
        }
    }
    
    public class func parseFaceStatusDataset(bytes: [UInt8]) -> [FaceStatus] {
        var bytesRead: Int = 0
        var ret = [FaceStatus]()
        while bytesRead < bytes.count {
            let (block, lengthRead) = Block.wireDecode([UInt8](bytes[bytesRead..<bytes.count]))
            if let blk = block {
                bytesRead += lengthRead
                if let fs = FaceStatus(block: blk) {
                    ret.append(fs)
                } else {
                    break
                }
            } else {
                break
            }
        }
        return ret
    }
}
