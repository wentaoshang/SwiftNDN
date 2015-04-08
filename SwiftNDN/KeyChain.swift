//
//  KeyChain.swift
//  SwiftNDN
//
//  Created by Wentao Shang on 3/4/15.
//  Copyright (c) 2015 Wentao Shang. All rights reserved.
//

import Foundation
import Security

public class KeyChain {
    
    private var pubKey: SecKeyRef!
    private var priKey: SecKeyRef!
    private let keyLable = "/ndn/swift/dummy/key"
    
    public init?() {
        var pubKeyPointer: Unmanaged<SecKey>?
        var priKeyPointer: Unmanaged<SecKey>?
        let param = [
            kSecAttrKeyType as String : kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String : 1024,
            kSecAttrLabel as String : keyLable
        ]
        let status = SecKeyGeneratePair(param, &pubKeyPointer, &priKeyPointer)
        if status == noErr {
            pubKey = pubKeyPointer!.takeUnretainedValue()
            priKey = priKeyPointer!.takeUnretainedValue()
        } else {
            return nil
        }
    }
    
    public func clean() {
        let param = [
            kSecClass as String : kSecClassKey,
            kSecAttrLabel as String : keyLable,
            kSecMatchLimit as String : kSecMatchLimitAll
        ]
        SecItemDelete(param)
    }
    
    public func sign(data: Data, onFinish: (Data) -> Void, onError: (String) -> Void) {
        // Clear existing signature
        data.signatureInfo = Data.SignatureInfo()
        data.signatureInfo.keyLocator = Data.SignatureInfo.KeyLocator(name: Name(url: keyLable)!)
        data.signatureValue = Data.SignatureValue()
        
        let signedPortion = data.getSignedPortion()
        var signedData = NSData(bytes: signedPortion, length: signedPortion.count)
        
        var unmangedSigner = SecSignTransformCreate(priKey, nil)
        if unmangedSigner == nil {
            onError("KeyChain.sign: failed to create signer")
            return
        }
        
        var signer: SecTransformRef = unmangedSigner.takeUnretainedValue()
        
        if SecTransformSetAttribute(signer, kSecTransformInputAttributeName, signedData, nil) == 0 {
            onError("KeyChain.sign: failed to set data to be signed")
            return
        }
        if SecTransformSetAttribute(signer, kSecDigestTypeAttribute, kSecDigestSHA2, nil) == 0 {
            onError("KeyChain.sign: failed to set digest algorithm")
            return
        }
        if SecTransformSetAttribute(signer, kSecDigestLengthAttribute, 256, nil) == 0 {
            onError("KeyChain.sign: failed to set digest length")
            return
        }
        
        func makeSignResultCollector() ->
            ((message: CFTypeRef!, error: CFErrorRef!, isFinal: Boolean) -> Void) {
                var pendingResult = [UInt8]()
                return {
                    (message: CFTypeRef!, error: CFErrorRef!, isFinal: Boolean) -> Void in
                    
                    if error != nil {
                        onError("KeyChain.sign: \(CFErrorCopyDescription(error))")
                        return
                    }
                    if let signatureData = message as? NSData! {
                        if let signature = signatureData {
                            var arr = [UInt8](count: signature.length, repeatedValue: 0)
                            signature.getBytes(&arr, length: signature.length)
                            pendingResult += arr
                        }
                    }
                    
                    if isFinal != 0 {
                        if pendingResult.isEmpty {
                            onError("KeyChain.sign: failed to extract signature result")
                        } else {
                            data.setSignature(pendingResult)
                            onFinish(data)
                        }
                    }
                }
        }
        
        SecTransformExecuteAsync(signer, dispatch_get_main_queue(), makeSignResultCollector())
        return
    }
    
    public func verify(data: Data, onSuccess: () -> Void, onFailure: (String) -> Void) {
        let signedPortion = data.getSignedPortion()
        var signedData = NSData(bytes: signedPortion, length: signedPortion.count)
        var signature = NSData(bytes: data.signatureValue.value, length: data.signatureValue.value.count)
        
        var unmanagedVerifier = SecVerifyTransformCreate(pubKey, signature, nil)
        if unmanagedVerifier == nil {
            onFailure("KeyChain.verify: failed to create verifier")
            return
        }
        
        var verifier: SecTransformRef = unmanagedVerifier.takeUnretainedValue()
        
        if SecTransformSetAttribute(verifier, kSecTransformInputAttributeName, signedData, nil) == 0 {
            onFailure("KeyChain.verify: failed to set data to be verified")
            return
        }
        if SecTransformSetAttribute(verifier, kSecDigestTypeAttribute, kSecDigestSHA2, nil) == 0 {
            onFailure("KeyChain.verify: failed to set digest algorithm")
            return
        }
        if SecTransformSetAttribute(verifier, kSecDigestLengthAttribute, 256, nil) == 0 {
            onFailure("KeyChain.verify: failed to set digest length")
            return
        }
        
        func makeVerifyResultCollector() ->
            ((message: CFTypeRef!, error: CFErrorRef!, isFinal: Boolean) -> Void) {
                var success = true
                return {
                    (message: CFTypeRef!, error: CFErrorRef!, isFinal: Boolean) -> Void in
                    
                    if error != nil {
                        onFailure("KeyChain.verify: \(CFErrorCopyDescription(error))")
                        return
                    }
                    if let verified = message as! CFBooleanRef! {
                        if verified == kCFBooleanTrue {
                            success = success && true
                        } else {
                            success = false
                        }
                    }
                    
                    if isFinal != 0 {
                        if success {
                            onSuccess()
                        } else {
                            onFailure("KeyChain.verify: signature is incorrect")
                        }
                    }
                }
        }
        
        SecTransformExecuteAsync(verifier, dispatch_get_main_queue(), makeVerifyResultCollector())
        return
    }
}