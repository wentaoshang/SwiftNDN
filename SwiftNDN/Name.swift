//
//  Name.swift
//  Swift-NDN
//
//  Created by Wentao Shang on 2/26/15.
//  Copyright (c) 2015 Wentao Shang. All rights reserved.
//

import Foundation

public class Name: Tlv {
    
    public class Component: Tlv {
        
        let value = [UInt8]()
        
        public override var block: Block? {
            return Block(type: TypeCode.NameComponent, bytes: self.value)
        }
        
        public init(bytes: [UInt8]) {
            self.value = bytes
        }
        
        public init?(block: Block) {
            super.init()
            if block.type != TypeCode.NameComponent {
                return nil
            }
            switch block.value {
            case .RawBytes(let bytes):
                self.value = bytes
            default: return nil
            }
        }
        
        public convenience init(str: NSString) {
            let cStr = str.cStringUsingEncoding(NSUTF8StringEncoding)
            let cStrLen = str.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
            var bytes = [UInt8]()
            bytes.reserveCapacity(cStrLen)
            for i in 0..<cStrLen {
                bytes.append(UInt8(cStr[i]))
            }
            self.init(bytes: bytes)
        }
        
    }
    
    var components = [Component]()
    
    public override var block: Block? {
        if components.count == 0 {
            return nil
        } else {
            var blk = Block(type: TypeCode.Name)
            for comp in self.components {
                if let compBlock = comp.block {
                    blk.appendBlock(compBlock)
                } else {
                    return nil
                }
            }
            return blk
        }
    }
    
    public var size: Int {
        return self.components.count
    }
    
    public var isEmpty: Bool {
        return self.components.isEmpty
    }
    
    public override init() {
        super.init()
    }

    public init?(block: Block) {
        super.init()
        if block.type != Tlv.TypeCode.Name {
            return nil
        }
        switch block.value {
        case .Blocks(let blocks):
            var comps = [Component]()
            for blk in blocks {
                if let c = Component(block: blk) {
                    comps.append(c)
                } else {
                    return nil
                }
            }
            self.components = comps
        default: return nil
        }
    }
    
    public init?(url: String) {
        super.init()
        if let comps = NSURL(string: url)?.pathComponents {
            if comps.count <= 1 {
                // Empty URL "/"
                return nil
            }
            for i in 1..<comps.count {
                self.appendComponent(Component(str: (comps[i] as NSString)))
            }
        }
    }
    
    public func appendComponent(component: Component) {
        self.components.append(component)
    }
    
    public func getComponentByIndex(index: Int) -> Component? {
        return self.components[index]
    }

}