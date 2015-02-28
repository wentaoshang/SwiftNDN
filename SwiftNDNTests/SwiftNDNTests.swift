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
        
        let b1Content = b1.readByteArray(b1.size)
        XCTAssert(b1Content != nil)
        XCTAssert(b1Content!.array == expectedContent1)
        XCTAssertEqual(b1Content!.length, expectedContent1.count)
        
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
        // Test for Name & NameComponent
        
        let nameUrl = "/a/b/c/d/%00%01"
        let c0 = Name.Component(bytes: [0x61])
        let c1 = Name.Component(bytes: [0x62])
        let c2 = Name.Component(bytes: [0x63])
        let c3 = Name.Component(bytes: [0x64])
        let c4 = Name.Component(bytes: [0x00, 0x01])
        let n0 = Name()
        n0.appendComponent(c0)
        n0.appendComponent(c1)
        n0.appendComponent(c2)
        n0.appendComponent(c3)
        n0.appendComponent(c4)
        let n0Encode = n0.wireEncode()
        XCTAssert(n0Encode != nil)

        let (n0blk, _) = Tlv.Block.wireDecode(n0Encode!)
        XCTAssert(n0blk != nil)
        let n1 = Name(block: n0blk!)
        XCTAssert(n1 != nil)
        
        //let emptyUrl = NSURL(string: "/")
        //println(emptyUrl?)
        //let url = NSURL(string: "/a/b/c/d/%00%01//e")
        //println(url?)
        //println(url?.absoluteString)
        //println(url?.pathComponents)
        //println(url?.pathComponents?.count)
        
        let n2 = Name(url: nameUrl)
        XCTAssert(n2 != nil)
        let n2Encode = n2!.wireEncode()
        XCTAssert(n2Encode != nil)
        XCTAssert(n0.wireEncode()! == n2Encode!)

    }
    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measureBlock() {
//            // Put the code you want to measure the time of here.
//        }
//    }
    
}
