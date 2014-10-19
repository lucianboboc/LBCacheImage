//
//  LBString.swift
//  SwiftProject
//
//  Created by Lucian Boboc on 18/10/14.
//  Copyright (c) 2014 Lucian Boboc. All rights reserved.
//

import Foundation


enum HashType {
    case MD5
    case SHA1
    case SHA256
}





//MARK: NSString extension
extension NSString {
    
    func hashMD5() -> NSString? {
        var str = self.hashWithType(.MD5)
        return str
    }
    
    func hashSHA1() -> NSString? {
        var str = self.hashWithType(.SHA1)
        return str
    }
    
    func hashSHA256() -> NSString? {
        var str = self.hashWithType(.SHA256)
        return str
    }
    
    func hashWithType(type:HashType) -> NSString? {
        
        let str = self.UTF8String
        var bufferSize:Int = 0
        
        switch type {
        case .MD5:
            bufferSize = Int(CC_MD5_DIGEST_LENGTH)
        case .SHA1:
            bufferSize = Int(CC_SHA1_DIGEST_LENGTH)
        case .SHA256:
            bufferSize = Int(CC_SHA256_DIGEST_LENGTH)
        default:
            fatalError("hash type not implemented")
        }
        
        let size = NSMutableData(length: bufferSize)
        if let theSize = size {
            var resultBytes = UnsafeMutablePointer<CUnsignedChar>(theSize.bytes)
            switch type {
            case .MD5:
                CC_MD5(str, CC_LONG(strlen(str)), resultBytes)
            case .SHA1:
                CC_SHA1(str, CC_LONG(strlen(str)), resultBytes)
            case .SHA256:
                CC_SHA256(str, CC_LONG(strlen(str)), resultBytes)
            default:
                fatalError("hash type not implemented")
            }
            
            let MD5 = NSMutableString()
            for(var i = 0; i < bufferSize; i++) {
                MD5.appendFormat("%02x",resultBytes[i])
            }
            return MD5
        }
        
        return nil
    }
}

