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
        let arr1 = Buffer.byteArrayFromNonNegativeInteger(0x01)
        let expected1: [UInt8] = [1]
        XCTAssert(arr1 == expected1)
        let arr2 = Buffer.byteArrayFromNonNegativeInteger(0x0102)
        let expected2: [UInt8] = [1,2]
        XCTAssert(arr2 == expected2)
        let arr3 = Buffer.byteArrayFromNonNegativeInteger(0x01020304)
        let expected3: [UInt8] = [1,2,3,4]
        XCTAssert(arr3 == expected3)
        let arr4 = Buffer.byteArrayFromNonNegativeInteger(0x0102030405060708)
        let expected4: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]
        XCTAssert(arr4 == expected4)
        
        XCTAssert(Buffer.nonNegativeIntegerFromByteArray(arr1) == 0x01)
        XCTAssert(Buffer.nonNegativeIntegerFromByteArray(arr2) == 0x0102)
        XCTAssert(Buffer.nonNegativeIntegerFromByteArray(arr3) == 0x01020304)
        XCTAssert(Buffer.nonNegativeIntegerFromByteArray(arr4) == 0x0102030405060708)
        
        // Test for Array-String conversion
        let str = "abcd1234"
        let arr = Buffer.byteArrayFromString(str)
        XCTAssert(arr != nil)
        XCTAssert(arr! == [97, 98, 99, 100, 49, 50, 51, 52])
        let str0 = Buffer.stringFromByteArray(arr!)
        XCTAssert(str0 != nil)
        XCTAssertEqual(str0!, str)
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
        
        let c70 = Name.Component(bytes: [0xFD, 0, 0, 1, 0x2E])
        XCTAssert(c70.toUri() == "%FD%00%00%01.")
        let c71 = Name.Component(url: "%FD%00%00%01.")
        XCTAssert(c71 != nil)
        XCTAssert(c71! == c70)
        
        // Test for Name
        let nameUrl = "/a/b/c/d/%00%01"
        let n0 = Name()
        n0.appendComponent(c0)
        n0.appendComponent(c1)
        n0.appendComponent(c2)
        n0.appendComponent(c3)
        n0.appendComponent(c4)
        XCTAssertEqual(n0.toUri(), nameUrl)
        XCTAssertEqual(n0.getComponentByIndex(0)!.toUri(), "a")
        XCTAssertEqual(n0.getComponentByIndex(1)!.toUri(), "b")
        XCTAssertEqual(n0.getComponentByIndex(2)!.toUri(), "c")
        XCTAssertEqual(n0.getComponentByIndex(3)!.toUri(), "d")
        XCTAssertEqual(n0.getComponentByIndex(4)!.toUri(), "%00%01")
        XCTAssert(n0.getComponentByIndex(5) == nil)
        
        let n00 = Name(url: nameUrl + "/")
        XCTAssert(n00 != nil)
        XCTAssert(n00! == n0)
        XCTAssertEqual(n00!.toUri(), nameUrl)
        
        let n0Encode = n0.wireEncode()
        let (n0blk, _) = Tlv.Block.wireDecodeWithBytes(n0Encode)
        XCTAssert(n0blk != nil)
        let n1 = Name(block: n0blk!)
        XCTAssert(n1 != nil)
        XCTAssert(n0 == n1!)
        
        let n2 = Name(url: nameUrl)
        XCTAssert(n2 != nil)
        let n2Encode = n2!.wireEncode()
        XCTAssert(n0.wireEncode() == n2Encode)
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
        
        XCTAssert(_a_b.isPrefixOf(_a_b))
        XCTAssert(!_a_b.isProperPrefixOf(_a_b))
        
        let emptyName1 = Name()
        XCTAssertEqual(emptyName1.toUri(), "/")
        let emptyEncode = emptyName1.wireEncode()
        let emptyName2 = Name.wireDecode(emptyEncode)
        XCTAssert(emptyName2 != nil)
        XCTAssert(emptyName1 == emptyName2!)
        
        let n30 = Name(url: "/a/b/c")!
        let n31 = Name(name: n30)
        n31.appendComponent("d")
        XCTAssert(n30 != n31)
        XCTAssertEqual(n30.toUri(), "/a/b/c")
        XCTAssertEqual(n31.toUri(), "/a/b/c/d")
        
        let n40 = Name(url: "ndn:/a/b")
        XCTAssert(n40 != nil)
        XCTAssert(n40!.size == 2)
        let n41 = Name(url: "ndn://a/b")
        XCTAssert(n41 != nil)
        XCTAssert(n41!.size == 1)
        
        XCTAssert(Name(url: "http://a") == nil)
        
        let n5 = Name(url: "/a/b/%FD%00%01")
        XCTAssert(n5 != nil)
        XCTAssert(n5!.size == 3)
        XCTAssert(n5!.toUri() == "/a/b/%FD%00%01")
        
        XCTAssert(Name(url: "/%a") == nil)
        XCTAssert(Name(url: "/%FD") != nil)
        XCTAssert(Name(url: "/+a") != nil)
        XCTAssert(Name(url: "/-a") != nil)
        XCTAssert(Name(url: "/.a") != nil)
        XCTAssert(Name(url: "/_a") != nil)
        
        //FIXME:
        //XCTAssert(Name(url: "/@a") == nil)
        //XCTAssert(Name(url: "/&a") == nil)
        //XCTAssert(Name(url: "/!a") == nil)
        //XCTAssert(Name(url: "/!a")! == Name(url: "/%21a")!)

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
        
        // NSRegularExpression usages
    }
    
    func testExclude() {
        let f0: [[UInt8]] = [[0x03], []]
        let ex0 = Interest.Selectors.Exclude(filter: f0)
        XCTAssert(!ex0.matchesComponent(Name.Component(bytes: [0x02])))
        XCTAssert(ex0.matchesComponent(Name.Component(bytes: [0x03])))
        XCTAssert(ex0.matchesComponent(Name.Component(bytes: [0x04])))
        
        let ex01 = Interest.Selectors.Exclude()
        ex01.appendComponent(Name.Component(bytes: [0x03]))
        ex01.appendAny()
        XCTAssert(!ex01.matchesComponent(Name.Component(bytes: [0x02])))
        XCTAssert(ex01.matchesComponent(Name.Component(bytes: [0x03])))
        XCTAssert(ex01.matchesComponent(Name.Component(bytes: [0x04])))

        
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
        
        let encode5 = ex5.wireEncode()
        XCTAssert(encode5 == [16, 19, 19, 0, 8, 1, 0x01, 8, 1, 0x03, 8, 1, 0x05, 19, 0, 8, 1, 0x07, 8, 1, 0x09])
        let (blk, _) = Tlv.Block.wireDecodeWithBytes(encode5)
        let ex50 = Interest.Selectors.Exclude(block: blk!)
        if let ex = ex50 {
            XCTAssert(ex.matchesComponent(Name.Component(bytes: [0x00])))
            XCTAssert(ex.matchesComponent(Name.Component(bytes: [0x01])))
            XCTAssert(!ex.matchesComponent(Name.Component(bytes: [0x02])))
            XCTAssert(ex.matchesComponent(Name.Component(bytes: [0x03])))
            XCTAssert(!ex.matchesComponent(Name.Component(bytes: [0x04])))
            XCTAssert(ex.matchesComponent(Name.Component(bytes: [0x05])))
            XCTAssert(ex.matchesComponent(Name.Component(bytes: [0x06])))
            XCTAssert(ex.matchesComponent(Name.Component(bytes: [0x07])))
            XCTAssert(!ex.matchesComponent(Name.Component(bytes: [0x08])))
            XCTAssert(ex.matchesComponent(Name.Component(bytes: [0x09])))
            XCTAssert(!ex.matchesComponent(Name.Component(bytes: [0x0A])))
        } else {
            XCTFail("Exclude decoding fail")
        }
        
    }
    
    func testNonNegativeIntegerTlv() {
        let ilt0 = Interest.InterestLifetime()
        let ilt0Encode = ilt0.wireEncode()
        XCTAssert(ilt0Encode == [12, 2, 0x0F, 0xA0])
        
        let ilt1 = Interest.InterestLifetime(value: 0x123456)
        let ilt1Encode = ilt1.wireEncode()
        XCTAssert(ilt1Encode == [12, 4, 0, 0x12, 0x34, 0x56])
    }
    
    func testInterest() {
        var i0 = Interest()
        let i0Encode = i0.wireEncode()
        var i1 = Interest.wireDecode(i0Encode)
        XCTAssert(i1 != nil)
        XCTAssert(i0.name == i1!.name)
        XCTAssert(i0.nonce == i1!.nonce)
        
        var i2 = Interest()
        i2.name = Name(url: "/a/b/c/%00%01")!
        i2.setChildSelector(Interest.Selectors.ChildSelector.Val.LeftmostChild)
        i2.setMustBeFresh()
        i2.setInterestLifetime(2000)
        let i2Encode = i2.wireEncode()
        var i3 = Interest.wireDecode(i2Encode)
        XCTAssert(i3 != nil)
        XCTAssert(i3!.name.toUri() == "/a/b/c/%00%01")
        XCTAssert((i3!.getChildSelector())! == Interest.Selectors.ChildSelector.Val.LeftmostChild)
        XCTAssert((i3!.getInterestLifetime())! == 2000)
        
        var i4 = Interest()
        i4.name = Name(url: "/a/b/c")!
        i4.setExclude([[], [0x00, 0x02]])
        var d40 = Data()
        d40.name = Name(url: "/a/b/c")!
        var d41 = Data()
        d41.name = Name(url: "/a/b/c/%00%05")!
        var d42 = Data()
        d42.name = Name(url: "/a/b/c/%00%01")!
        var d43 = Data()
        d43.name = Name(url: "/a/b")!
        XCTAssert(i4.matchesData(d40))
        XCTAssert(i4.matchesData(d41))
        XCTAssert(!i4.matchesData(d42))
        XCTAssert(!i4.matchesData(d43))
    }
    
    func testData() {
        var name = "/a/b/c/d/%00%01"
        var d0 = Data()
        d0.name = Name(url: name)!
        d0.setFreshnessPeriod(40000)
        var content: [UInt8] = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
        d0.setContent(content)
        
        var keychainSignExpectation = expectationWithDescription("sign data")
        var keychainVerifyExpectation = expectationWithDescription("verify data")
        
        let keychain = KeyChain()
        XCTAssert(keychain != nil)
        
        keychain?.sign(d0, onFinish: { (signedData: Data) in
            keychainSignExpectation.fulfill()
            
            var d0Encode = signedData.wireEncode()
            println(d0Encode)
            
            var d1 = Data.wireDecode(d0Encode)
            XCTAssert(d1 != nil)
            XCTAssert(d1!.name.toUri() == name)
            XCTAssert((d1!.getFreshnessPeriod())! == 40000)
            XCTAssert(d1!.getContent() == content)

            keychain?.verify(d1!, onSuccess: {
                keychainVerifyExpectation.fulfill()
            }, onFailure: { message in
                println("testData: \(message)")
            })
        }, onError: { message in
            println("testData: \(message)")
        })
        
        waitForExpectationsWithTimeout(1, handler: { error in
            if let err = error {
                println("testData: \(err.localizedDescription)")
            }
        })
        
        keychain?.clean()
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
            transport.send(name1!.wireEncode())
            transport.send(name2!.wireEncode() + name3!.wireEncode())
            let n4Encode = name4!.wireEncode()
            let half = n4Encode.count / 2
            transport.send([UInt8](n4Encode[0..<half]))
            transport.send([UInt8](n4Encode[half..<n4Encode.count]) + name5!.wireEncode())
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
    
    func testTimer() {
        if let timer = Timer() {
            var timerExpectation = expectationWithDescription("fire timer")
            let startTime = mach_absolute_time()
            timer.setTimeout(2000) {
                timerExpectation.fulfill()
                let stopTime = mach_absolute_time()
                let elapsed = stopTime - startTime
                var tinfo = mach_timebase_info(numer: 1, denom: 1)
                mach_timebase_info(&tinfo)
                let elapsedMS = elapsed * UInt64(tinfo.numer) / UInt64(tinfo.denom) / 1000000
                XCTAssert(elapsedMS >= 2000)
            }
            
            waitForExpectationsWithTimeout(3, handler: { error in
                if let err = error {
                    println("testTimer: \(err.localizedDescription)")
                }
            })
        }
        
        var timer1: Timer? = Timer()
        timer1 = nil
        XCTAssert(true, "should not crash")
        
        var waitForTimerExpectation = expectationWithDescription("wait for cancelled timer")
        var timer2Wait: Timer! = Timer()
        timer2Wait.setTimeout(1000) {
            XCTFail("Handler should not be called")
        }
        timer2Wait = nil  // should cancel the timer in deinitializer
        
        var waitingTimer: Timer! = Timer()
        waitingTimer.setTimeout(2000) {
            waitForTimerExpectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(3, handler: { error in
            if let err = error {
                println("testTimer: \(err.localizedDescription)")
            }
        })
    }
    
    func testLinkedList() {
        var list = LinkedList<Int>()
        XCTAssert(list.isEmpty == true)
        XCTAssert(list.size == 0)
        list.appendAtTail(0)
        list.appendAtTail(1)
        list.appendAtTail(2)
        list.appendAtTail(3)
        list.appendAtTail(4)
        XCTAssert(list.isEmpty == false)
        XCTAssert(list.size == 5)
        XCTAssert(list.findOneIf({ $0 == -1}) == nil)
        var t = list.findOneIf({ $0 == 2 })
        XCTAssert(t != nil)
        XCTAssert(t! == 2)
        XCTAssert(list.removeOneIf({ $0 == 2}) == true)
        XCTAssert(list.findOneIf({ $0 == 2}) == nil)
        list.appendInFront(-1)
        list.appendInFront(-1)
        XCTAssert(list.size == 6)
        XCTAssert(list.findAllIf({ $0 == -1 }) == [-1, -1])
        XCTAssert(list.removeAllIf({ $0 == -1 }) == true)
        XCTAssert(list.findOneIf({ $0 == -1 }) == nil)
        XCTAssert(list.size == 4)
        
        class ListSum {
            var sum = 0
            func add(v: Int) {
                sum += v
            }
        }
        
        var l2 = LinkedList<Int>()
        l2.appendAtTail(1)
        l2.appendAtTail(2)
        l2.appendAtTail(3)
        l2.appendAtTail(4)
        l2.appendAtTail(5)
        var listSum = ListSum()
        l2.forEach(listSum.add)
        XCTAssert(listSum.sum == 15)
    }
    
    class FaceTestClient: FaceDelegate {
        
        var face: Face!
        
        var receiveI0DataExpectation: XCTestExpectation?
        var receiveI01DataExpectation: XCTestExpectation?
        var timeoutI1Expectation: XCTestExpectation?
        var closeExpectation: XCTestExpectation?
        
        init() {
            face = Face(delegate: self, host: "127.0.0.1", port: 12345)
        }
        
        func onOpen() {
            var i0 = Interest()
            i0.name = Name(url: "/a/b/c")!
            i0.setInterestLifetime(1000)
            face.expressInterest(i0, onData: { [unowned self] in self.onI0Data($0, d0: $1) },
                onTimeout: { [unowned self] in self.onI0Timeout($0) })
            
            var i01 = Interest()
            i01.name = Name(url: "/a/b/c/%00%02")!
            face.expressInterest(i0, onData: { [unowned self] in self.onI01Data($0, d01: $1) },
                onTimeout: { [unowned self] in self.onI01Timeout($0) })
        }
        
        func onI0Data(i0: Interest, d0: Data) {
            receiveI0DataExpectation?.fulfill()
            XCTAssertEqual(d0.name.toUri(), "/a/b/c/%00%02")
            XCTAssert(d0.getContent() == [0, 1, 2, 3, 4, 5, 6, 7])
            
            var i1 = Interest()
            i1.name = Name(url: "/a/b/d")!
            i1.setInterestLifetime(1500)
            face.expressInterest(i1, onData: { [unowned self] in self.onI1Data($0, d1: $1) },
                onTimeout: { [unowned self] in self.onI1Timeout($0) })
        }
        
        func onI0Timeout(i0: Interest) {
            XCTFail("i0 timeout")
        }
        
        func onI01Data(i01: Interest, d01: Data) {
            receiveI01DataExpectation?.fulfill()
            XCTAssertEqual(d01.name.toUri(), "/a/b/c/%00%02")
            XCTAssert(d01.getContent() == [0, 1, 2, 3, 4, 5, 6, 7])
        }
        
        func onI01Timeout(i01: Interest) {
            XCTFail("i01 timeout")
        }
        
        func onI1Data(i1: Interest, d1: Data) {
            XCTFail("i1 data received")
        }
        
        func onI1Timeout(i1: Interest) {
            timeoutI1Expectation?.fulfill()
            self.close()
        }
        
        func onClose() {
            //println("FaceTestClient close")
            closeExpectation?.fulfill()
        }
        
        func onError(reason: String) {
            //println("FaceTestClient error: \(reason)")
        }
        
        func run() {
            face.open()
        }
        
        func close() {
            face.close()
        }
    }
    
    class RibRegisterTestClient: FaceDelegate {
        
        var face: Face!
        
        var registerSuccessExpectation: XCTestExpectation?
        var receiveInterestExpectation: XCTestExpectation?
        var closeExpectation: XCTestExpectation?
        
        init() {
            face = Face(delegate: self, host: "127.0.0.1", port: 12345)
        }
        
        func onOpen() {
            XCTAssertTrue(face.isOpen)
            let prefix = Name(url: "/swift/ndn/face/test")!
            face.registerPrefix(prefix,
                onInterest: { [unowned self] i in
                    self.onInterest(i)
                }, onRegisterSuccess: { [unowned self] _ in
                    self.onRegSuccess()
                }, onRegisterFailure: { [unowned self] msg in
                    self.onRegFailure(msg)
            })
        }
        
        func onInterest(interest: Interest) {
            if interest.name.toUri() == "/swift/ndn/face/test/001" {
                receiveInterestExpectation?.fulfill()
            } else {
                XCTFail("wrong interest received")
            }
            self.close()
        }
        
        func onRegSuccess() {
            self.registerSuccessExpectation?.fulfill()
        }
        
        func onRegFailure(msg: String) {
            println("RibRegisterTestClient: register prefix error: \(msg)")
            XCTFail("register prefix")
        }
        
        func onClose() {
            //println("RibRegisterTestClient close")
            closeExpectation?.fulfill()
        }
        
        func onError(reason: String) {
            //println("RibRegisterTestClient error: \(reason)")
        }
        
        func run() {
            face.open()
        }
        
        func close() {
            face.close()
        }
    }
    
    func testFace() {
        var server: FaceTestServer! = FaceTestServer()
        server.start()
        
        var client: FaceTestClient! = FaceTestClient()
        client.receiveI0DataExpectation = expectationWithDescription("receive i0 data")
        client.receiveI01DataExpectation = expectationWithDescription("receive i01 data")
        client.closeExpectation = expectationWithDescription("close client")
        client.run()
        
        waitForExpectationsWithTimeout(6, handler: { error in
            if let err = error {
                println("testFace: \(err.localizedDescription)")
            }
        })
        
        client = nil
        server = nil
    }
    
    func testFace2() {
        var server2: RibRegisterTestServer! = RibRegisterTestServer()
        server2.start()
        
        var client2: RibRegisterTestClient! = RibRegisterTestClient()
        client2.registerSuccessExpectation = expectationWithDescription("register prefix")
        client2.receiveInterestExpectation = expectationWithDescription("receive interest")
        client2.closeExpectation = expectationWithDescription("close client")
        client2.run()
        
        waitForExpectationsWithTimeout(6, handler: { error in
            if let err = error {
                println("testFace2: \(err.localizedDescription)")
            }
        })
        
        client2 = nil
        server2 = nil
    }
    
    func testFaceList() {
        let bytes: [UInt8] = [128, 56, 105, 1, 1, 114, 11, 105, 110, 116, 101, 114, 110, 97,
            108, 58, 47, 47, 129, 11, 105, 110, 116, 101, 114, 110, 97, 108, 58, 47,
            47, 132, 1, 1, 133, 1, 0, 134, 1, 0, 144, 1, 0, 145, 1, 7, 146, 1, 4, 147,
            1, 0, 148, 1, 0, 149, 1, 0, 128, 64, 105, 1, 254, 114, 15, 99, 111, 110,
            116, 101, 110, 116, 115, 116, 111, 114, 101, 58, 47, 47, 129, 15, 99, 111,
            110, 116, 101, 110, 116, 115, 116, 111, 114, 101, 58, 47, 47, 132, 1, 1,
            133, 1, 0, 134, 1, 0, 144, 1, 0, 145, 1, 0, 146, 1, 0, 147, 1, 0, 148, 1,
            0, 149, 1, 0, 128, 48, 105, 1, 255, 114, 7, 110, 117, 108, 108, 58, 47, 47,
            129, 7, 110, 117, 108, 108, 58, 47, 47, 132, 1, 1, 133, 1, 0, 134, 1, 0, 144,
            1, 0, 145, 1, 0, 146, 1, 0, 147, 1, 0, 148, 1, 0, 149, 1, 0, 128, 80, 105, 2,
            1, 0, 114, 22, 116, 99, 112, 52, 58, 47, 47, 49, 50, 55, 46, 48, 46, 48, 46,
            49, 58, 54, 49, 53, 48, 51, 129, 21, 116, 99, 112, 52, 58, 47, 47, 49, 50, 55,
            46, 48, 46, 48, 46, 49, 58, 54, 51, 54, 51, 132, 1, 1, 133, 1, 1, 134, 1, 0,
            144, 1, 4, 145, 1, 0, 146, 1, 0, 147, 1, 4, 148, 2, 3, 181, 149, 2, 9, 127, 128,
            78, 105, 2, 1, 1, 114, 22, 116, 99, 112, 52, 58, 47, 47, 49, 50, 55, 46, 48, 46,
            48, 46, 49, 58, 54, 49, 53, 48, 52, 129, 21, 116, 99, 112, 52, 58, 47, 47, 49,
            50, 55, 46, 48, 46, 48, 46, 49, 58, 54, 51, 54, 51, 132, 1, 1, 133, 1, 1, 134,
            1, 0, 144, 1, 1, 145, 1, 0, 146, 1, 0, 147, 1, 0, 148, 1, 48, 149, 1, 0]
        
        XCTAssert(FaceStatus.parseFaceStatusDataset(bytes).count == 5)
    }
    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measureBlock() {
//            // Put the code you want to measure the time of here.
//        }
//    }
    
}
