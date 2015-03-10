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
        dispatch_source_set_event_handler(timer, { [unowned self] in self.handler() })
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

public protocol FaceDelegate: class {
    func onOpen()
    func onClose()
    func onError(reason: String)
}

public class Face: AsyncTransportDelegate {
    
    var transport: AsyncTcpTransport!
    weak var delegate: FaceDelegate!
    
    var host = "127.0.0.1"
    var port: UInt16 = 6363
    
    public typealias OnDataCallback = (Interest, Data) -> Void
    public typealias OnTimeoutCallback = (Interest) -> Void
    public typealias OnInterestCallback = (Interest) -> Void
    public typealias OnRegisterSuccessCallback = (Name) -> Void
    public typealias OnRegisterFailureCallback = (String) -> Void
    
    class ExpressedInterestTable {
        
        class Entry {
            var interest: Interest
            var onData: OnDataCallback?
            var onTimeout: OnTimeoutCallback?
            var timer: Timer!
            
            init?(interest: Interest, onDataCb: OnDataCallback?,
                onTimeoutCb: OnTimeoutCallback?)
            {
                self.interest = interest
                self.onData = onDataCb
                self.onTimeout = onTimeoutCb
                self.timer = Timer()
                if self.timer == nil {
                    return nil
                }
            }
        }
        
        var table = LinkedList<Entry>()
        
        func append(interest: Interest, onDataCb: OnDataCallback?,
            onTimeoutCb: OnTimeoutCallback?)
        {
            if let entry = Entry(interest: interest,
                onDataCb: onDataCb, onTimeoutCb: onTimeoutCb)
            {
                var listEntry = table.appendAtTail(entry)
                let lifetime = interest.getInterestLifetime() ?? 4000
                entry.timer.setTimeout(lifetime, callback: {
                    listEntry.detach()
                    if let cb = entry.onTimeout {
                        cb(entry.interest)
                    }
                })
            }
        }
        
        func consumeWithData(data: Data) {
            table.forEachEntry() { listEntry in
                if let entry = listEntry.value {
                    if entry.interest.matchesData(data) {
                        listEntry.detach()
                        entry.timer?.cancel()
                        entry.timer = nil
                        if let onData = entry.onData {
                            onData(entry.interest, data)
                        }
                    }
                }
            }
        }
    }
    
    var expressedInterests = ExpressedInterestTable()
    
    class RegisteredPrefixTable {
        
        struct Entry {
            var prefix: Name
            var onInterest: OnInterestCallback?
        }
        
        var table = LinkedList<Entry>()
        
        func append(prefix: Name, onInterestCb: OnInterestCallback?) -> ListEntry<Entry>
        {
            let entry = Entry(prefix: prefix, onInterest: onInterestCb)
            let lentry = table.appendAtTail(entry)
            return lentry
        }
        
        func dispatchInterest(interest: Interest) {
            table.forEachEntry() { listEntry in
                if let entry = listEntry.value {
                    if entry.prefix.isPrefixOf(interest.name) {
                        if let onInterest = entry.onInterest {
                            onInterest(interest)
                        }
                    }
                }
            }
        }
    }

    var registeredPrefixes = RegisteredPrefixTable()

    public init(delegate: FaceDelegate) {
        self.delegate = delegate
        self.transport = AsyncTcpTransport(face: self, host: host, port: port)
    }
    
    public init(delegate: FaceDelegate, host: String, port: UInt16) {
        self.delegate = delegate
        self.host = host
        self.port = port
        self.transport = AsyncTcpTransport(face: self, host: host, port: port)
    }
    
    public func onOpen() {
        self.delegate.onOpen()
    }
    
    public func onClose() {
        self.delegate.onClose()
    }
    
    public func onError(reason: String) {
        self.delegate.onError(reason)
    }
    
    public func open() {
        transport.connect()
    }

    public func close() {
        transport.close()
    }
    
    public func onMessage(block: Tlv.Block) {
        if let interest = Interest(block: block) {
            registeredPrefixes.dispatchInterest(interest)
        } else if let data = Data(block: block) {
            expressedInterests.consumeWithData(data)
        }
    }
    
    public func expressInterest(interest: Interest,
        onData: OnDataCallback?, onTimeout: OnTimeoutCallback?) -> Bool
    {
        if let wire = interest.wireEncode() {
            expressedInterests.append(interest, onDataCb: onData, onTimeoutCb: onTimeout)
            transport.send(wire)
            return true
        } else {
            return false
        }
    }
    
    public func registerPrefix(prefix: Name, onInterest: OnInterestCallback?,
        onRegisterSuccess: OnRegisterSuccessCallback?,
        onRegisterFailure: OnRegisterFailureCallback?)
    {
        // Append to table first
        let lentry = registeredPrefixes.append(prefix, onInterest)

        // Prepare command interest
        var param = ControlParameters()
        param.name = prefix
        var nfdRibRegisterInterest = ControlCommand(prefix: Name(url: "/localhost/nfd")!,
            module: "rib", verb: "register", param: param)
        let ret = self.expressInterest(nfdRibRegisterInterest, onData: { [unowned self] _, d in
            let content = d.getContent()
            if let response = ControlResponse.wireDecode(content) {
                if response.statusCode.value == 200 {
                    onRegisterSuccess?(prefix)
                } else {
                    onRegisterFailure?("Register command failure")
                }
            } else {
                onRegisterFailure?("Malformat control response")
            }
        }, onTimeout: { [unowned self] _ in
            onRegisterFailure?("Command Interest timeout")
            lentry.detach()
        })
        
        if !ret {
            // Failed in sending the command interest
            if let onRegFailure = onRegisterFailure {
                onRegFailure("Failed to send Command Interest")
            }
            lentry.detach()
        }
    }
}