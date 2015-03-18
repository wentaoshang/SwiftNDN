//
//  AsyncTransport.swift
//  SwiftNDN
//
//  Created by Wentao Shang on 3/2/15.
//  Copyright (c) 2015 Wentao Shang. All rights reserved.
//

import Foundation

public protocol AsyncTransportDelegate: class {
    func onOpen()
    func onClose()
    func onError(reason: String)
    func onMessage(block: Tlv.Block)
}

public class AsyncTcpTransport: NSObject, GCDAsyncSocketDelegate {
    
    var socket: GCDAsyncSocket!
    
    var host: String
    var port: UInt16
    
    var buffer: [UInt8]
    
    weak var face: AsyncTransportDelegate!
    
    public init(face: AsyncTransportDelegate, host: String, port: UInt16) {
        self.host = host
        self.port = port
        self.buffer = [UInt8]()
        self.face = face
    }
    
    public func connect() {
        socket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
        // or use global dispatch queue for multithreading?
        var error: NSError?
        if (!socket.connectToHost(host, onPort: port, error: &error)) {
            println("AsyncTcpTransport: connectToHost: \(error!.localizedDescription)")
            face.onError(error!.description)
            return
        }
    }
    
    public func socket(sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        //println("AsyncTcpTransport: didConnectToHost \(host):\(port)")
        face.onOpen()
        sock.readDataWithTimeout(-1, tag: 0)
    }
    
    public class func byteArrayFromNSData(data: NSData) -> [UInt8]? {
        if data.length == 0 {
            return nil
        }
        var array = [UInt8](count: data.length, repeatedValue: 0)
        data.getBytes(&array, length: array.count)
        return array
    }
    
    public func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        if let bytes = AsyncTcpTransport.byteArrayFromNSData(data) {
            buffer += bytes
            //println("AsyncTcpTransport: didReadData \(buffer)")
            while buffer.count > 0 {
                let decoded = Tlv.Block.wireDecodeWithBytes(buffer)
                if let blk = decoded.block {
                    face.onMessage(blk)
                    buffer.removeRange(0..<decoded.lengthRead)
                }
            }
        }
        sock.readDataWithTimeout(-1, tag: 0)
    }
    
    public func send(bytes: [UInt8]) {
        let data = NSData(bytes: bytes, length: bytes.count)
        socket.writeData(data, withTimeout: -1, tag: 0)
    }
    
    public func close() {
        socket.disconnectAfterWriting()
    }
    
    public func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        if let error = err {
            face.onError(error.description)
        } else {
            face.onClose()
        }
    }
    
}