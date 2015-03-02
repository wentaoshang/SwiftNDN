//
//  SwiftNDNTests.swift
//  SwiftNDNTests
//
//  Created by Wentao Shang on 2/27/15.
//  Copyright (c) 2015 Wentao Shang. All rights reserved.
//

import Cocoa
import XCTest

import SwiftNDN

class SwiftNDNTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBuffer() {
        // Test for var number
        var b1 = Buffer(capacity: 1000)
        b1.writeVarNumber(0x01)
        b1.writeVarNumber(0x0102)
        b1.writeVarNumber(0x01020304)
        b1.writeVarNumber(0x0102030405060708)
        let expectedContent1: [UInt8] = [1, 253, 1, 2, 254, 1, 2, 3, 4, 255, 1, 2, 3, 4, 5, 6, 7, 8]
        XCTAssert(b1 == expectedContent1)
        XCTAssertEqual(b1.size, expectedContent1.count)
        
        var b1b = Buffer(buffer: expectedContent1)
        XCTAssert(b1b === b1)
        XCTAssert(b1b == b1)
        
        let b1Content = b1.readByteArray(b1.size)
        XCTAssert(b1Content != nil)
        XCTAssert(b1Content!.array == expectedContent1)
        XCTAssertEqual(b1Content!.length, expectedContent1.count)
        XCTAssert(!(b1b === b1))
        XCTAssert(b1b == b1)
        
        b1 = Buffer(capacity: 1000)
        b1.writeVarNumber(0x01)
        b1.writeVarNumber(0x0102)
        b1.writeVarNumber(0x01020304)
        b1.writeVarNumber(0x0102030405060708)
        
        let firstNumber = b1.peekVarNumber()
        XCTAssert(firstNumber != nil)
        XCTAssert(firstNumber!.number == 1)
        XCTAssert(firstNumber!.length == 1)
        let firstNumberAgain = b1.readVarNumber()
        XCTAssert(firstNumberAgain != nil)
        XCTAssert(firstNumberAgain!.number == 1)
        XCTAssert(firstNumberAgain!.length == 1)
        
        let secondNumber = b1.readVarNumber()
        XCTAssert(secondNumber != nil)
        XCTAssert(secondNumber!.number == 0x0102)
        XCTAssert(secondNumber!.length == 3)
        
        let thirdNumber = b1.readVarNumber()
        XCTAssert(thirdNumber != nil)
        XCTAssert(thirdNumber!.number == 0x01020304)
        XCTAssert(thirdNumber!.length == 5)
        
        let fourthNumber = b1.readVarNumber()
        XCTAssert(fourthNumber != nil)
        XCTAssert(fourthNumber!.number == 0x0102030405060708)
        XCTAssert(fourthNumber!.length == 9)
        
        let nonExistNumber = b1.readVarNumber()
        XCTAssert(nonExistNumber == nil)
        
        // Test for Non-negative integer
        var b2 = Buffer(capacity: 1000)
        b2.writeNonNegativeInteger(0x01)
        b2.writeNonNegativeInteger(0x0102)
        b2.writeNonNegativeInteger(0x01020304)
        b2.writeNonNegativeInteger(0x0102030405060708)
        let expectedContent2: [UInt8] = [1, 1, 2, 1, 2, 3, 4, 1, 2, 3, 4, 5, 6, 7, 8]
        XCTAssert(b2 == expectedContent2)
        XCTAssertEqual(b2.size, expectedContent2.count)
        
        let b2Content = b2.readByteArray(b2.size)
        XCTAssert(b2Content != nil)
        XCTAssert(b2Content!.array == expectedContent2)
        XCTAssertEqual(b2Content!.length, expectedContent2.count)
        
        b2 = Buffer(capacity: 1000)
        b2.writeNonNegativeInteger(0x01)
        b2.writeNonNegativeInteger(0x0102)
        b2.writeNonNegativeInteger(0x01020304)
        b2.writeNonNegativeInteger(0x0102030405060708)
        
        let firstNonNegative = b2.readNonNegativeInteger(1)
        XCTAssert(firstNonNegative != nil)
        XCTAssert(firstNonNegative!.number == 0x01)
        XCTAssert(firstNonNegative!.length == 1)
        
        let secondNonNegative = b2.readNonNegativeInteger(2)
        XCTAssert(secondNonNegative != nil)
        XCTAssert(secondNonNegative!.number == 0x0102)
        XCTAssert(secondNonNegative!.length == 2)
        
        let thirdNonNegative = b2.readNonNegativeInteger(4)
        XCTAssert(thirdNonNegative != nil)
        XCTAssert(thirdNonNegative!.number == 0x01020304)
        XCTAssert(thirdNonNegative!.length == 4)
        
