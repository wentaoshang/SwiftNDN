//
//  Face.swift
//  SwiftNDN
//
//  Created by Wentao Shang on 3/5/15.
//  Copyright (c) 2015 Wentao Shang. All rights reserved.
//

import Foundation

public class Timer {
    
    var timer: dispatch_source_t!
    var callback: (() -> Void)?
    
    public init?() {
        timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue())
        if timer == nil {
            return nil
        }
    }
    
    public func setTimeout(ms: UInt64, callback: () -> Void) {
        self.callback = callback
        var delay = dispatch_time(DISPATCH_TIME_NOW, Int64(ms) * 1000000)
        dispatch_source_set_timer(timer, delay, UInt64.max, ms * 100000)
        dispatch_source_set_event_handler(timer, self.handler)
        dispatch_resume(self.timer)
    }
    
    private func handler() {
        self.callback?()
        dispatch_source_cancel(self.timer)
    }
    
    public func cancel() {
        dispatch_source_cancel(self.timer)
    }
}

public class Face: AsyncTransportDelegate {
    
    var transport: AsyncTcpTransport!
    
    var host = "127.0.0.1"
    var port: UInt16 = 6363
    
    public typealias OnOpenCallback = () -> Void
    public typealias OnCloseCallback = () -> Void
    public typealias OnErrorCallback = (String) -> Void
    
    var onOpenCb: OnOpenCallback?
    var onCloseCb: OnCloseCallback?
    var onErrorCb: OnErrorCallback?
    
    public typealias OnDataCallback = (Interest, Data) -> Void
    public typealias OnTimeoutCallback = (Interest) -> Void
    public typealias OnInterestCallback = (Interest) -> Void
    
    var interestDispatchTable = [(Interest, OnDataCallback, OnTimeoutCallback)]()
    var dataDispatchTable = [(Name, OnInterestCallback)]()
    
    public init() {
        transport = AsyncTcpTransport(face: self, host: host, port: port)
    }
    
    public init(host: String, port: UInt16, onOpenCallback: () -> Void) {
        self.host = host
        self.port = port
        self.transport = AsyncTcpTransport(face: self, host: host, port: port)
    }
    
    public func setOnOpenCallback(cb: OnOpenCallback) {
        self.onOpenCb = cb
    }
    
    public func onOpen() {
        self.onOpenCb?()
    }
    
    public func setOnCloseCallback(cb: OnCloseCallback) {
        self.onCloseCb = cb
    }
    
    public func onClose() {
        self.onCloseCb?()
    }
    
    public func setOnErrorCallback(cb: OnErrorCallback) {
        self.onErrorCb = cb
    }
    
    public func onError(reason: String) {
        self.onErrorCb?(reason)
    }
    
    public func open() {
        transport.connect()
    }
    
    public func onMessage(block: Tlv.Block) {
        
    }
}