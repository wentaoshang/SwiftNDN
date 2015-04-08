//
//  Buffer.swift
//  Swift-NDN
//
//  Created by Wentao Shang on 2/26/15.
//  Copyright (c) 2015 Wentao Shang. All rights reserved.
//

import Foundation

public class Buffer: Printable {
    
    var buffer: [UInt8]
    var head: Int  // only used for decoding
    
    public init() {
        self.buffer = [UInt8]()
        self.head = 0
    }
    
    public init(capacity: Int) {
        self.buffer = [UInt8]()
        self.buffer.reserveCapacity(capacity)
        self.head = 0
    }
    
    public init(buffer: [UInt8]) {
        self.buffer = buffer
        self.head = 0
    }
    
    public var size: Int {
        return self.buffer.count
    }
    
    public func writeByte(byte: UInt8) -> Buffer {
        buffer.append(byte)
        return self
    }
    
    public func writeByteArray(bytes: [UInt8]) -> Buffer {
        for b in bytes {
            writeByte(b)
        }
        return self
    }
    
    public class func getVarNumberEncodedLength(number: UInt64) -> UInt64 {
        switch number {
        case let x where x < 253: return 1
        case let x where x >= 253 && x <= 0xFFFF: return 3
        case let x where x > 0xFFFF && x <= 0xFFFFFFFF: return 5
        case let x where x > 0xFFFFFFFF: return 9
        default: return 0
        }
    }
    
    public func writeVarNumber(number: UInt64) -> Buffer {
        switch number {
        case let x where x < 253:
            return writeByte(UInt8(x & 0xFF))
        case let x where x >= 253 && x <= 0xFFFF:
            var arr = [UInt8]()
            arr.reserveCapacity(3)
            arr.append(253)
            arr.append(UInt8((x >> 8) & 0xFF))
            arr.append(UInt8(x & 0xFF))
            return writeByteArray(arr)
        case let x where x > 0xFFFF && x <= 0xFFFFFFFF:
            var arr = [UInt8]()
            arr.reserveCapacity(5)
            arr.append(254)
            arr.append(UInt8((x >> 24) & 0xFF))
            arr.append(UInt8((x >> 16) & 0xFF))
            arr.append(UInt8((x >> 8) & 0xFF))
            arr.append(UInt8(x & 0xFF))
            return writeByteArray(arr)
        case let x where x > 0xFFFFFFFF:
            var arr = [UInt8]()
            arr.reserveCapacity(9)
            arr.append(255)
            arr.append(UInt8((x >> 56) & 0xFF))
            arr.append(UInt8((x >> 48) & 0xFF))
            arr.append(UInt8((x >> 40) & 0xFF))
            arr.append(UInt8((x >> 32) & 0xFF))
            arr.append(UInt8((x >> 24) & 0xFF))
            arr.append(UInt8((x >> 16) & 0xFF))
            arr.append(UInt8((x >> 8) & 0xFF))
            arr.append(UInt8(x & 0xFF))
            return writeByteArray(arr)
        default: return self
        }
    }
    
    public func peekVarNumber() -> (number: UInt64, length: Int)? {
        if head >= buffer.count {
            return nil
        }
        let len = buffer[head]
        switch len {
        case let x where x < 253:
            return (UInt64(len), 1)
        case 253:
            if head + 2 >= buffer.count {
                return nil
            }
            var number: UInt64 = 0
            for i in 1...2 {
                number = (number << 8) + UInt64(buffer[head + i])
            }
            return (number, 3)
        case 254:
            if head + 4 >= buffer.count {
                return nil
            }
            var number: UInt64 = 0
            for i in 1...4 {
                number = (number << 8) + UInt64(buffer[head + i])
            }
            return (number, 5)
        case 255:
            if head + 8 >= buffer.count {
                return nil
            }
            var number: UInt64 = 0
            for i in 1...8 {
                number = (number << 8) + UInt64(buffer[head + i])
            }
            return (number, 9)
        default: return nil
        }
    }
    
