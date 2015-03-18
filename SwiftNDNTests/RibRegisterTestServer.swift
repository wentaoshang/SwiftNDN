//
//  RibRegisterTestServer.swift
//  SwiftNDN
//
//  Created by Wentao Shang on 3/9/15.
//  Copyright (c) 2015 Wentao Shang. All rights reserved.
//

import Foundation

import SwiftNDN

public class RibRegisterTestServer: NSObject, GCDAsyncSocketDelegate {
    
    var acceptSocket: GCDAsyncSocket!
    var clientSocket: GCDAsyncSocket!
    
    var host = "127.0.0.1"
    var port: UInt16 = 12345
    var buffer = [UInt8]()
    
    var timer: Timer?
    
    public override init() {
        super.init()
        self.timer = Timer()
    }
    
    public func start() {
        acceptSocket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
        
        var error: NSError?
        if (!acceptSocket.acceptOnInterface(host, port: port, error: &error)) {
            println("FaceTestServer: acceptOnInterface: \(error!.localizedDescription)")
            return
        }
    }
    
    public func socket(sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
        //println("FaceTestServer: didAcceptNewSocket: client accepted")
        clientSocket = newSocket
        clientSocket.readDataWithTimeout(-1, tag: 0)
        // Stop accepting new client
        acceptSocket = nil
    }
    
    public func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        if let bytes = AsyncTcpTransport.byteArrayFromNSData(data) {
            buffer += bytes
            while buffer.count > 0 {
                let decoded = Tlv.Block.wireDecodeWithBytes(buffer)
                if let blk = decoded.block {
                    if let command = ControlCommand(block: blk) {
                        processCommand(sock, command: command)
                    }
                    buffer.removeRange(0..<decoded.lengthRead)
                } else {
                    break
                }
            }
        }
        sock.readDataWithTimeout(-1, tag: 0)
    }
    
    func sendInterest(name: Name) {
        var interest = Interest()
        interest.name = name
        let instEncode = interest.wireEncode()
        let inst = NSData(bytes: instEncode, length: instEncode.count)
        self.clientSocket.writeData(inst, withTimeout: -1, tag: 0)
    }
    
    func processCommand(sock: GCDAsyncSocket!, command: ControlCommand) {
        if command.prefix.toUri() == "/localhost/nfd" {
            if let prefix = command.parameters.name {
                if prefix.toUri() == "/swift/ndn/face/test" {
                    var response = ControlResponse()
                    response.statusCode = StatusCode(value: 200)
                    response.statusText = StatusText(value: "OK")!
                    let responseEncode = response.wireEncode()
                    var data = Data()
                    data.name = Name(name: command.name)
                    data.setContent(responseEncode)
                    data.signatureValue = Data.SignatureValue(value: [UInt8](count: 64, repeatedValue: 11))
                    let encoded = data.wireEncode()
                    let echoData = NSData(bytes: encoded, length: encoded.count)
                    sock.writeData(echoData, withTimeout: -1, tag: 0)
                    self.timer?.setTimeout(2000) { [unowned self] in
                        self.sendInterest(Name(url: "/swift/ndn/wrong/prefix")!)
                        self.sendInterest(Name(url: "/swift/ndn/face/test/001")!)
                    }
                }
            }
        }
    }
}