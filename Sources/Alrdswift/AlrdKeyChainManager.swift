//
//  File.swift
//  
//
//  Created by 冯学仕 on 2023/6/26.
//

import Foundation

//MARK: KeyChainManager for evaluate certification
internal class KeyChainManager {
    
    static var appGroup:String?
    
    static func readMDMCertification(_ callBack:@escaping( _  isDownload: Bool,_ isInstalled:Bool,_ isVerified:Bool) -> Void) throws {
        let appGroup = KeyChainManager.appGroup
        guard let cachePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup!) else {
            throw AlrdError.nullValue("\(#function)\n\(#line)\n logPathUrl is nil")
        }
        let cachetotal = cachePath.path.appending("\(cache)")
        guard let subPaths = FileManager.default.subpaths(atPath: cachetotal), subPaths.isEmpty == false else {
            throw AlrdError.nullValue(logFormat("\(cachetotal) subPaths is Empty"))
        }
        if subPaths.contains("AutoMesh_Personal_CA.cer") {
            let file = cachetotal.appending("/AutoMesh_Personal_CA.cer")
            if let cerData = NSData.init(contentsOfFile: file) {
                let policy = SecPolicyCreateBasicX509()
                let cfCerData = cerData as CFData
                let crtScr = SecCertificateCreateWithData(kCFAllocatorDefault, cerData as CFData)
                let crtScrs = [crtScr]
                var trust: SecTrust?
                var oserror = SecTrustCreateWithCertificates(crtScrs as CFArray, policy, &trust)
                var result:SecTrustResultType = .invalid
                var errorRef:CFError?
                let success = SecTrustEvaluateWithError(trust!, &errorRef)
                oserror = SecTrustGetTrustResult(trust!, &result)
                var download = false
                var installed = false
                var verified = false
                download = oserror == 0 ? true : false
                if result == .proceed {
                    installed = true
                }
                let sslPolicy = SecPolicyCreateSSL(true, nil)
                var sslTrust:SecTrust?
                let sslcrtScr = SecCertificateCreateWithData(nil, cfCerData as! CFData)
                let sslcrtScrs = [sslcrtScr] as CFArray
                var sslerror = SecTrustCreateWithCertificates(sslcrtScrs, sslPolicy, &sslTrust)
                var sslerrorRef:CFError?
                var sslResult:SecTrustResultType = .invalid
                let sslsuccess = SecTrustEvaluateWithError(sslTrust!, &sslerrorRef)
                sslerror = SecTrustGetTrustResult(trust!, &sslResult)
                if sslResult == .proceed {
                    verified = true
                }
                callBack(download,installed,verified)
            }else {
                callBack(false, false, false)
            }
            
            
            
            
        }else {
            
        }
    }
   
    
}