        let fourthNonNegative = b2.readNonNegativeInteger(8)
        XCTAssert(fourthNonNegative != nil)
        XCTAssert(fourthNonNegative!.number == 0x0102030405060708)
        XCTAssert(fourthNonNegative!.length == 8)
        
        let nonExistNonNegative = b2.readNonNegativeInteger(4)
        XCTAssert(nonExistNonNegative == nil)
    }
    
    func testName() {
        // Test for Name.Component
        
        let c0 = Name.Component(bytes: [0x61])
        XCTAssertEqual(c0.toUri(), "a")
        let c1 = Name.Component(bytes: [0x62])
        let c2 = Name.Component(bytes: [0x63])
        let c3 = Name.Component(bytes: [0x64])
        let c4 = Name.Component(bytes: [0x00, 0x01])
        XCTAssertEqual(c4.toUri(), "%00%01")
        
        let c0s = Name.Component(url: "a")
        XCTAssert(c0s != nil)
        XCTAssert(c0s! == c0)
        
        let c4s = Name.Component(url: "%00%01")
        XCTAssert(c4s != nil)
        XCTAssert(c4s! == c4)
        
        let c5 = Name.Component(url: "")
        XCTAssert(c5 == nil)
        let c6 = Name.Component(url: "/")
        XCTAssert(c6 == nil)
        
        let a = Name.Component(url: "a")
        let ab = Name.Component(url: "ab")
        let aaa = Name.Component(url: "aaa")
        let aac = Name.Component(url: "aac")
        XCTAssert(a! < ab!)
        XCTAssert(ab! < aaa!)
        XCTAssert(aaa! < aac!)
        XCTAssert(aac! > ab!)
        
        // Test for Name
        let nameUrl = "/a/b/c/d/%00%01"
        let n0 = Name()
        n0.appendComponent(c0)
        n0.appendComponent(c1)
        n0.appendComponent(c2)
        n0.appendComponent(c3)
        n0.appendComponent(c4)
        XCTAssertEqual(n0.toUri(), nameUrl)
        
        let n0Encode = n0.wireEncode()
        XCTAssert(n0Encode != nil)
        let (n0blk, _) = Tlv.Block.wireDecode(n0Encode!)
        XCTAssert(n0blk != nil)
        let n1 = Name(block: n0blk!)
        XCTAssert(n1 != nil)
        XCTAssert(n0 == n1!)
        
        let n2 = Name(url: nameUrl)
        XCTAssert(n2 != nil)
        let n2Encode = n2!.wireEncode()
        XCTAssert(n2Encode != nil)
        XCTAssert(n0.wireEncode()! == n2Encode!)
        XCTAssert(n0 == n2!)
        XCTAssert(n1! == n2!)
        
        let _a = Name(url: "/a")!
        let _a_b = Name(url: "/a/b")!
        let _a_a_a = Name(url: "/a/a/a")!
        let _a_a_c = Name(url: "/a/a/c")!
        XCTAssert(_a < _a_b)
        XCTAssert(_a_b > _a_a_a)
        XCTAssert(_a_a_a < _a_a_c)
        
        let emptyName1 = Name()
        XCTAssertEqual(emptyName1.toUri(), "/")
        let emptyEncode = emptyName1.wireEncode()
        XCTAssert(emptyEncode != nil)
        let emptyName2 = Name.wireDecode(emptyEncode!)
        XCTAssert(emptyName2 != nil)
        XCTAssert(emptyName1 == emptyName2!)

        // NSURL usages
//        let url0 = NSURL(string: "%00%01")
//        println(url0?.absoluteString)
//        println(url0?.pathComponents)
//        //println(url0?.lastPathComponent?.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding))
//        let url1 = NSURL(string: "")
//        println(url1?.absoluteString)
//        println(url1?.pathComponents)
//        //println(url1?.lastPathComponent?.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding))
//        let url2 = NSURL(string: "/")
//        println(url2?.absoluteString)
//        println(url2?.pathComponents)
//        let url3 = NSURL(string: "a")
//        println(url3?.absoluteString)
//        println(url3?.pathComponents)
//        let url4 = NSURL(string: "/a/b/c/d/%00%01//e")
//        println(url4?)
//        println(url4?.absoluteString)
//        println(url4?.pathComponents)
//        println(url4?.pathComponents?.count)
    }
    
    func testInterest() {
        var i0 = Interest()
        let i0Encode = i0.wireEncode()
        XCTAssert(i0Encode != nil)
        var i1 = Interest.wireDecode(i0Encode!)
        XCTAssert(i1 != nil)
        XCTAssert(i0.name == i1!.name)
        XCTAssert(i0.nonce == i1!.nonce)
    }
    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measureBlock() {
//            // Put the code you want to measure the time of here.
//        }
//    }
    
}
