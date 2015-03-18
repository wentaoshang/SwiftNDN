//
//  FaceTestServer.swift
//  SwiftNDN
//
//  Created by Wentao Shang on 3/8/15.
//  Copyright (c) 2015 Wentao Shang. All rights reserved.
//

import Foundation

import SwiftNDN

public class FaceTestServer: NSObject, GCDAsyncSocketDelegate {
    
    var acceptSocket: GCDAsyncSocket!
    var clientSocket: GCDAsyncSocket!
    
    var host = "127.0.0.1"
    var port: UInt16 = 12345
    var buffer = [UInt8]()
    
    public override init() {
        super.init()
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
                    if let interest = Interest(block: blk) {
                        processInterest(sock, interest: interest)
                    }
                    buffer.removeRange(0..<decoded.lengthRead)
                } else {
                    break
                }
            }
        }
        sock.readDataWithTimeout(-1, tag: 0)
    }

    func processInterest(sock: GCDAsyncSocket!, interest: Interest) {
        if interest.name.toUri() == "/a/b/c" {
            var data = Data()
            data.name = Name(name: interest.name)
            data.name.appendComponent("%00%02")
            data.setContent([0, 1, 2, 3, 4, 5, 6, 7])
            data.signatureValue = Data.SignatureValue(value: [UInt8](count: 64, repeatedValue: 0))
            let encoded = data.wireEncode()
            let echoData = NSData(bytes: encoded, length: encoded.count)
            sock.writeData(echoData, withTimeout: -1, tag: 0)
        }
    }
}