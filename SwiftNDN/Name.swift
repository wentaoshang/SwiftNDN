//
//  Name.swift
//  Swift-NDN
//
//  Created by Wentao Shang on 2/26/15.
//  Copyright (c) 2015 Wentao Shang. All rights reserved.
//

import Foundation

public let NDNURIAllowedCharacterSet = NSCharacterSet(charactersInString:
    "ABCDEFGHIGKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+._-")

public class Name: Tlv.Block {
    
    public class Component: Tlv.Block {
        
        public init(bytes: [UInt8]) {
            super.init(type: Tlv.NDNType.NameComponent, value: bytes)
        }
        
        public init?(block: Tlv.Block) {
            super.init(type: block.type, value: block.value)
            if block.type != Tlv.NDNType.NameComponent {
                return nil
            }
        }
        
        public init?(url: String) {
            super.init(type: Tlv.NDNType.NameComponent)
            if let comps = NSURL(string: url)?.pathComponents? {
                if comps.count != 1 {
                    return nil
                }
                let unescaped = comps[0] as NSString
                if unescaped == "/" {
                    return nil
                }
                if let bytes = Buffer.byteArrayFromString(unescaped) {
                    if bytes.count == 0 {
                        return nil
                    } else {
                        self.value = bytes
                    }
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }
        
        public func toUri() -> String {
            var uri = NSString(bytes: self.value, length: self.value.count, encoding: NSASCIIStringEncoding)
            //return (uri?.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet()))!
            return (uri?.stringByAddingPercentEncodingWithAllowedCharacters(NDNURIAllowedCharacterSet))!
        }
        
        // Return -1 if self < target; +1 if self > target; 0 if self == target
        public func compare(target: Component) -> Int {
            if self.value.count < target.value.count {
                return -1
            } else if self.value.count > target.value.count {
                return 1
            } else {
                for i in 0..<self.value.count {
                    if self.value[i] < target.value[i] {
                        return -1
                    }
                    if self.value[i] > target.value[i] {
                        return 1
                    }
                }
                return 0
            }
        }
    }
    
    var components = [Component]()
    
    public var size: Int {
        return self.components.count
    }
    
    public var isEmpty: Bool {
        return self.components.isEmpty
    }
    
    public override init() {
        super.init(type: Tlv.NDNType.Name)
    }
    
    public init(name: Name) {
        super.init(type: Tlv.NDNType.Name)
        // make a copy
        self.components = name.components
    }

    public init?(block: Tlv.Block) {
        super.init(type: block.type, value: block.value)
        if block.type != Tlv.NDNType.Name {
            return nil
        }
        if let blocks = Tlv.Block.wireDecodeBlockArray(block.value) {
            var comps = [Component]()
            for blk in blocks {
                if let c = Component(block: blk) {
                    comps.append(c)
                } else {
                    return nil
                }
            }
            self.components = comps
        } else {
            return nil
        }
    }
    
    public init?(url: String) {
        super.init(type: Tlv.NDNType.Name)
        if let comps = NSURL(string: url)?.pathComponents {
            for i in 1..<comps.count {
                let string = comps[i] as NSString
                if let bytes = Buffer.byteArrayFromString(string) {
                    if bytes.count == 0 {
                        continue // skip empty string
                    } else {
                        self.appendComponent(Component(bytes: bytes))
                    }
                } else {
                    return nil
                }
            }
        } else {
            return nil
        }
    }
    
    public func appendComponent(component: Component) -> Name {
        self.components.append(component)
        return self
    }
    
    public func appendComponent(bytes: [UInt8]) -> Name {
        self.components.append(Component(bytes: bytes))
        return self
    }
    
    public func appendComponent(url: String) -> Name? {
        if let c = Component(url: url) {
            self.components.append(c)
            return self
        } else {
            return nil
        }
    }
    
    public func appendNumber(number: UInt64) -> Name {
        var arr = Buffer.byteArrayFromNonNegativeInteger(number)
        return self.appendComponent(arr)
    }
    
    public func getComponentByIndex(var index: Int) -> Component? {
        if index < 0 {
            index = self.components.count + index
        }
        if index < self.components.count && index >= 0 {
            return self.components[index]
        } else {
            return nil
        }
    }
    
    public func getPrefix(length: Int) -> Name {
        if length >= self.size {
            return Name(name: self)
        } else {
            var prefix = Name()
            prefix.components = [Component](self.components[0..<length])
            return prefix
        }
    }

    public func toUri() -> String {
        if components.count == 0 {
            return "/"
        } else {
            var uri = ""
            for c in components {
                uri += "/\(c.toUri())"
            }
            return uri
        }
    }
    
    // Return -1 if self < target; +1 if self > target; 0 if self == target
    public func compare(target: Name) -> Int {
        let l = min(self.components.count, target.components.count)

        for i in 0..<l {
            if self.components[i] < target.components[i] {
                return -1
            }
            if self.components[i] > target.components[i] {
                return 1
            }
        }
        
        if self.components.count < target.components.count {
            return -1
        } else if self.components.count > target.components.count {
            return 1
        } else {
            return 0
        }
    }
    
    public func isProperPrefixOf(name: Name) -> Bool {
        return self.isPrefixOf(name) && self.size < name.size
    }
    
    public func isPrefixOf(name: Name) -> Bool {
        if name.size < self.size {
            return false
        }
        for i in 0 ..< self.components.count {
            if self.components[i] != name.components[i] {
                return false
            }
        }
        return true
    }
    
    public override func wireEncodeValue() -> [UInt8] {
        var buf = Buffer(capacity: Int(self.length))
        for c in self.components {
            c.wireEncode(buf)
        }
        self.value = buf.buffer
        return self.value
    }
    
    public override var length: UInt64 {
        var l: UInt64 = 0
        for c in self.components {
            l += c.totalLength
        }
        return l
    }
    
    public class func wireDecode(bytes: [UInt8]) -> Name? {
        let (block, _) = Tlv.Block.wireDecodeWithBytes(bytes)
        if let blk = block {
            return Name(block: blk)
        } else {
            return nil
        }
    }
}

public func == (lhs: Name.Component, rhs: Name.Component) -> Bool {
    return lhs.value == rhs.value
}

public func != (lhs: Name.Component, rhs: Name.Component) -> Bool {
    return !(lhs == rhs)
}

public func < (lhs: Name.Component, rhs: Name.Component) -> Bool {
    return lhs.compare(rhs) == -1
}

public func <= (lhs: Name.Component, rhs: Name.Component) -> Bool {
    return !(lhs > rhs)
}

public func > (lhs: Name.Component, rhs: Name.Component) -> Bool {
    return lhs.compare(rhs) == 1
}

public func >= (lhs: Name.Component, rhs: Name.Component) -> Bool {
    return !(lhs < rhs)
}

public func == (lhs: Name, rhs: Name) -> Bool {
    if lhs.components.count != rhs.components.count {
        return false
    }
    
    for i in 0..<lhs.components.count {
        if !(lhs.components[i] == rhs.components[i]) {
            return false
        }
    }
    
    return true
}

public func != (lhs: Name, rhs: Name) -> Bool {
    return !(lhs == rhs)
}

public func < (lhs: Name, rhs: Name) -> Bool {
    return lhs.compare(rhs) == -1
}

public func > (lhs: Name, rhs: Name) -> Bool {
    return lhs.compare(rhs) == 1
}
