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
        let arr1 = Buffer.nonNegativeIntegerToByteArray(0x01)
        let expected1: [UInt8] = [1]
        XCTAssert(arr1 == expected1)
        let arr2 = Buffer.nonNegativeIntegerToByteArray(0x0102)
        let expected2: [UInt8] = [1,2]
        XCTAssert(arr2 == expected2)
        let arr3 = Buffer.nonNegativeIntegerToByteArray(0x01020304)
        let expected3: [UInt8] = [1,2,3,4]
        XCTAssert(arr3 == expected3)
        let arr4 = Buffer.nonNegativeIntegerToByteArray(0x0102030405060708)
        let expected4: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]
        XCTAssert(arr4 == expected4)
        
        XCTAssert(Buffer.byteArrayToNonNegativeInteger(arr1) == 0x01)
        XCTAssert(Buffer.byteArrayToNonNegativeInteger(arr2) == 0x0102)
        XCTAssert(Buffer.byteArrayToNonNegativeInteger(arr3) == 0x01020304)
        XCTAssert(Buffer.byteArrayToNonNegativeInteger(arr4) == 0x0102030405060708)
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
        
        let _a_b_c = Name(url: "/a/b/c")!
        XCTAssert(_a.isProperPrefixOf(_a_b))
        XCTAssert(_a_b.isProperPrefixOf(_a_b_c))
        XCTAssert(_a.isProperPrefixOf(_a_b_c))
        XCTAssert(!_a_b.isProperPrefixOf(_a_a_a))
        
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
    
    func testExclude() {
        let f0: [[UInt8]] = [[0x03], []]
        let ex0 = Interest.Selectors.Exclude(filter: f0)
        XCTAssert(!ex0.matchesComponent(Name.Component(bytes: [0x02])))
        XCTAssert(ex0.matchesComponent(Name.Component(bytes: [0x03])))
        XCTAssert(ex0.matchesComponent(Name.Component(bytes: [0x04])))
        
        let f1: [[UInt8]] = [[], [0x03]]
        let ex1 = Interest.Selectors.Exclude(filter: f1)
        XCTAssert(ex1.matchesComponent(Name.Component(bytes: [0x02])))
        XCTAssert(ex1.matchesComponent(Name.Component(bytes: [0x03])))
        XCTAssert(!ex1.matchesComponent(Name.Component(bytes: [0x04])))
        
        let f2: [[UInt8]] = [[0x01], [], [], [0x03]]
        let ex2 = Interest.Selectors.Exclude(filter: f2)
        XCTAssert(!ex2.matchesComponent(Name.Component(bytes: [0x00])))
        XCTAssert(ex2.matchesComponent(Name.Component(bytes: [0x01])))
        XCTAssert(ex2.matchesComponent(Name.Component(bytes: [0x02])))
        XCTAssert(ex2.matchesComponent(Name.Component(bytes: [0x03])))
        XCTAssert(!ex2.matchesComponent(Name.Component(bytes: [0x04])))

        
        let f3: [[UInt8]] = [[], [0x01], [], [], [0x03], [0x05], []]
        let ex3 = Interest.Selectors.Exclude(filter: f3)
        XCTAssert(ex3.matchesComponent(Name.Component(bytes: [0x00])))
        XCTAssert(ex3.matchesComponent(Name.Component(bytes: [0x01])))
        XCTAssert(ex3.matchesComponent(Name.Component(bytes: [0x02])))
        XCTAssert(ex3.matchesComponent(Name.Component(bytes: [0x03])))
        XCTAssert(!ex3.matchesComponent(Name.Component(bytes: [0x04])))
        XCTAssert(ex3.matchesComponent(Name.Component(bytes: [0x05])))
        XCTAssert(ex3.matchesComponent(Name.Component(bytes: [0x06])))

        let f4: [[UInt8]] = [[0x01], [0x02], [0x03]]
        let ex4 = Interest.Selectors.Exclude(filter: f4)
        XCTAssert(!ex4.matchesComponent(Name.Component(bytes: [0x00])))
        XCTAssert(ex4.matchesComponent(Name.Component(bytes: [0x01])))
        XCTAssert(ex4.matchesComponent(Name.Component(bytes: [0x02])))
        XCTAssert(ex4.matchesComponent(Name.Component(bytes: [0x03])))
        XCTAssert(!ex4.matchesComponent(Name.Component(bytes: [0x04])))
        
        let f5: [[UInt8]] = [[], [0x01], [0x03], [0x05], [], [0x07], [0x09]]
        let ex5 = Interest.Selectors.Exclude(filter: f5)
        XCTAssert(ex5.matchesComponent(Name.Component(bytes: [0x00])))
        XCTAssert(ex5.matchesComponent(Name.Component(bytes: [0x01])))
        XCTAssert(!ex5.matchesComponent(Name.Component(bytes: [0x02])))
        XCTAssert(ex5.matchesComponent(Name.Component(bytes: [0x03])))
        XCTAssert(!ex5.matchesComponent(Name.Component(bytes: [0x04])))
        XCTAssert(ex5.matchesComponent(Name.Component(bytes: [0x05])))
        XCTAssert(ex5.matchesComponent(Name.Component(bytes: [0x06])))
        XCTAssert(ex5.matchesComponent(Name.Component(bytes: [0x07])))
        XCTAssert(!ex5.matchesComponent(Name.Component(bytes: [0x08])))
        XCTAssert(ex5.matchesComponent(Name.Component(bytes: [0x09])))
        XCTAssert(!ex5.matchesComponent(Name.Component(bytes: [0x0A])))
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
    
    func testData() {
        var name = "/a/b/c/d/%00%01"
        var d0 = Data()
        d0.name = Name(url: name)!
        d0.metaInfo.setFreshnessPeriod(40000)
        var content: [UInt8] = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
        d0.setContent(content)
        var d0Encode = d0.wireEncode()
        XCTAssert(d0Encode != nil)
        
        var d1 = Data.wireDecode(d0Encode!)
        XCTAssert(d1 != nil)
        XCTAssert(d1!.name.toUri() == name)
        XCTAssert(d1!.metaInfo.getFreshnessPeriod() == 40000)
        XCTAssert(d1!.getContent() == content)
    }
    
    class TlvEchoClient: AsyncTransportDelegate {
        
        var openExpectation: XCTestExpectation?
        var closeExpectation: XCTestExpectation?
        var receiveName1Expectation: XCTestExpectation?
        var receiveName2Expectation: XCTestExpectation?
        var receiveName3Expectation: XCTestExpectation?
        var receiveName4Expectation: XCTestExpectation?
        var receiveName5Expectation: XCTestExpectation?

        var name1Received = false
        var name2Received = false
        var name3Received = false
        var name4Received = false
        var name5Received = false
        
        var host = "127.0.0.1"
        var port: UInt16 = 12345
        var transport: AsyncTcpTransport!
        
        var name1 = Name(url: "/a/b/c/%00%01")
        var name2 = Name(url: "/ndn/swift/2")
        var name3 = Name(url: "/test/swift/ndn/00")
        var name4 = Name(url: "/1/2/3")
        var name5 = Name(url: "/ok")
        
        init() {
            transport = AsyncTcpTransport(face: self, host: host, port: port)
        }
        
        func onOpen() {
            openExpectation?.fulfill()
        }
        
        func onClose() {
            closeExpectation?.fulfill()
        }
        
        func onError(reason: String) {
            
        }
        
        func onMessage(block: Tlv.Block) {
            if let n = Name(block: block) {
                if n == name1! {
                    name1Received = true
                    receiveName1Expectation?.fulfill()
                } else if n == name2! {
                    name2Received = true
                    receiveName2Expectation?.fulfill()
                } else if n == name3! {
                    name3Received = true
                    receiveName3Expectation?.fulfill()
                } else if n == name4! {
                    name4Received = true
                    receiveName4Expectation?.fulfill()
                } else if n == name5! {
                    name5Received = true
                    receiveName5Expectation?.fulfill()
                }
            }
            
            if name1Received && name2Received && name3Received
                && name4Received && name5Received {
                transport.close()
            }
        }
        
        func run() {
            transport.connect()
            transport.send(name1!.wireEncode()!)
            transport.send(name2!.wireEncode()! + name3!.wireEncode()!)
            let n4Encode = name4!.wireEncode()!
            let half = n4Encode.count / 2
            transport.send([UInt8](n4Encode[0..<half]))
            transport.send([UInt8](n4Encode[half..<n4Encode.count]) + name5!.wireEncode()!)
        }
    }
    
    func testTransport() {
        var server = TlvEchoServer()
        server.start()
        
        var client = TlvEchoClient()
        client.openExpectation = expectationWithDescription("open transport")
        client.receiveName1Expectation = expectationWithDescription("receive name1")
        client.receiveName2Expectation = expectationWithDescription("receive name2")
        client.receiveName3Expectation = expectationWithDescription("receive name3")
        client.receiveName4Expectation = expectationWithDescription("receive name4")
        client.receiveName5Expectation = expectationWithDescription("receive name5")
        client.closeExpectation = expectationWithDescription("close transport")
        client.run()
        
        waitForExpectationsWithTimeout(4, handler: { error in
            if let err = error {
                println("testTransport: \(err.localizedDescription)")
            }
        })
    }
    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measureBlock() {
//            // Put the code you want to measure the time of here.
//        }
//    }
    
}
