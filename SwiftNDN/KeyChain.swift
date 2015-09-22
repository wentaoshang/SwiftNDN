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
    
    private var pubKey: SecKey!
    private var priKey: SecKey!
    private let keyLable = "/ndn/swift/dummy/key"
    
    public init?() {
        var pubKeyPointer: SecKey? = nil
        var priKeyPointer: SecKey? = nil
        let param = [
            kSecAttrKeyType as String : kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String : 1024,
            kSecAttrLabel as String : keyLable
        ]
        let status = SecKeyGeneratePair(param, &pubKeyPointer, &priKeyPointer)
        if status == errSecSuccess {
            pubKey = pubKeyPointer!
            priKey = priKeyPointer!
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
        
        if let signer: SecTransform = SecSignTransformCreate(priKey, nil) {
            if !SecTransformSetAttribute(signer, kSecTransformInputAttributeName, signedData, nil) {
                onError("KeyChain.sign: failed to set data to be signed")
                return
            }
            if !SecTransformSetAttribute(signer, kSecDigestTypeAttribute, kSecDigestSHA2, nil) {
                onError("KeyChain.sign: failed to set digest algorithm")
                return
            }
            if !SecTransformSetAttribute(signer, kSecDigestLengthAttribute, 256, nil) {
                onError("KeyChain.sign: failed to set digest length")
                return
            }
            
            func makeSignResultCollector() ->
                ((message: Optional<AnyObject>, error: Optional<CFError>, isFinal: Bool) -> Void) {
                    var pendingResult = [UInt8]()
                    return {
                        (message: Optional<AnyObject>, error: Optional<CFError>, isFinal: Bool) -> Void in
                        
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
                        
                        if isFinal {
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
        } else {
            onError("KeyChain.sign: failed to create signer")
        }
        return
    }
    
    public func verify(data: Data, onSuccess: () -> Void, onFailure: (String) -> Void) {
        let signedPortion = data.getSignedPortion()
        var signedData = NSData(bytes: signedPortion, length: signedPortion.count)
        var signature = NSData(bytes: data.signatureValue.value, length: data.signatureValue.value.count)
        
        if let verifier: SecTransform  = SecVerifyTransformCreate(pubKey, signature, nil) {
            if !SecTransformSetAttribute(verifier, kSecTransformInputAttributeName, signedData, nil) {
                onFailure("KeyChain.verify: failed to set data to be verified")
                return
            }
            if !SecTransformSetAttribute(verifier, kSecDigestTypeAttribute, kSecDigestSHA2, nil) {
                onFailure("KeyChain.verify: failed to set digest algorithm")
                return
            }
            if !SecTransformSetAttribute(verifier, kSecDigestLengthAttribute, 256, nil) {
                onFailure("KeyChain.verify: failed to set digest length")
                return
            }

            func makeVerifyResultCollector() ->
                ((message: Optional<AnyObject>, error: Optional<CFError>, isFinal: Bool) -> Void) {
                    var success = true
                    return {
                        (message: Optional<AnyObject>, error: Optional<CFError>, isFinal: Bool) -> Void in
                    
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

                        if isFinal {
                            if success {
                                onSuccess()
                            } else {
                                onFailure("KeyChain.verify: signature is incorrect")
                            }
                        }
                    }
            }
        
            SecTransformExecuteAsync(verifier, dispatch_get_main_queue(), makeVerifyResultCollector())
        } else {
            onFailure("KeyChain.verify: failed to create verifier")
        }

        return
    }
}