    public func readVarNumber() -> (number: UInt64, length: Int)? {
        if let result = peekVarNumber() {
            head += result.length
            return result
        }
        return nil
    }
    
    public class func getNonNegativeIntegerEncodedLength(number: UInt64) -> UInt64 {
        switch number {
        case let x where x <= 0xFF: return 1
        case let x where x > 0xFF && x <= 0xFFFF: return 2
        case let x where x > 0xFFFF && x <= 0xFFFFFFFF: return 4
        case let x where x > 0xFFFFFFFF: return 8
        default: return 0
        }
    }
    
    public class func byteArrayFromNonNegativeInteger(number: UInt64) -> [UInt8] {
        switch number {
        case let x where x <= 0xFF:
            var arr = [UInt8]()
            arr.append(UInt8(x & 0xFF))
            return arr
        case let x where x > 0xFF && x <= 0xFFFF:
            var arr = [UInt8]()
            arr.reserveCapacity(2)
            arr.append(UInt8((x >> 8) & 0xFF))
            arr.append(UInt8(x & 0xFF))
            return arr
        case let x where x > 0xFFFF && x <= 0xFFFFFFFF:
            var arr = [UInt8]()
            arr.reserveCapacity(4)
            arr.append(UInt8((x >> 24) & 0xFF))
            arr.append(UInt8((x >> 16) & 0xFF))
            arr.append(UInt8((x >> 8) & 0xFF))
            arr.append(UInt8(x & 0xFF))
            return arr
        case let x where x > 0xFFFFFFFF:
            var arr = [UInt8]()
            arr.reserveCapacity(8)
            arr.append(UInt8((x >> 56) & 0xFF))
            arr.append(UInt8((x >> 48) & 0xFF))
            arr.append(UInt8((x >> 40) & 0xFF))
            arr.append(UInt8((x >> 32) & 0xFF))
            arr.append(UInt8((x >> 24) & 0xFF))
            arr.append(UInt8((x >> 16) & 0xFF))
            arr.append(UInt8((x >> 8) & 0xFF))
            arr.append(UInt8(x & 0xFF))
            return arr
        default: return [UInt8]()
        }
    }
    
    public class func nonNegativeIntegerFromByteArray(bytes: [UInt8]) -> UInt64 {
        var number: UInt64 = 0
        for b in bytes {
            number = (number << 8) + UInt64(b)
        }
        return number
    }

    public class func byteArrayFromString(string: String) -> [UInt8]? {
        if let data = (string as NSString).dataUsingEncoding(NSASCIIStringEncoding) {
            var arr = [UInt8](count: data.length, repeatedValue: 0)
            data.getBytes(&arr, length: data.length)
            return arr
        } else {
            return nil
        }
    }
    
    public class func stringFromByteArray(bytes: [UInt8]) -> String? {
        let data = NSData(bytes: bytes, length: bytes.count)
        if let string = NSString(data: data, encoding: NSASCIIStringEncoding) {
            return string as String
        } else {
            return nil
        }
    }
    
    public func readByteArray(length: Int) -> (array: [UInt8], length: Int)? {
        if head + length > buffer.count {
            return nil
        }
        var arr = [UInt8]()
        arr.reserveCapacity(length)
        for i in 0..<length {
            arr.append(buffer[head + i])
        }
        head += length
        return (arr, length)
    }
    
    public var description: String {
        get {
            return "Buffer: \(buffer), head at \(head)"
        }
    }
}

public func == (lhs: Buffer, rhs: Buffer) -> Bool {
    return lhs.buffer == rhs.buffer
}

public func === (lhs: Buffer, rhs: Buffer) -> Bool {
    return lhs.buffer == rhs.buffer && lhs.head == rhs.head
}

public func == (lhs: Buffer, rhs: [UInt8]) -> Bool {
    return lhs.buffer == rhs
}