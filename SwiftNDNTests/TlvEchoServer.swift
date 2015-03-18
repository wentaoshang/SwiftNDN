//
//  TlvEchoServer.swift
//  SwiftNDN
//
//  Created by Wentao Shang on 3/3/15.
//  Copyright (c) 2015 Wentao Shang. All rights reserved.
//

import Foundation

import SwiftNDN

public class TlvEchoServer: NSObject, GCDAsyncSocketDelegate {
    
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
            println("TlvEchoServer: acceptOnInterface: \(error!.localizedDescription)")
            return
        }
    }
    
    public func socket(sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
        //println("TlvEchoServer: didAcceptNewSocket: client accepted")
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
                    //println("TlvEchoServer: didReadData: \(buffer)")
                    //println("TlvEchoServer: didReadData: \(blk)")
                    let encoded = blk.wireEncode()
                    //println("TlvEchoServer: didReadData: \(encoded)")
                    let echoData = NSData(bytes: encoded, length: encoded.count)
                    sock.writeData(echoData, withTimeout: -1, tag: 0)
                    buffer.removeRange(0..<decoded.lengthRead)
                } else {
                    break
                }
            }
        }
        sock.readDataWithTimeout(-1, tag: 0)
    }
    
//    public func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
//        println("TlvEchoServer: socketDidDisconnect: \(sock)")
//    }

}
